+++
title = "Content Security Policy: A Strict Nonce-Based Policy and How to Roll It Out Safely"
date = 2026-10-10T06:10:00Z
tags = ["appsec", "api-security"]
categories = ["appsec"]
summary = "A Content Security Policy limits what scripts a browser will run, which can turn a cross-site scripting bug from a full compromise into a blocked request. Here is the strict nonce-based policy MDN and OWASP recommend, what each directive does, and a report-only rollout that does not break your site."
description = "How to write a strict Content Security Policy with nonces, what strict-dynamic and unsafe-inline do, and how to deploy with Report-Only and reporting endpoints."
author = "FirewallSync Editorial"
imageAlt = "A padlock hanging on a metal gate"
imageCredit = "Photo by [Hennie Stander](https://unsplash.com/photos/ACmOuY2lOug) on Unsplash"
takeaways = [
  "MDN's recommended practice for controlling script loading is a strict CSP: a policy built on per-response nonces or on hashes, not on lists of allowed hostnames.",
  "A starting policy is script-src with a nonce, object-src 'none' and base-uri 'none'. Adding frame-ancestors 'none' blocks other sites from embedding yours unless you need that.",
  "CSP is defense in depth. Both MDN and OWASP say you still have to sanitize input and encode output; OWASP states CSP should not be the only defense against cross-site scripting.",
  "Deploy first with the Content-Security-Policy-Report-Only header. It reports violations but does not block anything, and it cannot be set through a meta element.",
  "A nonce must be different for every HTTP response and unpredictable. A fixed nonce in a template is equivalent to no protection."
]

[[faq]]
q = "What does a Content Security Policy protect against?"
a = "MDN describes CSP as a set of instructions from a site to the browser that restricts what the site's code is allowed to do. Its main use is defense in depth against cross-site scripting (XSS): even if an attacker manages to inject markup, a strict policy can stop the injected script from running. It does not remove the underlying injection bug."
 
[[faq]]
q = "Should I use a nonce or a hash?"
a = "MDN says nonces suit pages your server renders per request, and hashes suit static pages. A nonce is a random value generated for each response and placed in both the header and the script tags. A hash allows one specific script and breaks if the script changes at all, including whitespace, per OWASP."

[[faq]]
q = "Is 'unsafe-inline' ever acceptable?"
a = "MDN advises avoiding it because it defeats much of the purpose of a CSP, since inline JavaScript is one of the most common XSS vectors. MDN also notes that when a directive contains nonce or hash expressions, browsers ignore 'unsafe-inline' in that directive."

[[faq]]
q = "Can I test a policy without breaking my site?"
a = "Yes. Send the policy in the Content-Security-Policy-Report-Only header. Violations are reported to your endpoint but nothing is blocked. If both headers are present, both are honored: the enforced one blocks and the report-only one generates reports."

[[faq]]
q = "Does CSP replace X-Frame-Options?"
a = "MDN describes the frame-ancestors directive as a more flexible replacement for X-Frame-Options and recommends setting it to 'none' unless your site needs to be embeddable. We did not test every browser version; check your support requirements."
+++

A Content Security Policy (CSP) is an HTTP response header that tells the browser which sources of script and other content it may use on your page. The version worth deploying for cross-site scripting (XSS) defense is a *strict* policy based on a random per-response value called a nonce. MDN's guidance reads: "To control script loading as a mitigation against XSS, recommended practice is to use nonce- or hash-based fetch directives." OWASP's cheat sheet likewise calls a strict CSP the "current leading practice." This article covers the minimal strict policy, what each part does, and how to roll it out without a day of broken pages.

It is research-based. We tested only one thing ourselves: a small Node.js script confirming that the example below produces a different nonce on every response and that the header and page agree. We did not test browser behavior.

## The minimal strict policy

MDN's nonce-based example is:

```http
Content-Security-Policy:
  script-src 'nonce-{RANDOM}';
  object-src 'none';
  base-uri 'none';
```

In plain terms:

- **`script-src 'nonce-{RANDOM}'`** allows a script only if its tag carries a `nonce` attribute matching the value in the header. Without nonce or hash expressions, MDN says, a `script-src` or `default-src` directive blocks inline JavaScript. That is the protection: an attacker who injects `<script>alert(1)</script>` does not know the nonce, so the browser refuses to run it.
- **`object-src 'none'`** disallows plugins and embedded objects. OWASP's strict samples set it because, with `plugin-types` removed from the specification, `object-src 'none'` is the control when you do not need embedded objects.
- **`base-uri 'none'`** stops injected `<base>` elements from changing how relative URLs resolve. OWASP's samples also set `base-uri 'none'`.

Add **`frame-ancestors 'none'`** if your pages should never be embedded in an iframe on another site. MDN says: "Unless you need your site to be embeddable, you should set `frame-ancestors` to `'none'`," and describes it as a more flexible replacement for `X-Frame-Options`.

## Generating the nonce

The rule from MDN: the nonce "must be different for every HTTP response, and must not be predictable." Here is a minimal Node.js example (no framework) that does that:

```js
const http = require("node:http");
const crypto = require("node:crypto");

http.createServer((req, res) => {
  const nonce = crypto.randomBytes(16).toString("base64"); // new value per response
  const policy = [
    `script-src 'nonce-${nonce}' 'strict-dynamic'`,
    "object-src 'none'",
    "base-uri 'none'",
    "frame-ancestors 'none'",
  ].join("; ");
  res.setHeader("Content-Security-Policy-Report-Only", policy); // switch to Content-Security-Policy to enforce
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.end(`<!doctype html><script nonce="${nonce}">/* app code */</script>`);
}).listen(8080);
```

