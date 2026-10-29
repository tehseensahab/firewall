+++
title = "Node.js Decompression Bombs: zlib Limits That Work"
date = 2026-10-29T04:40:00Z
tags = ["node.js", "denial of service", "api security", "appsec"]
categories = ["appsec"]
summary = "A 100 KB gzip body can decompress to 100 MB. Node's maxOutputLength stops that in the one-shot zlib functions, but streams silently ignore it, and fetch() decompresses responses with no cap at all. We tested where the limits hold in Node.js 22 and Express 5, with code you can copy."
description = "Node.js decompression bombs: maxOutputLength works for gunzipSync but streams ignore it. Tested limits for zlib, Brotli, zstd, Express and fetch()."
author = "John Marshall"
imageAlt = "Water pouring over a low concrete weir below a calm lake, with a metal railing on one side and bare trees on the far shore"
imageCredit = "Photo by [Deniz Demirci](https://unsplash.com/photos/tA30zkMCx-g) on Unsplash"
takeaways = [
  "A decompression bomb is small compressed input that expands into huge output. In our test, 100 MiB of zeros compressed to 101,941 bytes with gzip, 3,219 bytes with zstd and 172 bytes with Brotli.",
  "maxOutputLength works on Node's one-shot functions (gunzipSync, brotliDecompress, zstdDecompressSync and the rest): they throw RangeError ERR_BUFFER_TOO_LARGE. Its default is buffer.kMaxLength, which is effectively no limit.",
  "Streams ignore maxOutputLength. createGunzip({ maxOutputLength: 1 MiB }) let all 100 MiB through in our test. Put a byte-counting Transform after the decompressor instead.",
  "Express 5's express.json() applies its 100 KB default limit after decompression, and it rejected 10 MB bombs in gzip, Brotli and zstd with 413. Keep the limit low; inflate: false rejects compressed bodies outright.",
  "fetch() decompresses gzip responses automatically and arrayBuffer() has no size cap. Read response bodies through a capped reader whenever the URL or server isn't yours."
]

[[faq]]
q = "Does maxOutputLength protect zlib streams in Node.js?"
a = "No. The Node.js docs say it limits output size 'when using convenience methods', meaning the one-shot functions such as zlib.gunzip() and zlib.gunzipSync(). In our test on Node.js 22.23.4, zlib.createGunzip({ maxOutputLength: 1048576 }) passed all 104,857,600 bytes through without an error."
[[faq]]
q = "Is Express vulnerable to gzip bombs?"
a = "Not with its default body parsers. In Express 5.3.0 with body-parser 2.4.0, express.json() counted the decompressed bytes against its 100 KB limit and returned 413 for 10 MB bodies sent compressed as gzip (10,232 bytes), Brotli (41 bytes) and zstd (355 bytes). Raising the limit raises your exposure, and custom middleware that pipes req through zlib needs its own cap."
[[faq]]
q = "Is checking Content-Length enough?"
a = "No. Content-Length is the compressed size. In our fetch() test the header said 101,941 bytes and the decoded body was 104,857,600 bytes. Count bytes after decompression."
[[faq]]
q = "Which Node.js versions support zstd in zlib?"
a = "zstd support (zstdCompress, zstdDecompress and the Zstd stream classes) was added in Node.js 22.15.0 and is marked Stability 1, Experimental, in the Node.js 22 documentation."
+++

