+++
title = "CSRF Protection: SameSite Cookies, Tokens and Fetch Metadata Compared"
date = 2026-10-07T08:35:00Z
tags = ["appsec", "authentication"]
categories = ["appsec"]
summary = "SameSite cookies reduce cross-site request forgery but do not end it. Here is what each defense stops, where each one fails, and a header check you can add in a few lines."
description = "CSRF protection compared: what SameSite=Lax leaves open, when you still need CSRF tokens, and how to reject cross-origin requests with Sec-Fetch-Site."
author = "FirewallSync Editorial"
imageAlt = "Laptop on a desk showing code in an editor"
imageCredit = "Photo by [Emile Perron](https://unsplash.com/photos/xrVDYZRGdw4) on Unsplash"
takeaways = [
  "SameSite=Lax stops cross-site POST requests from carrying your session cookie, but it works per site, not per origin, so a sibling subdomain is not blocked.",
  "When a browser applies Lax as a default because no SameSite value was set, MDN documents a more permissive version: cross-site POSTs still carry cookies set in the previous two minutes. Set SameSite explicitly.",
  "The Sec-Fetch-Site request header tells the server whether a request came from the same origin, the same site or another site. MDN lists it as available across browsers since March 2023.",
  "Go 1.25, released in August 2025, added net/http.CrossOriginProtection, which blocks cross-origin state-changing requests using that header with no tokens.",
  "OWASP's cheat sheet still lists CSRF tokens ahead of Fetch Metadata, and says a cross-site scripting flaw can bypass CSRF protections whichever you choose."
]

[[faq]]
q = "Is SameSite=Lax enough to prevent CSRF?"
a = "Not on its own, according to OWASP's CSRF Prevention Cheat Sheet, which treats SameSite as defense in depth. Lax still sends cookies on cross-site top-level GET navigations, so any GET endpoint that changes state is exposed, and SameSite compares sites rather than origins, so a request from another subdomain of the same registrable domain is treated as same-site."

[[faq]]
q = "Do I still need CSRF tokens in 2026?"
a = "OWASP's cheat sheet still recommends them: use your framework's built-in protection if it has one, otherwise add tokens to state-changing requests, and use Fetch Metadata checks with a fallback. A header check such as Sec-Fetch-Site can replace tokens for browsers that send it, which is the approach Go's standard library took in version 1.25, but you need a fallback for requests that arrive without the header."

[[faq]]
q = "What is the Sec-Fetch-Site header?"
a = "It is a request header that browsers add automatically to say how the page making a request relates to the server receiving it. The values are same-origin, same-site, cross-site and none, where none means a user-initiated action such as typing a URL. Page JavaScript cannot set or change it, because it is a forbidden request header."

[[faq]]
q = "Does a JSON API need CSRF protection?"
a = "If it authenticates with cookies, yes. If it authenticates only with a token that JavaScript places in an Authorization header, a cross-site page cannot make the browser attach that token, so classic CSRF does not apply. Many APIs accept both, and those need protection for the cookie path."

[[faq]]
q = "What is the difference between CSRF and SSRF?"
a = "In cross-site request forgery (CSRF) the attacker tricks a victim's browser into sending a request with the victim's cookies. In server-side request forgery (SSRF) the attacker tricks a server into sending a request from inside your network. The names are similar and the defenses are unrelated."
+++

Cross-site request forgery (CSRF) is still possible in 2026, but the defaults have moved in your favor. If your session cookie is explicitly set to `SameSite=Lax` or `Strict`, every state-changing endpoint uses POST or another non-GET method, and you reject requests the browser labels as cross-origin, the classic attack is closed. Each of those three conditions is one that real applications miss, so this article goes through what each defense stops and where it fails.

## What the attack needs

A CSRF attack has three ingredients: a victim logged in to your site, a browser that attaches the victim's cookies to requests automatically, and a request that an attacker's page can make the browser send. The attacker's page never sees the response. It only needs the side effect: an email address changed, a transfer submitted, an API key created.

Every defense below works by breaking one of the last two ingredients. Either the cookie is not attached, or the server can tell the request did not come from its own pages.

## The four defenses compared

