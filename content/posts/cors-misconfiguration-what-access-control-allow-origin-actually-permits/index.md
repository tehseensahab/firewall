+++
title = "CORS Misconfiguration: What Access-Control-Allow-Origin Actually Permits"
date = 2026-10-08T08:15:00Z
tags = ["appsec", "api-security"]
categories = ["appsec"]
summary = "A CORS header decides which other websites may read your responses with your users' cookies attached. Reflecting the Origin header, matching it with endsWith or an unescaped regex, or trusting null each hands that read access to an attacker."
description = "CORS misconfiguration explained: what Access-Control-Allow-Origin with credentials allows, the origin-matching bugs attackers exploit, and a tested fix."
author = "FirewallSync Editorial"
imageAlt = "Blue and white light in a dark room"
imageCredit = "Photo by [Denny Müller](https://unsplash.com/photos/JyRTi3LoQnc) on Unsplash"
takeaways = [
  "CORS does not block requests. It controls whether script on another website may read the response.",
  "The dangerous combination is a specific Access-Control-Allow-Origin value plus Access-Control-Allow-Credentials: true, because that lets the other site read data fetched with your user's cookies.",
  "Browsers refuse the wildcard * for credentialed requests, so the common shortcut is to echo back whatever Origin the request carried. That gives every website on the internet read access.",
  "Suffix checks, prefix checks and regexes with unescaped dots accept attacker-registered domains. In our tests, a check for endsWith(\"example.com\") accepted https://evilexample.com.",
  "Compare the Origin header against an exact list of allowed origins, never allow null, and send Vary: Origin."
]

[[faq]]
q = "What does Access-Control-Allow-Origin: * allow?"
a = "It lets script on any website read the response, but only for requests made without credentials such as cookies. Browsers block access to the response if the request included credentials and the header is the wildcard. For public, non-personal data that is usually fine."

[[faq]]
q = "Is it safe to reflect the Origin header in Access-Control-Allow-Origin?"
a = "Not with Access-Control-Allow-Credentials: true. Reflecting every Origin is equivalent to allowing every website to read authenticated responses. Reflect the Origin only after it matches an exact entry in an allowlist."

[[faq]]
q = "Why is allowing the null origin dangerous?"
a = "Browsers send Origin: null in several situations that an attacker can create, including requests from sandboxed iframes. PortSwigger's research describes using a sandboxed iframe to send a cross-origin request that carries Origin: null, which then matches an allowlist entry for null."

[[faq]]
q = "Does CORS protect against CSRF?"
a = "No. CORS governs reading responses. A cross-site form post or a simple request is still sent with cookies, subject to SameSite rules, whatever the CORS headers say. Protect state-changing endpoints with CSRF defenses."

[[faq]]
q = "Does CORS protect my API from non-browser clients?"
a = "No. CORS is enforced by browsers. Tools such as curl and server-side code ignore it, so authentication and authorization on the server are still required."
+++

Cross-Origin Resource Sharing (CORS) headers answer one question: may script running on another website read this response? If your API answers "yes" to the wrong origin and also allows credentials, that website can read your users' data using their own logged-in sessions. Most real CORS vulnerabilities come from a short list of origin-matching mistakes, and all of them are fixed the same way: compare the `Origin` header against an exact list.

## What CORS actually controls

Browsers apply the same-origin policy: script loaded from one origin cannot read responses from another. An origin is the scheme, host and port together, so `https://app.example.com` and `https://api.example.com` are different origins. MDN describes CORS as "an HTTP-header based mechanism that allows a server to indicate any origins (domain, scheme, or port) other than its own from which a browser should permit loading resources."

Three facts shape everything below:

- **CORS relaxes a restriction; it does not add one.** Without CORS headers, other origins cannot read your responses. Every CORS header you add widens access.
- **CORS governs reading, not sending.** For a simple request, which MDN defines as a GET, HEAD or POST using only safelisted headers and one of three content types (`application/x-www-form-urlencoded`, `multipart/form-data` or `text/plain`), the browser sends the request without asking first. CORS decides only whether the calling script gets the response. Other requests trigger a preflight `OPTIONS` request before the real one is sent.
- **Browsers enforce it; servers do not.** A command-line client ignores CORS entirely. PortSwigger puts it plainly: "CORS defines browser behaviors and is never a replacement for server-side protection of sensitive data."