We ran an equivalent script twice against itself: the nonce differed between the two responses and the nonce in the body matched the header. That confirms the mechanics, not that your application is protected.

OWASP warns against one shortcut: do not use middleware that automatically adds the nonce to every script tag, because scripts an attacker injects would then receive the nonce too. The nonce belongs only on scripts your templates deliberately emit, which means your templating layer has to apply it.

## Nonce, hash or `'strict-dynamic'`

| Option | Good for | Limitation |
|---|---|---|
| Nonce | Pages rendered by a server on each request | Needs a templating step; a static, cached page would reuse the nonce, which is unsafe |
| Hash (`'sha256-...'`) | Static pages with fixed inline scripts | OWASP: any change to the script, even whitespace, changes the hash and breaks it; external scripts also need an `integrity` attribute (MDN) |
| `'strict-dynamic'` | Scripts that load other scripts, such as tag managers | MDN: it "does make your CSP less secure" because trusted scripts that create `<script>` elements from XSS-prone input are not protected |

Per MDN, `'strict-dynamic'` means that if a script has a nonce or hash, it may load further scripts that do not have one. It eases third-party scripts but moves some trust to them.

### Why not just list allowed hostnames?

Allowlist policies such as `script-src https://cdn.example.com` were the original mechanism. OWASP says a strict policy is "much easier to deploy" and warns that a non-strict policy "that is too granular or permissive is likely to lead to bypasses." We did not survey bypass techniques here and do not quantify how often they occur.

## Roll it out in report-only mode first

The `Content-Security-Policy-Report-Only` header applies the policy in reporting mode. MDN: "The policy is not enforced, but any violations are sent to the reporting endpoint specified in the policy." OWASP calls it non-blocking ("fail open") and often a precursor to blocking mode. Practical points:

1. **Report-only cannot be set in a `<meta>` element**, per MDN and the W3C draft. The `<meta http-equiv>` form also "does not support all CSP features." Use response headers, on all responses, not only the main document (MDN).
2. **Both headers can run together.** MDN says that if both are present, both policies are honored: the enforced one blocks and the report-only one reports. OWASP suggests running a strict report-only policy alongside a looser enforced one to collect many violation reports while you migrate.
3. **Collect reports.** MDN's recommended method uses the Reporting API:

```http
Reporting-Endpoints: csp-endpoint="https://example.com/csp-reports"
Content-Security-Policy: default-src 'self'; report-to csp-endpoint
```

   Reports arrive as `POST` requests with content type `application/reports+json` and `"type": "csp-violation"`. The older `report-uri` directive is described by MDN as deprecated, but it says to declare both until `report-to` is supported in all browsers.
4. **Fix the causes**, which are usually inline `<script>` blocks, inline event handlers such as `onclick`, and third-party snippets. Move inline code to external files or give emitted scripts a nonce.
5. **Switch the header name** from `Content-Security-Policy-Report-Only` to `Content-Security-Policy` once reports are quiet for your traffic, and keep reporting on.

Avoid the temptation to add `'unsafe-inline'` to make reports go away. MDN: "Developers should avoid `'unsafe-inline'`, because it defeats much of the purpose of having a CSP." It adds that when a directive has nonce or hash expressions, browsers ignore `'unsafe-inline'` in it, so adding it beside a nonce does not weaken the policy in browsers that support nonces, but it also gains nothing there.

## What CSP does not do

OWASP states that CSP "should not be relied upon as the only defensive mechanism against XSS." MDN says the same thing differently: "Setting a CSP is not an alternative to sanitizing input. Websites should sanitize input *and* set a CSP." Output encoding and safe templating remain the primary fix. CSP also does not address cross-site request forgery, misconfigured cross-origin access, or broken authorization; see our articles on [CSRF protection](/posts/csrf-protection-samesite-cookies-tokens-and-fetch-metadata-compared/), [CORS misconfiguration](/posts/cors-misconfiguration-what-access-control-allow-origin-actually-permits/) and [broken access control](/posts/broken-access-control-real-world-examples-and-how-to-prevent-it/). For where missing security headers sit among other common API mistakes, see [the most common API security misconfigurations](/posts/the-most-common-api-security-misconfigurations-and-how-to-fix-them/).

A note on standards status: as of our check, CSP Level 3 is a W3C Working Draft (the page shows September 16, 2026 as its date), not a finished Recommendation. Browser support is what determines real behavior, so test the browsers your users have.

## Sources and verification

Checked on October 10, 2026. We did not test a policy in any browser.

| Important claim | Source | Verification |
|---|---|---|
| Strict CSP is recommended practice for XSS mitigation; nonce must be unique per response and unpredictable; hashes for static pages; example policy; `'strict-dynamic'` behavior and its security cost; `'unsafe-inline'` warning and nonce/hash behavior | [MDN, Content Security Policy (CSP)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP) | Verified |
| Report-Only header behavior, both headers honored, no meta support, Reporting-Endpoints and `report-to`, deprecated `report-uri` | Same MDN page | Verified |
| `frame-ancestors 'none'` recommendation and relation to X-Frame-Options | Same MDN page | Verified |
| Strict CSP is leading practice; nonce guidance and middleware warning; hash fragility; `object-src` and `base-uri`; Report-Only is fail-open; CSP not the only XSS defense; allowlist bypass warning | [OWASP, Content Security Policy Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html) | Verified |
| Report-only cannot be in meta; CSP Level 3 is a W3C Working Draft dated September 16, 2026 | [W3C, Content Security Policy Level 3](https://www.w3.org/TR/CSP3/) | Qualified: draft status and date as shown when we checked; only the first part of the document was read |
| Example script produces a different nonce per response and matches the page | Our own test, Node.js 22 | Qualified: tests header and nonce mechanics only, not browser enforcement |
