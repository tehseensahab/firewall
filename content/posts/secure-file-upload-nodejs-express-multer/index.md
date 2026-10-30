+++
title = "Secure File Uploads in Node.js: A Tested Express Setup"
date = 2026-10-30T04:30:00Z
tags = ["file upload", "node.js", "express", "appsec", "owasp"]
categories = ["appsec"]
summary = "Most upload bugs come from trusting something the client sent: the filename, the Content-Type, or the idea that a file sitting in a public folder won't be run. This guide builds an Express 5 and Multer 2 upload endpoint that limits size and count, checks magic bytes against an allowlist, renames and stores files outside the webroot, and serves them back safely. We ran ten attack requests against it, and one of them got through the type check, which is why the storage rules matter more."
description = "Secure file upload in Node.js: Express and Multer limits, magic-byte allowlist, random names, storage outside the webroot and safe download headers, tested."
author = "Craig Leslie"
imageAlt = "Close-up of a weathered green roadside mailbox at the end of a row of mailboxes on wooden posts, with fallen leaves and a blurred road behind"
imageCredit = "Photo by [Daria Nepriakhina](https://unsplash.com/photos/tilt-shift-photography-of-green-mailbox-EvX8-J2ClMo) on Unsplash"
takeaways = [
  "Never trust the client's filename or Content-Type. Generate the stored name on the server and detect the type from the file's bytes.",
  "Multer's limits default to Infinity for file size, file count and parts. Set fileSize, files, fields and parts on every upload route, and never mount Multer globally.",
  "Magic-byte checks reject obvious fakes (a PHP script labelled image/jpeg got 415 in our test), but a valid PNG with PHP appended passed. Type detection is a filter, not a guarantee.",
  "What made the polyglot harmless was storage: a random name with an extension we chose, mode 0600, in a directory no web server or interpreter serves.",
  "Serve uploads through a handler that checks ownership and sends Content-Disposition: attachment, X-Content-Type-Options: nosniff and a sandbox CSP. Re-encoding images (we used sharp) strips appended payloads."
]

[[faq]]
q = "Is checking the file extension enough to secure an upload?"
a = "No. OWASP's File Upload Cheat Sheet lists double extensions (.jpg.php), null bytes, case changes, alternative extensions such as .phtml, and NTFS alternate data streams as common bypasses. Ignore the user's extension entirely: detect the type from content, then store the file under a name and extension your server chooses."
[[faq]]
q = "Is checking magic bytes enough?"
a = "No. The file-type package's own readme calls detection 'a best-effort hint' that 'does not guarantee the file is actually of that type'. In our test a valid PNG with a PHP payload appended was detected as image/png. Combine detection with safe storage, safe serving and, for images, re-encoding."
[[faq]]
q = "Should I allow SVG uploads?"
a = "Only if you need them, and then serve them as attachments or from a separate origin. SVG is XML text that can contain script, and magic-byte libraries such as file-type do not detect text formats. Our example allowlist rejects SVG with 415."
[[faq]]
q = "Where should uploaded files be stored?"
a = "OWASP's order of preference is a different host first, then outside the webroot, and only then inside the webroot with write-only permissions. Object storage with private buckets and short-lived download URLs counts as a different host."
+++

A secure file upload accepts only the types you need, decides the filename and extension itself, stores the bytes somewhere nothing will execute or serve them directly, and checks authorization again on download. The [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html) says it plainly: "There is no silver bullet in validating user content." No single check is enough, so you stack them.

This guide builds that stack in Node.js and tests it. Versions: Node.js 22.23.4, Express 5.3.0, Multer 2.5.0, file-type 22.3.0 and sharp 0.35.5, installed from npm on 2026-10-30.

## Why uploads keep turning into breaches