## Credentials are what make it dangerous

By default, a cross-origin `fetch()` does not send cookies. A script must ask for them with `credentials: "include"`, and the browser then makes the response available only if the server replies with `Access-Control-Allow-Credentials: true`.

The browser adds a second safeguard. MDN says that when responding to a credentialed request the server "must not specify the `*` wildcard" for `Access-Control-Allow-Origin` and must instead name an explicit origin. The same rule applies to the allowed headers, allowed methods and exposed headers.

| Response headers | Request without cookies | Request with cookies |
|---|---|---|
| No CORS headers | Response hidden from the calling script | Response hidden |
| `Access-Control-Allow-Origin: *` | Any website can read the response | Browser blocks access to the response |
| `Access-Control-Allow-Origin: https://app.example.com` | That origin can read it | Hidden: credentials header missing |
| Same, plus `Access-Control-Allow-Credentials: true` | That origin can read it | That origin can read your user's authenticated data |

The last row is the one to get right. It is also where the wildcard rule pushes developers into the worst shortcut.

## The five misconfigurations that matter

PortSwigger's Web Security Academy groups CORS vulnerabilities into a handful of classes. These are the ones that reach authenticated data.

### 1. Reflecting any Origin

The wildcard is refused for credentialed requests, so some servers copy the request's `Origin` header straight into `Access-Control-Allow-Origin` and add `Access-Control-Allow-Credentials: true`. PortSwigger describes this as the application that "reflects arbitrary origins". The effect is identical to a wildcard that browsers would allow with cookies: any website a logged-in user visits can read their data from your API.

### 2. Matching the Origin with a prefix, suffix or loose regex

Allowlists implemented as string tests are easy to get wrong. We tested three common shortcuts in Python against a set of origins:

| Origin header | Exact match against a list | `endswith("example.com")` | `startswith("https://app.example.com")` | Regex `https://.*.example.com` |
|---|---|---|---|---|
| `https://app.example.com` | Allowed | Allowed | Allowed | Allowed |
| `https://evilexample.com` | Rejected | **Allowed** | Rejected | **Allowed** |
| `https://attacker-example.com` | Rejected | **Allowed** | Rejected | **Allowed** |
| `https://app.example.com.evil.net` | Rejected | Rejected | **Allowed** | **Allowed** |
| `http://app.example.com` | Rejected | **Allowed** | Rejected | Rejected |
| `null` | Rejected | Rejected | Rejected | Rejected |

Every bold cell is an origin an attacker can obtain by registering a domain, or in the last case by serving content over plain HTTP. The regex fails two ways at once: the dot before `example.com` is unescaped, so it matches any character, and Python's `re.match` anchors only the start of the string, so trailing text is accepted.

### 3. Allowing the `null` origin

Some applications allow `Origin: null` to make local development work. PortSwigger notes that an attacker can produce a request carrying `Origin: null` from "a sandboxed `iframe`". If `null` is on your list, so is every attacker who uses that trick. Its prevention advice is direct: "Avoid using the header `Access-Control-Allow-Origin: null`."

### 4. Trusting an origin that can be compromised

An allowlist is only as strong as the weakest origin on it. PortSwigger describes two cases. If a trusted origin has a cross-site scripting (XSS) flaw, an attacker can run script there and read your API through the trust you granted. If you trust an origin served over plain HTTP, such as `http://legacy.example.com`, an attacker who can intercept that traffic can inject script into it, even though your own site uses HTTPS everywhere.

### 5. Wildcards on internal services

Without credentials, the risk shifts to networks. PortSwigger explains that most CORS attacks rely on credentials, but internal sites, which are "often held to a lower security standard", can be read through a visitor's browser when they send `Access-Control-Allow-Origin: *`. A public website can use an employee's browser as a proxy to reach an intranet page that trusts its own network. PortSwigger's advice is to "avoid using wildcards in internal networks".

## The fix: an exact allowlist