| | SameSite cookies | CSRF token | Fetch Metadata check | Custom header requirement |
|---|---|---|---|---|
| Where it runs | Browser decides whether to send the cookie | Server compares a secret value | Server reads `Sec-Fetch-Site` | Server requires a header a plain form cannot send |
| What you change | One cookie attribute | Every form and state-changing request | One middleware | Client code and one server check |
| Granularity | Site (registrable domain plus scheme) | Session | Origin or site, your choice | Origin, enforced by CORS |
| Protects GET endpoints that change state | No, with Lax | Only if you check tokens on GET | Only if you check GET | Only if required on GET |
| Stops a sibling subdomain | No | Yes, if tied to the session | Yes, if you reject `same-site` | Yes, unless CORS allows that origin |
| Works without browser support | No | Yes | No, needs a fallback | Yes |
| Server state needed | None | Session, or a signing key | None | None |

"Site" and "origin" are different things, and the gap between them is where several bypasses live. An origin is the scheme, host and port together: `https://app.example.com`. A site is the scheme plus the registrable domain: `https://example.com`. Two subdomains of one company are different origins on the same site.

## SameSite: what it does and the three gaps

MDN describes the three values of the cookie's `SameSite` attribute:

- **Strict** sends the cookie only for requests originating from the same site.
- **Lax** also sends it on cross-site requests that are top-level navigations using a safe method. In practice that means following a link, not submitting a cross-site POST form.
- **None** sends it everywhere, and requires the `Secure` attribute.

For a session cookie, `Lax` means an attacker's page can no longer submit a hidden POST form with your user's session attached. That removes the textbook attack. Three gaps remain.

**Gap 1: GET requests that change state.** `Lax` deliberately allows cookies on cross-site top-level GET navigations, so that links to your site work for logged-in users. If `/account/delete?confirm=1` works as a GET, a link is enough. OWASP's cheat sheet is blunt about the fix: never use GET for state changes.

**Gap 2: the default is weaker than the explicit setting.** Some browsers apply `Lax` when a cookie has no `SameSite` attribute at all. MDN notes that "when `Lax` is applied as a default, a more permissive version is used", in which cookies are also sent on cross-site POST requests "as long as they were set no more than two minutes before the request was made." That means a cookie issued moments ago, for example right after login, is exposed. Browsers also differ on whether they apply the default at all. The fix costs one attribute: set `SameSite=Lax` or `Strict` explicitly.

**Gap 3: same-site is not same-origin.** `SameSite` compares sites. A request from `https://blog.example.com` to `https://app.example.com` is same-site, so the cookie is sent whatever the setting. If any subdomain can run attacker-controlled script, through an abandoned DNS record, a user-content host or a cross-site scripting flaw in a marketing page, `SameSite` gives no protection against it. OWASP lists this registrable-domain behavior among the reasons it treats `SameSite` as defense in depth and not a standalone defense.

## CSRF tokens: still the reference defense

A CSRF token is a secret value the server gives its own pages and expects back on state-changing requests. An attacker's page cannot read it, so it cannot include it.

OWASP's cheat sheet describes two patterns:

- **Synchronizer token.** The server stores a random token in the user's session and compares it on each protected request. It should be sent in a hidden form field or a custom header, not in a cookie or URL.
- **Signed double-submit cookie.** For applications without server-side session storage. The token is an HMAC (a keyed hash) computed over the session identifier plus a random value, sent both as a cookie and in the request. OWASP recommends this signed form and warns that the naive version, a bare random value in a cookie compared with a request field, can be defeated by an attacker who is able to set cookies from a subdomain.

OWASP's ordering of advice is: use your framework's built-in CSRF protection if it has one; otherwise add tokens to state-changing requests and validate them on the server; consider Fetch Metadata headers with a fallback; then add defense-in-depth measures such as `SameSite`.

Tokens cost more to maintain than the alternatives. Every form, every JavaScript request and every cached page has to carry the right token, and "invalid CSRF token" errors after a session expires are a familiar support ticket. That maintenance cost is why the header-based approach below has gained ground. This is our assessment of the trade-off, not OWASP's wording.

## Fetch Metadata: let the browser tell you

Browsers attach a set of `Sec-Fetch-*` headers to requests. The one that matters here is `Sec-Fetch-Site`, which MDN defines as indicating "the relationship between a request initiator's origin and the origin of the requested resource." Its values:

| Value | Meaning |
|---|---|
| `same-origin` | The page making the request has the same scheme, host and port as the server |
| `same-site` | Same site, different origin, for example another subdomain |
| `cross-site` | A different site |
| `none` | A user-initiated action, such as typing a URL or opening a bookmark |

Two properties make it usable as a security control. It is a forbidden request header, so page JavaScript cannot set or alter it. And MDN lists it as available across browsers since March 2023.