Unrestricted upload is [CWE-434](https://cwe.mitre.org/data/definitions/434.html). In the CISA KEV catalog (version 2026.10.29), 24 entries carry CWE-434, eight of them added in 2026. The count is a floor: not every KEV entry has a CWE assigned. The most recent is the Magento "PolyShell" bug we covered in [Magento CVE-2026-48356: Patch and Hunt](/posts/magento-cve-2026-48356-polyshell-patch-and-hunt/), where the fix included making sure upload directories can't execute code.

The OWASP cheat sheet groups the risks into two kinds:

- **Malicious files**: exploits for the parser that processes the file, phishing documents, zip and XML bombs, overwriting existing files, and active content such as HTML or SVG that attacks other users.
- **Public retrieval**: if uploads are publicly reachable, attackers can enumerate other users' files, use them for DoS, or host illegal content on your domain.

## The endpoint, step by step

Here is the full server. Each control is explained below.

```js
// Node.js 22, Express 5.3.0, Multer 2.5.0, file-type 22.3.0 (package.json: "type": "module")
import express from 'express';
import multer from 'multer';
import { fileTypeFromBuffer } from 'file-type';
import { randomUUID } from 'node:crypto';
import { writeFile, mkdir } from 'node:fs/promises';
import path from 'node:path';

const UPLOAD_DIR = process.env.UPLOAD_DIR ?? '/srv/app-uploads'; // not under any static/public dir
const ALLOWED = new Map([            // detected type -> extension we will store
  ['image/png', 'png'],
  ['image/jpeg', 'jpg'],
  ['application/pdf', 'pdf'],
]);
const files = new Map();             // id -> { owner, mime, ext }; use your database in production

const upload = multer({
  storage: multer.memoryStorage(),   // bytes stay in memory until they pass checks
  limits: { fileSize: 5 * 1024 * 1024, files: 1, fields: 5, parts: 6 },
});

// Stand-in for your real auth middleware
function requireUser(req, res, next) {
  const user = req.get('x-demo-user');
  if (!user) return res.status(401).json({ error: 'login required' });
  req.user = { id: user };
  next();
}

const app = express();

app.post('/uploads', requireUser, upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'no file' });
  const detected = await fileTypeFromBuffer(req.file.buffer);   // magic bytes, not the client's Content-Type
  if (!detected || !ALLOWED.has(detected.mime)) {
    return res.status(415).json({ error: 'file type not allowed' });
  }
  const id = randomUUID();
  const ext = ALLOWED.get(detected.mime);
  await mkdir(UPLOAD_DIR, { recursive: true, mode: 0o700 });
  // Server-chosen name; 'wx' fails instead of overwriting; 0o600 = no execute bit
  await writeFile(path.join(UPLOAD_DIR, `${id}.${ext}`), req.file.buffer, { flag: 'wx', mode: 0o600 });
  files.set(id, { owner: req.user.id, mime: detected.mime, ext });
  res.status(201).json({ id });
});

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

app.get('/files/:id', requireUser, (req, res) => {
  const meta = UUID.test(req.params.id) && files.get(req.params.id);
  if (!meta || meta.owner !== req.user.id) return res.status(404).end();  // authz on every download
  res.set({
    'Content-Type': meta.mime,                       // the type we detected, never the client's
    'Content-Disposition': `attachment; filename="${req.params.id}.${meta.ext}"`,
    'X-Content-Type-Options': 'nosniff',
    'Content-Security-Policy': "default-src 'none'; sandbox",
  });
  res.sendFile(`${req.params.id}.${meta.ext}`, { root: UPLOAD_DIR });
});

app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    const status = err.code === 'LIMIT_FILE_SIZE' ? 413 : 400;
    return res.status(status).json({ error: err.code });
  }
  next(err);
});

app.listen(3000, () => console.log('listening on :3000'));
```

The `x-demo-user` header and the in-memory `files` map exist only so the example runs on its own. Replace them with your session middleware and a database table.

### 1. Authenticate before parsing, and only on the routes that need it

`requireUser` runs before `upload.single()`, so an anonymous request is rejected before Multer reads a byte of the body. Multer's README warns: "Never add multer as a global middleware since a malicious user could upload files to a route that you didn't anticipate." Mount it per route, as above.

### 2. Set every limit

Multer passes `limits` straight to busboy, and the defaults in the Multer 2.5.0 README are generous: `fileSize`, `files`, `parts` and `fields` all default to `Infinity`. The README also notes that "Limits apply to the whole request; there is no per-file limit." Set them to what the feature needs. Map `LIMIT_FILE_SIZE` to 413 and other Multer errors to 400 in your error handler, as the example does.

`memoryStorage()` holds the whole file in RAM, which is why `fileSize` matters. For large files, use disk storage into a private temp directory and run the same checks before moving the file into place. If you also accept compressed data, the limit has to apply after decompression; see [Node.js decompression bombs](/posts/nodejs-decompression-bomb-zlib-limits/).

### 3. Detect the type from content, against an allowlist

The `Content-Type` of each part is whatever the client says. OWASP: "it is trivial to spoof." `fileTypeFromBuffer()` reads the file's magic number instead, and we compare the result to a short allowlist of types the feature actually needs.

Know the limits of this check. The file-type readme says detection "is a best-effort hint. It does not guarantee the file is actually of that type or that the file is valid/not malformed." It also covers only binary formats, "not text-based formats like `.txt`, `.csv`, `.svg`". If you need text formats, validate them with a real parser.

### 4. Choose the name and extension yourself

The stored name is a UUID plus the extension mapped from the detected type. The user's `originalname` is never used on disk, which removes the whole class of tricks OWASP lists for extensions (`.jpg.php`, `.php%00.jpg`, `.pHp`, `.phtml`, `shell.asp:.jpg`) and path traversal in filenames. If you need to show the original name, store it as data in your database and escape it on output.

The `wx` flag makes `writeFile` fail if the path exists rather than overwrite it. Mode `0o600` means no execute bit, and your process umask can only make it stricter.

### 5. Store outside anything that serves or executes files

OWASP ranks storage options in this order: a different host, then outside the webroot, then inside the webroot with write-only permissions. `UPLOAD_DIR` must not be inside `express.static()`, your nginx `root`, or a PHP document root. Private object storage (an S3 bucket with [Block Public Access](/posts/s3-block-public-access-what-the-four-settings-do-and-how-to-enforce-them/) on, served by short-lived signed URLs) satisfies "different host".

If files have to live under a web server's document root, also turn off per-directory overrides there. OWASP's example is Apache `AllowOverride None`, so an uploaded `.htaccess` can't remap `.png` to the PHP handler. For PHP stacks, our [php.ini hardening guide](/posts/php-ini-security-hardening-production-settings/) covers the upload-related settings.

### 6. Serve through a handler with defensive headers

The download route checks ownership on every request. Without that, a guessable or leaked ID becomes an [IDOR](/posts/idor-vulnerabilities-how-to-find-and-fix-insecure-direct-object-references/). It then sets four headers:

| Header | What it does here |
|---|---|
| `Content-Type` from detection | The browser gets the type you verified, not the one the uploader claimed |
| `Content-Disposition: attachment` | The browser downloads the file instead of rendering it on your origin |
| `X-Content-Type-Options: nosniff` | Stops the browser second-guessing the type; see [HTTP security headers](/posts/http-security-headers-hsts-nosniff-referrer-policy-and-permissions-policy-explained/) |
| `Content-Security-Policy: default-src 'none'; sandbox` | If the file is rendered anyway, it gets no scripts, no subresources and an opaque origin |

Serving user files from a separate domain (for example a dedicated `usercontent` domain) adds one more layer: active content never runs on the same origin as your session cookies.

## What we tested, and what got through

We started the server with `UPLOAD_DIR` set to a temp directory and sent ten requests with curl:

| # | Request | Result |
|---|---|---|
| 1 | Valid 1x1 PNG | 201, stored as `<uuid>.png` |
| 2 | PHP script named `shell.jpg`, sent as `image/jpeg` | 415, type not allowed |
| 3 | SVG containing `<script>`, sent as `image/svg+xml` | 415, type not allowed |
| 4 | Valid PNG with a PHP payload appended, filename `../../shell.php` | **201**, stored as `<uuid>.png` |
| 5 | 6 MB file | 413, `LIMIT_FILE_SIZE` |
| 6 | Two files in one request | 400, `LIMIT_FILE_COUNT` |
| 7 | Upload without a user | 401 |
| 8 | Owner downloads file from test 1 | 200 with all four headers above |
| 9 | Another user requests the same ID | 404 |
| 10 | ID of `../../etc/passwd` (URL-encoded) | 404 |

Both stored files were `-rw-------`. Test 4 is the one to remember. A PNG with code appended is still a valid PNG, so magic-byte detection passed it. It did no harm because of what came after: the traversal filename was ignored, the stored name ended in `.png`, the directory isn't served or interpreted, and downloads go out as attachments with a sandbox CSP. Remove any one of those and the polyglot becomes more dangerous.

## Re-encode images when you can

For images, OWASP recommends decoding and re-encoding to strip anything that isn't pixels. With sharp, metadata is dropped by default ("The default behaviour, when withMetadata is not used, is to strip all metadata", per its type definitions):

```js
import sharp from 'sharp';
// limitInputPixels guards against decompression-style image bombs; sharp's default is 268402689 pixels
const clean = await sharp(req.file.buffer, { limitInputPixels: 40_000_000 }).png().toBuffer();
```

Run on the polyglot from test 4, the 97-byte input contained `<?php`; the 90-byte output did not. OWASP adds a caveat worth keeping: the image library "itself handles untrusted input", so keep it patched and, for high-volume or high-risk uploads, run processing in a separate worker or sandbox. The file-type readme makes the same point for its own parser, recommending a size limit and "a worker thread with a timeout" for untrusted files.

## Checklist

- Authenticate before parsing; mount Multer only on upload routes.
- Set `fileSize`, `files`, `fields` and `parts`.
- Detect type from content; compare to a short allowlist; reject text formats you can't parse.
- Generate the stored name and extension; never write `originalname` to disk.
- Store outside the webroot or in private object storage, without execute permissions.
- Serve via a handler that checks ownership and sets `attachment`, `nosniff` and a sandbox CSP.
- Re-encode images; scan or sandbox documents if they will be opened by staff.
- Protect the upload form from [CSRF](/posts/csrf-protection-samesite-cookies-tokens-and-fetch-metadata-compared/) if it uses cookie auth.

## Limits of this article

- We tested one stack (Express 5.3.0, Multer 2.5.0). Other frameworks have different defaults; check their docs for limits and filename handling.
- We did not test antivirus scanning or Content Disarm and Reconstruction for Office or PDF files, which OWASP also recommends where applicable.
- The in-memory metadata map and header-based "auth" are placeholders and are not production-ready.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Extension bypasses, Content-Type spoofing, storage order, AllowOverride None, image re-encoding caveat | [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html) | Verified |
| Multer limit defaults (Infinity), "no per-file limit", never mount globally | Multer 2.5.0 README, as installed from npm ([repository](https://github.com/expressjs/multer)) | Verified |
| file-type detection is "a best-effort hint"; binary formats only; worker-thread advice | file-type 22.3.0 readme ([repository](https://github.com/sindresorhus/file-type)) | Verified |
| sharp strips metadata by default; limitInputPixels default 268402689 | sharp 0.35.5 `lib/index.d.ts` ([repository](https://github.com/lovell/sharp)) | Verified |
| 24 KEV entries with CWE-434, 8 added in 2026 | [CISA KEV catalog (kev-data)](https://github.com/cisagov/kev-data/blob/main/known_exploited_vulnerabilities.json), version 2026.10.29, counted with Python | Verified (floor; CWE field not always set) |
| Results of the ten test requests and the re-encode test | Our run on Node.js 22.23.4, 2026-10-30 | Verified (our test) |
