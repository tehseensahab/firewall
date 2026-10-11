+++
title = "HTTP Security Headers Beyond CSP: HSTS, nosniff, Referrer-Policy and Permissions-Policy Explained"
date = 2026-10-11T06:00:00Z
tags = ["appsec"]
categories = ["appsec"]
summary = "Four response headers do most of the work after Content Security Policy: Strict-Transport-Security, X-Content-Type-Options, Referrer-Policy and Permissions-Policy. Here is what each one does, the values MDN and OWASP document, and the HSTS preload trap that is hard to undo."
description = "What HSTS, X-Content-Type-Options, Referrer-Policy and Permissions-Policy do, the values OWASP recommends, the HSTS preload requirements, and which old headers to stop sending."
author = "FirewallSync Editorial"
imageAlt = "Brass padlock hanging from a metal slide bolt across the seam of two dark wooden door panels"
imageCredit = "Photo by [Zoshua Colah](https://unsplash.com/photos/n-O8na8fAao) on Unsplash"
takeaways = [
  "OWASP's recommended values are: Strict-Transport-Security: max-age=63072000; includeSubDomains; preload, X-Content-Type-Options: nosniff, Referrer-Policy: strict-origin-when-cross-origin, and Permissions-Policy: geolocation=(), camera=(), microphone=(). Treat them as starting points, not as drop-in answers for every site.",
  "HSTS only takes effect after a browser has received the header once over HTTPS, and a browser ignores it if it arrives over plain HTTP. Preloading closes the first-visit gap but, per hstspreload.org, cannot easily be undone.",
  "nosniff makes a browser block a script or stylesheet response whose Content-Type does not match, and stop guessing the type of other responses. It only works if your Content-Type headers are correct.",
  "Modern browsers default to strict-origin-when-cross-origin for Referrer-Policy, but OWASP says to set it explicitly instead of relying on the default.",
  "OWASP says not to set X-XSS-Protection (or to set it to 0) and not to use Expect-CT or Public-Key-Pins."
]

[[faq]]
q = "Which security headers should every website send?"
a = "OWASP's HTTP Headers Cheat Sheet recommends, among others, Strict-Transport-Security, X-Content-Type-Options: nosniff, Referrer-Policy, a Content-Security-Policy and a restrictive Permissions-Policy. Which ones matter most depends on the site. Pages that serve HTML benefit most; a header such as X-Frame-Options does nothing for redirects or JSON API responses, according to OWASP."

[[faq]]
q = "Can I set HSTS over plain HTTP?"
a = "No. MDN says the host must send Strict-Transport-Security over HTTPS only and that browsers ignore the header if it arrives over HTTP, so a man-in-the-middle cannot alter it. Your HTTP-to-HTTPS redirect must not include the header."

[[faq]]
q = "How do I remove a domain from the HSTS preload list?"
a = "hstspreload.org says inclusion cannot easily be undone. Removal takes months to reach users through a Chrome update, and other browsers are not guaranteed to honor it. Do not request preload unless you are sure you can serve HTTPS on the whole domain and every subdomain for the long term."

[[faq]]
q = "Does X-Content-Type-Options: nosniff stop all content-type confusion?"
a = "No. MDN says nosniff blocks script and style requests whose MIME type does not match the expected type. For other response types it only tells the browser to use the supplied Content-Type as-is instead of inferring one. It depends on your server setting Content-Type correctly."

[[faq]]
q = "Is Permissions-Policy supported in every browser?"
a = "Not necessarily. MDN labels the header as Limited availability and Experimental, and says it is not Baseline because it does not work in some of the most widely used browsers. Check the browser compatibility table for the browsers your users run before relying on it."
+++

Content Security Policy gets most of the attention among HTTP response headers, but four smaller headers cover different problems: forcing HTTPS, stopping content-type guessing, limiting what a link leaks, and switching off browser features you never use. The values below come from OWASP's HTTP Headers Cheat Sheet and MDN's reference pages, and every claim is attributed to one of them. This is research-based; we did not run these headers against a live server or test browser behavior. For the script-control header, see our separate guide to [a strict nonce-based Content Security Policy](/posts/content-security-policy-a-strict-nonce-based-policy-and-how-to-roll-it-out-safely/).

## The short version

OWASP's recommended values for the four headers:

| Header | OWASP-recommended value | What it controls |
|---|---|---|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Browser uses HTTPS only for the host |
| `X-Content-Type-Options` | `nosniff` | No content-type guessing |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | How much of the page URL is sent in the `Referer` header |
| `Permissions-Policy` | `geolocation=(), camera=(), microphone=()` | Which browser features the page and its iframes may use |

OWASP gives these as recommendations; `63072000` is two years in seconds. Two of them need care before you copy them: the HSTS value includes `preload`, which has consequences described below, and the Permissions-Policy value disables only three features, so you should disable what *your* site does not need.

Headers are sent by the web server, CDN or application, and the configuration syntax differs between them. The examples here are the raw header lines as they appear in an HTTP response.