One limit matters: MDN notes the header is only sent to potentially trustworthy URLs, which in practice means HTTPS. Over plain HTTP it is absent.

The check itself is short: for any request that is not GET, HEAD or OPTIONS, reject it unless `Sec-Fetch-Site` is `same-origin` or `none`.

### What Go's standard library does

Go 1.25, released in August 2025, added `net/http.CrossOriginProtection`. The release notes describe it as rejecting "non-safe cross-origin browser requests" using Fetch metadata, and say it "doesn't require tokens or cookies". Its logic, as we read the Go 1.25 source, is a useful reference whatever language you use:

1. GET, HEAD and OPTIONS are always allowed.
2. If `Sec-Fetch-Site` is present, the request is allowed only when the value is `same-origin` or `none`.
3. If `Sec-Fetch-Site` is absent but `Origin` is present, the `Origin` host is compared with the `Host` header, and the request is allowed if they match.
4. If neither header is present, the request is allowed, on the reasoning that it is either same-origin or not from a browser.
5. Explicitly trusted origins and bypass patterns are exempt.

Notice that step 2 rejects `same-site`. That closes Gap 3: a sibling subdomain is treated as untrusted unless you list it. Google's older web.dev guidance on Fetch Metadata, published in June 2020, allows `same-site` in its example policy. Which is right for you depends on whether you trust everything hosted under your domain. If you are unsure, reject `same-site` and add specific origins back.

### A working example in Python

The same logic as a Flask `before_request` hook. We ran this with Flask 3.1 on Python 3.13; it is a minimal illustration, not a drop-in library.

```python
from urllib.parse import urlsplit

from flask import Flask, abort, request

app = Flask(__name__)

SAFE_METHODS = {"GET", "HEAD", "OPTIONS"}
# Origins other than our own that may send state-changing requests, e.g. a separate admin UI.
TRUSTED_ORIGINS = {"https://admin.example.com"}


def is_cross_origin(req) -> bool:
    """True when a browser tells us the request came from another origin."""
    if req.headers.get("Origin") in TRUSTED_ORIGINS:
        return False
    site = req.headers.get("Sec-Fetch-Site")
    if site is not None:
        # same-origin: our own pages. none: typed URL or bookmark.
        return site not in ("same-origin", "none")
    origin = req.headers.get("Origin")
    if origin is None:
        # Neither header: not a current browser (curl, server-to-server).
        # CSRF needs a browser that attaches the victim's cookies.
        return False
    # Older browser: compare the Origin host with the Host we were addressed as.
    return urlsplit(origin).netloc != req.host


@app.before_request
def reject_cross_origin_writes():
    if request.method in SAFE_METHODS:
        return
    if is_cross_origin(request):
        abort(403, "cross-origin request rejected")
```

We tested it with Flask's test client against a POST route and a GET route:

| Request | Headers sent | Result |
|---|---|---|
| POST from the application's own page | `Sec-Fetch-Site: same-origin` | 200 |
| POST from another site | `Sec-Fetch-Site: cross-site` | 403 |
| POST from a sibling subdomain | `Sec-Fetch-Site: same-site` | 403 |
| POST from the listed admin origin | `Sec-Fetch-Site: same-site`, trusted `Origin` | 200 |
| POST with no `Sec-Fetch-Site`, matching `Origin` | `Origin` equals host | 200 |
| POST with no `Sec-Fetch-Site`, foreign `Origin` | `Origin` differs | 403 |
| POST with no `Sec-Fetch-Site`, `Origin: null` | Sandboxed or opaque origin | 403 |
| POST with neither header | As sent by curl | 200 |
| GET from another site | `Sec-Fetch-Site: cross-site` | 200 |

The last two rows are the limits, and they are deliberate:

- **Requests with neither header pass.** A command-line client or another server does not carry a victim's browser cookies, so there is nothing to forge. This does mean the check is not an authentication or anti-automation control.
- **GET is not checked.** The hook protects nothing if a GET route changes state.
- **The `Host` comparison trusts your proxy setup.** Behind a reverse proxy, the application must see the hostname the browser used. OWASP's cheat sheet advises accepting a forwarded host header only from proxies you control.
- **Plain HTTP gets the weaker path.** Without HTTPS the browser omits `Sec-Fetch-Site` and the check falls back to `Origin`.

## What none of these stop