This is a Flask hook that returns CORS headers only for exact matches. We ran it with Flask 3.1 on Python 3.13; it is a minimal illustration.

```python
from flask import Flask, request

app = Flask(__name__)

ALLOWED_ORIGINS = {"https://app.example.com", "https://admin.example.com"}


@app.after_request
def add_cors_headers(response):
    origin = request.headers.get("Origin")
    if origin in ALLOWED_ORIGINS:
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Credentials"] = "true"
    # The response differs by Origin either way, so caches must key on it.
    response.vary.add("Origin")
    return response
```

In our tests with Flask's test client, a request from `https://app.example.com` received `Access-Control-Allow-Origin: https://app.example.com` and `Access-Control-Allow-Credentials: true`. A request from `https://evil.example` and a request with no `Origin` header received neither header. All three responses carried `Vary: Origin`.

Why each line is there:

- **Set membership, not string tests.** The comparison is the whole origin string, scheme and port included. Add each origin you need, including each environment's front end, and nothing else.
- **`Vary: Origin` on every response.** MDN advises it whenever the allowed origin changes based on the request. Without it, a shared cache can store a response that carries one origin's headers and serve it to another.
- **Never add `null`.** If local development needs CORS, add `http://localhost:3000` (or your port) in development configuration only.
- **Only send `Access-Control-Allow-Credentials` where needed.** A public endpoint that serves the same data to everyone can use `*` without credentials.
- **Preflight responses need the same check.** Frameworks and CORS middleware usually answer `OPTIONS` for you. Confirm that they use the same allowlist and list only the methods and headers you actually accept.

If you use a CORS library, check how it interprets its configuration. Some accept a regex or a function, which reintroduces the matching problems in the table above.

## How to test your own API

Send a request with a foreign `Origin` and read the response headers. These are read-only GET requests; run them only against systems you are authorized to test.

```bash
curl -s -o /dev/null -D - -H "Origin: https://evil.example" https://api.example.com/me
curl -s -o /dev/null -D - -H "Origin: null" https://api.example.com/me
curl -s -o /dev/null -D - -H "Origin: https://evilexample.com" https://api.example.com/me
```

Any response that echoes the test origin in `Access-Control-Allow-Origin` while also sending `Access-Control-Allow-Credentials: true` is a finding. Test the endpoints that return personal data, not only the home page, because CORS is often configured per route.

## What CORS does not do

- **It does not stop CSRF.** A cross-site form submission or simple request is still sent, with cookies, subject to SameSite rules. CORS only hides the response. Our guide to [CSRF protection with SameSite cookies, tokens and Fetch Metadata](/posts/csrf-protection-samesite-cookies-tokens-and-fetch-metadata-compared/) covers that side.
- **It does not authenticate anyone.** It is a browser rule. Server-side authorization still decides who can see what.
- **It is not related to SSRF.** Server-side request forgery is a server making requests on an attacker's behalf, covered in [SSRF explained](/posts/ssrf-explained-how-server-side-request-forgery-works-and-how-to-prevent-it/).

## Sources and verification

Checked on October 8, 2026. We tested the matching functions and the Flask example with Flask's test client on Python 3.13, not in real browsers.

| Important claim | Source | Verification |
|---|---|---|
| CORS definition; simple request conditions; preflight; credentials not sent by default; wildcard not allowed for credentialed requests; browser blocks the response; `Vary: Origin` advice | [MDN, Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS) | Verified |
| CORS-safelisted methods are GET, HEAD and POST; safelisted `Content-Type` values | [Fetch Standard](https://fetch.spec.whatwg.org/), section 2.2 | Verified |
| Vulnerability classes: arbitrary origin reflection, origin parsing errors, `null` origin via sandboxed iframe, XSS on trusted origins, trusted HTTP origins, internal networks without credentials; prevention advice | [PortSwigger Web Security Academy, CORS](https://portswigger.net/web-security/cors) | Verified |
| Results of the four matching approaches in the table | Run in our build environment, Python 3.13 | Verified |
| Flask example response headers | Run with Flask 3.1 test client | Verified: not tested in browsers |
| Some CORS libraries accept regexes or functions | General observation | Qualified: check your library's documentation |