## Strict-Transport-Security (HSTS)

HTTP Strict Transport Security (HSTS) tells a browser to access a host only over HTTPS. MDN defines `max-age` as "the time, in seconds, that the browser should remember that a host is only to be accessed using HTTPS." Before loading an `http` URL for that host, the browser rewrites it to `https`.

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

How it behaves, per MDN:

- **HTTPS only.** The header must be sent over HTTPS. Browsers ignore it over HTTP, which prevents a man-in-the-middle from setting or expiring it. Your HTTP-to-HTTPS redirect (MDN suggests a permanent redirect such as status `301`) must not carry the header.
- **First-visit gap.** HSTS "does not take effect until the browser has made at least one secure connection to the host and received the `Strict-Transport-Security` header." An insecure first request is vulnerable to network attacks. Preloading mitigates this.
- **Refreshing.** Each time the browser receives the header, it extends the expiry by `max-age` from the current time. MDN warns that a fixed `max-age` can keep HSTS from ever expiring while the header keeps being sent.
- **Subdomains.** `includeSubDomains` applies the policy to all subdomains of the host that sent it. MDN notes it does not apply to the parent domain or to sibling hosts.
- **No click-through.** If a TLS error such as an invalid certificate occurs on an HSTS host, the browser does not let the user proceed. OWASP makes the same point from the operator side: a misconfigured header or a certificate problem can block legitimate users, and long durations are a particular risk if the certificate expires or is revoked.
- **Turning it off.** `max-age=0` disables it, but only once a browser makes a secure request and receives that response.

### The preload decision

HSTS preloading ships your domain inside browsers so even the first visit is HTTPS. MDN says the list is maintained by Google at hstspreload.org, is used by all major browsers, and "is not part of the HSTS specification and should not be treated as official."

hstspreload.org lists these submission requirements:

1. Serve a valid certificate.
2. Redirect HTTP to HTTPS on the same host if you listen on port 80.
3. Serve all subdomains over HTTPS, including `www` if a DNS record for it exists.
4. Send an HSTS header on the base domain with `max-age` of at least `31536000` seconds (one year), `includeSubDomains` and `preload`.

The site's warning is blunt: "inclusion in the preload list cannot easily be undone." Removal takes months to reach users through a Chrome update, other browsers are not guaranteed to honor it, and removal "tends to be slow and painful" for sites preloaded before they realized some subdomains lacked HTTPS.

Our editorial suggestion, not a quoted rule: because the header persists in browsers until it expires and `max-age=0` works only after a secure request, start with a short `max-age`, confirm every subdomain (including internal ones) serves valid HTTPS, raise the value in steps, and add `preload` only as a deliberate, final decision. Before then, an internal hostname with an expired certificate becomes unreachable for users who cached the policy.

## X-Content-Type-Options: nosniff

Browsers can try to work out what a file is from its content, called MIME sniffing, rather than trusting the `Content-Type` header. `nosniff` is the only valid value, and MDN describes two effects:

- For requests with a destination of script or style, the browser blocks the response if the MIME type does not match: a JavaScript MIME type for scripts, `text/css` for stylesheets.
- For other responses, including navigations to a new HTML document, the browser uses the supplied `Content-Type` as-is. MDN's example: a `text/plain` response with `nosniff` will not be interpreted as HTML even if it contains HTML markup, which helps against attacks where user-uploaded content is executed as an HTML document.

```http
X-Content-Type-Options: nosniff
```

The limitation is the part people miss. Blocking applies to script and style requests only, and everything depends on the declared type being right. OWASP's pairing advice is to set `Content-Type` correctly throughout the site. If your server labels JavaScript files `text/plain`, `nosniff` will cause scripts to be blocked, which is a good way to find those mistakes in staging.

## Referrer-Policy

When a user clicks a link or a page loads a resource, the browser may send a `Referer` header containing the address of the page that triggered the request. URLs can contain sensitive material such as password-reset tokens or internal paths, so `Referrer-Policy` controls how much is sent. MDN's list of values:

| Value | What the `Referer` contains |
|---|---|
| `no-referrer` | Nothing |
| `same-origin` | Full URL for same-origin requests; nothing for cross-origin requests |
| `strict-origin` | Origin only (for example `https://example.com/`) for HTTPS-to-HTTPS; nothing to less secure destinations |
| `strict-origin-when-cross-origin` | Full URL for same-origin requests; origin only for cross-origin HTTPS-to-HTTPS; nothing to less secure destinations |
| `no-referrer-when-downgrade` | Full URL unless the request goes from HTTPS to HTTP, then nothing |
| `origin` | Origin only, for all requests |
| `origin-when-cross-origin` | Full URL for same-origin requests; origin only for cross-origin requests and HTTPS-to-HTTP |
| `unsafe-url` | Full URL for all requests; MDN warns it "will leak potentially-private information from HTTPS resource URLs to insecure origins" |