A decompression bomb is a small compressed payload that expands into far more data than your service expects, enough to exhaust memory or tie up a CPU core. MITRE files it as [CWE-409](https://cwe.mitre.org/data/definitions/409.html), "Improper Handling of Highly Compressed Data (Data Amplification)". In Node.js, the defence is to **count decompressed bytes and stop at a limit you choose**. Node gives you that limit in one place, `maxOutputLength` on the one-shot zlib functions, and nowhere else. Streams, HTTP clients and custom middleware all need their own cap.

We ran every example below on Node.js 22.23.4. Results for each are in the text.

## How big the amplification gets

We compressed 100 MiB (104,857,600 bytes) of zeros with each codec Node ships:

| Codec | Compressed size | Ratio |
|---|---|---|
| gzip (level 9) | 101,941 bytes | about 1,029 : 1 |
| zstd (default level) | 3,219 bytes | about 32,575 : 1 |
| Brotli (default quality) | 172 bytes | about 609,637 : 1 |

Zeros are the best case for a compressor, and the ratio for real data is far lower. That's the point: an attacker picks the input. A request-body limit of 1 MB on the wire tells you nothing about the decompressed size.

## The one-shot functions: maxOutputLength works

Node's one-shot functions (`zlib.gunzip`, `zlib.inflate`, `zlib.brotliDecompress`, `zlib.zstdDecompress` and their `*Sync` forms) accept `maxOutputLength`. The [zlib docs](https://nodejs.org/api/zlib.html) describe it as an option that "Limits output size when using convenience methods". The default is `buffer.kMaxLength`, the largest Buffer Node can allocate, so without it you have no practical limit.

```js
const zlib = require('node:zlib');

const LIMIT = 1024 * 1024; // 1 MiB of decompressed output

function safeGunzip(buf) {
  try {
    return zlib.gunzipSync(buf, { maxOutputLength: LIMIT });
  } catch (err) {
    if (err.code === 'ERR_BUFFER_TOO_LARGE') {
      throw Object.assign(new Error('decompressed payload too large'), { status: 413 });
    }
    throw err; // corrupt input, wrong format, etc.
  }
}
```

With the 100 MiB bombs from the table, `gunzipSync`, `brotliDecompressSync` and `zstdDecompressSync` all threw `RangeError` with code `ERR_BUFFER_TOO_LARGE` and the message "Cannot create a Buffer larger than 1048576 bytes". The async `zlib.gunzip()` passed the same error to its callback.

Use the one-shot functions when the whole payload is already in memory and you can name a sensible maximum: a webhook body, a cached blob, a small config file.

## Streams: maxOutputLength is ignored

The stream classes accept the same options object, so this looks right:

```js
// Looks safe. Isn't.
zlib.createGunzip({ maxOutputLength: 1024 * 1024 });
```

In our test, piping the gzip bomb through that stream delivered all 104,857,600 bytes and finished without an error. The option is documented for the convenience methods only, and the stream path doesn't enforce it. Nothing warns you.

The fix is a Transform that counts bytes after the decompressor and fails the pipeline when the count passes your limit:

```js
const zlib = require('node:zlib');
const { pipeline, Transform } = require('node:stream');

// Fail the pipeline once decompressed output exceeds maxBytes.
function byteLimit(maxBytes) {
  let seen = 0;
  return new Transform({
    transform(chunk, _enc, cb) {
      seen += chunk.length;
      if (seen > maxBytes) {
        const err = new RangeError(`decompressed body exceeds ${maxBytes} bytes`);
        err.code = 'ERR_DECOMPRESSED_TOO_LARGE';
        return cb(err);
      }
      cb(null, chunk);
    },
  });
}

pipeline(
  source,                 // e.g. req, a file stream, an upstream response
  zlib.createGunzip(),
  byteLimit(1024 * 1024),
  destination,
  (err) => { /* err.code === 'ERR_DECOMPRESSED_TOO_LARGE' on a bomb */ },
);
```

Against the 100 MiB bomb, the pipeline failed with `ERR_DECOMPRESSED_TOO_LARGE` after exactly 1,048,576 bytes had reached the destination. `pipeline()` destroys every stream in the chain on error, so the decompressor stops as well.

Two details make this work. The limiter must sit **after** the decompressor, because counting compressed bytes is the mistake you're avoiding. And use `pipeline()`, not chained `.pipe()` calls, which don't propagate errors or destroy the upstream streams.

## Express: the body parser already counts decompressed bytes

Express's `express.json()`, `express.urlencoded()`, `express.text()` and `express.raw()` come from [body-parser](https://github.com/expressjs/body-parser). Its `inflate` option defaults to `true`, and in body-parser 2.4.0 it decodes `deflate`, `gzip`, `br` and, where Node supports it, `zstd`.

We sent `express.json()` (default `limit` of `'100kb'`) a 10 MB JSON body compressed each way:

| Content-Encoding | Bytes on the wire | Result |
|---|---|---|
| gzip | 10,232 | 413, `entity.too.large` |
| br | 41 | 413, `entity.too.large` |
| zstd | 355 | 413, `entity.too.large` |
| gzip with `inflate: false` | 10,232 | 415, `encoding.unsupported` |

All three compressed bodies were under 100 KB on the wire and still got 413, so the limit is applied to the decoded body. That's the behaviour you want. Tested with Express 5.3.0, body-parser 2.4.0 and raw-body 3.0.2.

Two cautions. The body-parser README warns that limits "above the default, for example payloads of 5 MB or more" increase memory use and response times, so raise `limit` per route, not globally. And if you don't expect compressed request bodies, `inflate: false` turns them away with 415 before any decoding.

Custom code is where the gaps are: a handler that does `req.pipe(zlib.createGunzip())` for an upload endpoint, or a framework plugin with its own decoder. Give each one the byte limiter above.

## fetch(): responses are decompressed with no cap

Node's built-in `fetch()` decodes `Content-Encoding: gzip` for you. We served the 100 MiB gzip bomb from a local server:

- `res.headers.get('content-length')` returned `101941`, the compressed size.
- `await res.arrayBuffer()` returned 104,857,600 bytes.

There's no size option on `arrayBuffer()`, `json()` or `text()`. If you fetch URLs you don't control (webhooks, link previews, feed readers, anything with a user-supplied URL), read the body with a cap:

```js
// Read at most maxBytes of a fetch() response body (after fetch's own decompression).
async function readCapped(res, maxBytes) {
  const reader = res.body.getReader();
  const chunks = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > maxBytes) {
      await reader.cancel();
      throw new RangeError(`response exceeds ${maxBytes} bytes`);
    }
    chunks.push(value);
  }
  return Buffer.concat(chunks);
}

const res = await fetch(url, { signal: AbortSignal.timeout(10_000) });
const body = await readCapped(res, 1024 * 1024);
```

Against the bomb, `readCapped(res, 1 MiB)` threw "response exceeds 1048576 bytes". Pair it with a timeout, because a slow trickle is a different attack that a byte cap doesn't stop. Fetching arbitrary URLs has bigger risks than size, too; our [SSRF guide](/posts/ssrf-explained-how-server-side-request-forgery-works-and-how-to-prevent-it/) covers the network side.

## A checklist for Node services

| Where you decompress | What enforces the limit | Default |
|---|---|---|
| `zlib.*Sync()` / `zlib.*()` one-shot | `maxOutputLength` | `buffer.kMaxLength` (no practical limit) |
| `zlib.create*()` streams | Your own byte-counting Transform | None; `maxOutputLength` is ignored |
| `express.json()` and other body-parser parsers | `limit`, counted after decoding | `'100kb'` |
| `fetch()` response bodies | A capped reader | None |
| Uploaded archives (zip, tar.gz) | Per-entry and total extracted-size limits in your extractor | Depends on the library |

Also consider:

- **Keep the decoder patched.** Size limits don't help against bugs in the decompressor itself. CVE-2026-111497 was an out-of-bounds write in Brotli's decoder, fixed in Node.js 22.23.4, 24.22.1 and 26.12.1; see our [Brotli guide](/posts/brotli-cve-2026-111497-find-and-patch-every-copy/).
- **Decide whether you need each codec.** zstd arrived in Node.js 22.15.0 and is marked Experimental in the Node 22 docs, yet body-parser 2.4.0 accepts it automatically when the runtime supports it. If clients never send it, `inflate: false` or a proxy rule removes that path.
- **Push the limit to the edge as well.** A reverse proxy that decompresses request bodies should cap the decoded size too, so the application isn't your only control.

## Limits of this article

All results come from Node.js 22.23.4 on Linux with Express 5.3.0, body-parser 2.4.0 and raw-body 3.0.2, using 100 MiB of zeros as the bomb. Other Node release lines, frameworks (Fastify, Koa, NestJS adapters) and HTTP clients (axios, undici's `request`) may behave differently. Test them the same way. We measured whether limits held, not peak memory use or CPU time.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| maxOutputLength "Limits output size when using convenience methods"; default `buffer.kMaxLength` | [Node.js zlib docs](https://nodejs.org/api/zlib.html) ([v22.23.4 source](https://github.com/nodejs/node/blob/v22.23.4/doc/api/zlib.md)) | Verified |
| zstd added in v22.15.0; Stability 1, Experimental | Node.js v22.23.4 zlib docs | Verified |
| Compression ratios; ERR_BUFFER_TOO_LARGE; streams ignore maxOutputLength; byte limiter; fetch() results | Our tests on Node.js 22.23.4 (code above) | Verified (tested) |
| Express limit applies after decompression; 413/415 results | Our tests on Express 5.3.0 / body-parser 2.4.0 | Verified (tested) |
| body-parser decodes deflate, gzip, br, zstd; inflate default true; limit default '100kb'; 5 MB warning | [body-parser](https://github.com/expressjs/body-parser) 2.4.0 source and README | Verified |
| CWE-409 title | [MITRE CWE-409](https://cwe.mitre.org/data/definitions/409.html) | Verified |