**Cross-site scripting.** OWASP states that cross-site scripting (XSS) vulnerabilities can bypass CSRF protections. Script running in your own origin sends requests that are genuinely same-origin, can read tokens from the page, and gets the right `Sec-Fetch-Site` value. CSRF defenses assume your own pages are not hostile.

**Client-side CSRF.** OWASP describes a variant where your own JavaScript builds a request from attacker-influenced input, such as a URL fragment. The request is same-origin and carries a valid token, so server-side checks pass. The fix is validating what the script uses to build requests.

**Login CSRF.** An attacker can submit a login form with their own credentials, leaving the victim signed in to the attacker's account. OWASP recommends protecting login forms too, using a pre-session, and regenerating the session after authentication.

## What to do

This table is our recommendation, built on the sources above.

| Your situation | Recommended setup |
|---|---|
| Framework with built-in CSRF protection (for example Django, Rails, ASP.NET) | Leave it on. Set the session cookie's `SameSite` explicitly. Audit for GET routes that change state |
| Go 1.25 or later | Wrap handlers with `http.CrossOriginProtection`; list trusted origins explicitly |
| No built-in protection, HTTPS everywhere | Add the Fetch Metadata check with the `Origin` fallback; set `SameSite=Lax` or `Strict`; keep or add tokens on the highest-risk actions |
| Cookie-authenticated JSON API | The Fetch Metadata check, plus rejecting state-changing requests that are not `application/json`, plus a restrictive CORS policy that never combines a wildcard origin with credentials |
| Token-only API (`Authorization` header, no cookies) | Classic CSRF does not apply. Confirm no cookie-based path exists |
| Untrusted or user-controlled subdomains | Treat `same-site` as cross-site everywhere; do not rely on `SameSite` cookies |

Three checks apply in every row:

1. Search your routes for GET handlers with side effects and convert them.
2. Set `SameSite` explicitly on session cookies, with `Secure` and `HttpOnly`.
3. Fix XSS first. It defeats everything on this page.

The session cookie being protected here is the same one an attacker wants to steal outright. For the token side of that problem, see [how to secure OAuth tokens in production](/posts/how-to-secure-oauth-tokens-in-production/), and for the credentials behind the session, [password hashing parameters](/posts/password-hashing-argon2id-vs-bcrypt-vs-scrypt-which-to-use-and-with-what-parameters/). If you arrived looking for the server-side attack with the similar name, that is [SSRF, explained here](/posts/ssrf-explained-how-server-side-request-forgery-works-and-how-to-prevent-it/).

## Sources and verification

Checked on October 7, 2026. Browser behavior changes between releases, so confirm the SameSite defaults for the browsers you support against MDN's compatibility data. We tested the Python example with Flask's test client, not in real browsers.

| Important claim | Source | Verification |
|---|---|---|
| SameSite Strict, Lax and None definitions; None requires Secure; default-Lax two-minute POST allowance | [MDN, Set-Cookie](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Set-Cookie) | Verified |
| Sec-Fetch-Site values; forbidden request header; available across browsers since March 2023; sent only to potentially trustworthy URLs | [MDN, Sec-Fetch-Site](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Sec-Fetch-Site) | Verified |
| OWASP ordering of defenses; synchronizer and signed double-submit patterns; SameSite as defense in depth; never use GET for state changes; XSS bypasses CSRF protections; client-side and login CSRF | [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html), as published October 7, 2026 | Verified |
| Go 1.25 added CrossOriginProtection; released August 2025 | [Go 1.25 release notes](https://go.dev/doc/go1.25) | Verified |
| CrossOriginProtection logic (safe methods, Sec-Fetch-Site, Origin and Host fallback, neither header allowed) | [Go 1.25 source, net/http/csrf.go](https://github.com/golang/go/blob/release-branch.go1.25/src/net/http/csrf.go) | Verified: our reading of the source |
| web.dev example policy allows same-site | [web.dev, Protect your resources from web attacks with Fetch Metadata](https://web.dev/articles/fetch-metadata), June 4, 2020 | Verified |
| Python example behavior in the results table | Run in our build environment with Flask 3.1 on Python 3.13 | Verified: test client only, not real browsers |
| Browsers differ on applying Lax by default | MDN compatibility notes for Set-Cookie | Qualified: we did not list per-browser behavior |
| Framework examples with built-in CSRF protection | General knowledge of Django, Rails and ASP.NET; OWASP names .NET and Go 1.25 | Qualified: check your framework's documentation |