MDN states that `strict-origin-when-cross-origin` is the default when no policy is specified, per a specification revision of November 2020, and that the previous default was `no-referrer-when-downgrade`. OWASP recommends the header with `strict-origin-when-cross-origin` and says to "Set the header explicitly rather than relying on browser defaults."

```http
Referrer-Policy: strict-origin-when-cross-origin
```

If your URLs carry secrets, the stricter `no-referrer` or `same-origin` send less; that comparison is our reading of MDN's table, not a recommendation either source makes. The better fix is not to put secrets in URLs. MDN also documents a comma-separated fallback list with the preferred policy last, for example `no-referrer, strict-origin-when-cross-origin`.

## Permissions-Policy

`Permissions-Policy` is a response header that, per MDN, "provides a mechanism to allow and deny the use of browser features in a document or within any `<iframe>` elements in the document." Specifying `()` for a feature disables it for all browsing contexts, including iframes from any origin.

```http
Permissions-Policy: geolocation=(), camera=(), microphone=()
```

MDN documents what happens when each is disabled: calls to `getUserMedia()` for camera or microphone reject with a `NotAllowedError`, and geolocation calls receive a `PERMISSION_DENIED` error. OWASP's rationale is that the policy "prevents that an injection, for example an XSS, enables the camera." Its advice is to disable every feature the site does not need, or allow it only for authorized domains.

Two qualifications. MDN labels the header "Limited availability" and "Experimental" and says it is not Baseline because it does not work in some of the most widely used browsers, so treat it as defense in depth rather than a guarantee. And you can scope a feature to specific origins, for example `("https://a.example.com")`, rather than disabling it outright, if a legitimate embedded widget needs it.

## Headers to stop sending

OWASP's cheat sheet also names headers that should no longer be used:

- **`X-XSS-Protection`:** "Do not set this header or explicitly turn it off." The example given is `X-XSS-Protection: 0`. OWASP says it can create XSS vulnerabilities in otherwise safe sites and points to a CSP that disables inline JavaScript instead.
- **`Expect-CT` and `Public-Key-Pins`:** do not use; remove from existing code where possible.
- **`Server`, `X-Powered-By`, `X-AspNet-Version`, `X-AspNetMvc-Version`:** remove, or set non-informative values.

OWASP also recommends `X-Frame-Options: DENY` against clickjacking but notes the CSP `frame-ancestors` directive obsoletes it for supporting browsers, and that it provides nothing for redirects or JSON API responses. For cross-origin access headers see [CORS misconfiguration](/posts/cors-misconfiguration-what-access-control-allow-origin-actually-permits/), and for another cookie- and header-based defense see [CSRF protection with SameSite cookies, tokens and Fetch Metadata](/posts/csrf-protection-samesite-cookies-tokens-and-fetch-metadata-compared/).

## A rollout order that limits breakage

This ordering is our editorial judgment built on the behaviors above:

1. **Audit what you send.** Inspect responses for all hostnames, not just the main site, including error pages and redirects.
2. **Add `nosniff` and fix any wrong `Content-Type` values** it exposes.
3. **Set `Referrer-Policy` explicitly.** It is the lowest-risk change here.
4. **Add `Permissions-Policy`** disabling features you do not use.
5. **Add HSTS with a short `max-age`,** then raise it after checking every subdomain. Consider preload last.
6. **Remove deprecated headers** listed above.

## Sources and verification

Checked on October 11, 2026. We read each page below; we did not test headers on a live server or in browsers.

| Important claim | Source | Verification |
|---|---|---|
| OWASP's recommended values for HSTS, nosniff, Referrer-Policy and Permissions-Policy; recommendation to set Referrer-Policy explicitly; X-Frame-Options and COOP notes; do not set X-XSS-Protection; do not use Expect-CT or Public-Key-Pins; remove Server and X-Powered-By | [OWASP HTTP Headers Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html) | Verified |
| HSTS behavior: max-age, includeSubDomains, ignored over HTTP, first-visit gap, expiry refresh, max-age=0, no click-through | [MDN: Strict-Transport-Security](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Strict-Transport-Security) | Verified |
| Preload requirements and "cannot easily be undone" warning | [hstspreload.org](https://hstspreload.org/) | Verified: page has no visible date; read October 11, 2026 |
| nosniff only valid value; script and style blocking; no sniffing elsewhere | [MDN: X-Content-Type-Options](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/X-Content-Type-Options) | Verified |
| Referrer-Policy values and default of strict-origin-when-cross-origin | [MDN: Referrer-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Referrer-Policy) | Verified |
| Permissions-Policy syntax, effects of disabling features, "Limited availability" and "Experimental" labels | [MDN: Permissions-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Permissions-Policy) | Qualified: MDN labels reflect the page when we read it and may change |
| The suggested rollout order and the comparison that no-referrer sends least | Our analysis of the pages above | Qualified: editorial judgment, not a quoted recommendation |
