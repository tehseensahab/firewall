+++
title = "Webhook Security: Signatures, Replay Protection, Idempotency"
date = 2026-10-19T09:00:00Z
lastmod = 2026-10-22T19:20:00Z
tags = ["api security", "appsec"]
categories = ["appsec"]
summary = "A webhook receiver is a public URL that triggers real actions. Securing it takes three separate controls: HMAC signature verification against the raw body, a freshness check on a signed timestamp, and idempotent processing keyed on the event ID. Here is how Stripe, GitHub and Shopify differ, with tested Python verification code."
description = "Webhook security: verify HMAC signatures on the raw body, reject stale or replayed deliveries, dedupe by event ID. Stripe, GitHub and Shopify compared, with tested code."
author = "FirewallSync Editorial"
imageAlt = "Close-up of colourful syntax-highlighted JavaScript on a dark screen, including a SQL query string"
imageCredit = "Photo by [Gabriel Heinzer](https://unsplash.com/photos/g5jpH62pwes) on Unsplash"
takeaways = [
  "A webhook endpoint accepts unsolicited POST requests from the internet and acts on them. Without verification, anyone who finds the URL can send a fake 'payment succeeded' event.",
  "Forgery, replay and duplicate delivery are three different problems. Signatures stop forgery, a signed timestamp limits replay, and idempotent processing keyed on the event ID handles both replays inside the time window and the provider's own retries.",
  "Verify the HMAC against the raw request bytes, before any JSON parsing, and compare with a constant-time function such as Python's hmac.compare_digest or Node's crypto.timingSafeEqual.",
  "Providers differ: Stripe signs '<timestamp>.<body>' and sends t= and v1= values; GitHub sends sha256=<hex> of the body with no timestamp; Shopify sends a Base64 digest. Copying one provider's verifier for another fails quietly.",
  "IP allowlisting, which Stripe and GitHub both document, is a useful extra layer but not a substitute for signature checks."
]

[[faq]]
q = "Does a valid signature mean the request is safe to process?"
a = "It means the body was signed by someone holding the secret and wasn't changed. It doesn't mean the request is new: a captured request can be resent with the same valid signature. You also need a freshness check where the provider signs a timestamp, and duplicate detection by event or delivery ID."
[[faq]]
q = "How does GitHub protect against webhook replay without a timestamp?"
a = "GitHub's documentation recommends using the X-GitHub-Delivery header, which is unique per event, to detect replays. It notes that a redelivery you request keeps the same X-GitHub-Delivery value, so storing processed delivery IDs also absorbs redeliveries."
[[faq]]
q = "What tolerance should I use for Stripe's timestamp?"
a = "Stripe's libraries default to 5 minutes. Stripe warns not to set the tolerance to 0, which disables the recency check, and recommends keeping your server clock synchronized with NTP. Stripe generates a new timestamp and signature for each retry, so retries don't fail the check."
[[faq]]
q = "Why does my signature check fail on legitimate requests?"
a = "Usually because the framework parsed the JSON before your code saw the body, so you're hashing a re-serialized copy. Stripe's documentation names whitespace changes, key reordering and encoding changes as causes. Other common causes are using the wrong secret, the wrong encoding (hex versus Base64) or, for Stripe, leaving the timestamp out of the signed string."
+++

A webhook endpoint is a public URL that fulfils an order, grants access or updates a record whenever it receives a correctly shaped POST request. Unlike most of your API, it is designed to accept unsolicited requests from outside, because the sending service decides when to call it. That makes three separate problems worth handling deliberately: **forged** requests from someone who isn't the provider, **replayed** copies of real requests, and **duplicate** deliveries of the same real event by the provider itself.

**Scope.** Provider details below come from Stripe's webhook documentation, GitHub's "Validating webhook deliveries" and "Best practices for using webhooks" pages, and Shopify's "Verify webhook deliveries" page, read on October 22, 2026. The Python verification code was run with Python 3.13 against GitHub's published test vector and against signatures we generated; it was not run against live provider traffic. Providers change their schemes, so check their current documentation before you ship.

## Forgery: verify an HMAC signature, on the raw body

Stripe, GitHub and Shopify all sign deliveries with HMAC-SHA256 (hash-based message authentication code using SHA-256). The provider computes an HMAC of the payload with a secret shared with you and sends it in a header; you recompute it and compare. Stripe's documentation puts the risk plainly: without verification, an attacker could send fake events to trigger actions like fulfilling orders, granting account access or modifying records.

Two implementation details decide whether this works.

**Hash the exact bytes you received.** Every provider signs the raw body it sent. Stripe lists the ways frameworks break this: adding or removing whitespace, reordering keys, converting the string to JSON, or changing the encoding. In Express, for example, Stripe notes that `express.json()` applied before the webhook route parses the body first and makes verification fail. Capture the raw body for the webhook route, verify, then parse. When verification fails on real traffic, fix the body capture; don't weaken the check.

**Compare in constant time.** GitHub's documentation says never to use a plain `==` and to use a constant-time comparison such as `crypto.timingSafeEqual` (Node.js) or `secure_compare` (Ruby) to mitigate timing attacks; Stripe says the same. In Python, use `hmac.compare_digest`.

## How the three providers differ

| | Stripe | GitHub | Shopify |
|---|---|---|---|
| Header | `Stripe-Signature` | `X-Hub-Signature-256` | `X-Shopify-Hmac-SHA256` |
| Format | `t=<unix time>,v1=<hex>` (can contain several `v1` values; test events also carry a fake `v0`) | `sha256=<hex>` | Base64 digest |
| What is signed | `<timestamp>.<raw body>` | Raw body | Raw body |
| Secret | Per-endpoint signing secret (`whsec_...`) | Webhook secret you set | App's client secret |
| Freshness | Signed timestamp; libraries default to 5 minutes' tolerance | None in the signature; use `X-GitHub-Delivery` | None in the signature; use `X-Shopify-Webhook-Id` for duplicates |

Stripe adds two details worth copying into any verifier: ignore every scheme except `v1`, which it says prevents downgrade attacks, and accept any one of several `v1` signatures, because during a secret rollover (up to 24 hours) Stripe signs with each active secret.

### Tested verification code

```python
import base64, hashlib, hmac, time

def _hmac(secret: bytes, msg: bytes) -> bytes:
    return hmac.new(secret, msg, hashlib.sha256).digest()

def verify_github(raw_body: bytes, header: str, secret: bytes) -> bool:
    # X-Hub-Signature-256: "sha256=" + hex digest of the raw body
    expected = "sha256=" + _hmac(secret, raw_body).hex()
    return hmac.compare_digest(expected, header or "")

def verify_shopify(raw_body: bytes, header: str, secret: bytes) -> bool:
    # X-Shopify-Hmac-SHA256: base64 of the HMAC of the raw body
    expected = base64.b64encode(_hmac(secret, raw_body)).decode()
    return hmac.compare_digest(expected, header or "")

def verify_stripe(raw_body: bytes, header: str, secret: bytes,
                  tolerance: int = 300, now: int | None = None) -> bool:
    # Stripe-Signature: "t=<unix time>,v1=<hex>[,v1=...]" over "<t>.<raw body>"
    parts = [p.split("=", 1) for p in (header or "").split(",") if "=" in p]
    ts = next((v for k, v in parts if k == "t"), None)
    sigs = [v for k, v in parts if k == "v1"]          # ignore v0 and others
    if ts is None or not ts.isdigit() or not sigs:
        return False
    expected = _hmac(secret, ts.encode() + b"." + raw_body).hex()
    if not any(hmac.compare_digest(expected, s) for s in sigs):
        return False
    now = int(time.time()) if now is None else now
    return abs(now - int(ts)) <= tolerance
```

What we checked on October 22, 2026:

| Test | Result |
|---|---|
| GitHub's published test vector (secret `It's a Secret to Everybody`, payload `Hello, World!`) | Accepted |
| GitHub-style signature checked against a re-serialized body (spaces added after colons) | Rejected |
| Shopify Base64 signature | Accepted; the same digest sent as hex was rejected |
| Stripe signature checked 60 seconds after its timestamp | Accepted |
| Same Stripe signature checked 10 minutes later (default 5-minute tolerance) | Rejected |
| Stripe header with the timestamp changed but the original `v1` signature | Rejected |
| Stripe header with only a `v0` signature | Rejected |

For production, prefer the provider's official library where one exists (Stripe recommends its libraries over manual verification). Code like the above is for providers without one, or for understanding what the library does.

## Replay: a valid signature isn't a fresh request

A signature proves who signed the body, not when the request was sent. An attacker who captures a real delivery can resend it, and the signature still verifies. If the webhook triggers a one-time action, such as a refund or an access grant, that replay does real harm.

**The timestamp must be inside what's signed.** Stripe's documentation explains why it signs `timestamp.body`: an attacker can't change the timestamp without invalidating the signature, so a stale request can be rejected. A timestamp sent alongside the signature but not covered by it gives no protection, because an attacker can replace it. Our test above shows the difference: swapping the timestamp broke the signature. If you design your own outgoing webhooks, copy this pattern.

Stripe's libraries default to a 5-minute tolerance. Stripe warns that a tolerance of `0` disables the recency check entirely, and recommends keeping your clock synchronized with NTP (Network Time Protocol). It also notes that each retry gets a new timestamp and signature, so legitimate retries aren't rejected as stale.

**A time window is not the whole answer.** A replay inside the tolerance window still passes. GitHub and Shopify don't sign a timestamp at all. That is why the next control matters.

## Duplicates: process each event once

Providers retry. Stripe says it retries live-mode deliveries for up to three days and that endpoints "might occasionally receive the same event more than once". Shopify says it retries 8 times over 4 hours after a failure. None of the three promises exactly-once delivery.

The fix is to record the ID of every event you've processed and skip ones you've seen:

- **Stripe:** log processed event IDs. Stripe also notes that two separate Event objects can occasionally be generated for the same change; it suggests using the `data.object` ID together with the event type to spot those. Don't use the `created` timestamp to detect duplicates or ordering.
- **GitHub:** use `X-GitHub-Delivery`, which GitHub describes as unique per event and recommends specifically against replay attacks. A redelivery you request keeps the same value.
- **Shopify:** make processing idempotent, or deduplicate on `X-Shopify-Webhook-Id`. `X-Shopify-Event-Id` groups deliveries caused by the same merchant action, which matters if you have several subscriptions to one topic.

Recording the ID and performing the action should succeed or fail together, for example in one database transaction with a unique constraint on the event ID. Otherwise a crash between the two can lose or double-process an event.

This one control handles three cases at once: provider retries, redeliveries, and replays that slip inside the timestamp window.

## IP allowlisting: an extra layer, not a primary control

Stripe publishes the IP addresses it sends webhooks from and recommends allowlisting them alongside signature verification. GitHub publishes its webhook source addresses through its `GET /meta` API and notes that they change occasionally, so the allow list needs regular updates. An allow list doesn't depend on your application code being right, which is its value. It doesn't help if the address list is stale, if a provider doesn't publish one, or if the attacker is sending through the provider's own infrastructure, so keep signature verification as the primary check.

## Operational details that matter

- **Respond fast, process later.** GitHub treats a delivery as failed if you don't respond with a 2xx within 10 seconds (on GitHub.com), and Stripe says to return 2xx before complex logic. Verify, record the event, queue the work, then respond.
- **Reject on any failed check.** Do no partial processing. Log which check failed, the source IP and the delivery ID, but avoid logging full payloads that may contain personal or payment data. Repeated failures from one source are worth an alert.
- **Exempt only the webhook route from CSRF checks.** Stripe notes that frameworks such as Rails and Django may require a CSRF token on every POST and block webhooks; scope the exemption to the webhook route, which is protected by its signature instead. See our [CSRF protection guide](/posts/csrf-protection-samesite-cookies-tokens-and-fetch-metadata-compared/) for why the rest of the app should keep it.
- **Rotate secrets.** Stripe recommends rolling signing secrets periodically or when you suspect exposure, and supports an overlap of up to 24 hours. Store webhook secrets like any other credential; our guide on [detecting and rotating leaked API keys](/posts/how-to-detect-and-rotate-leaked-api-keys-before-attackers-use-them/) covers the process.
- **Only subscribe to events you handle.** Stripe recommends it, and it shrinks the set of actions a forged or replayed event could trigger.

## Checklist

- Capture the raw body for the webhook route and verify before parsing.
- Use the provider's exact scheme: header, encoding, signed string, accepted versions.
- Compare signatures in constant time.
- Where a timestamp is signed, enforce a tolerance of a few minutes, never zero, and keep clocks in sync.
- Record processed event or delivery IDs atomically with the action, and skip duplicates.
- Treat IP allowlists as defense in depth.
- Respond quickly; process asynchronously.
- Reject and log failures; alert on repeats.

Webhook receivers are one entry in a wider API surface; [our public REST API checklist](/posts/how-to-secure-a-public-rest-api-a-production-checklist/) covers the rest.

## About this article

This guide combines two earlier FirewallSync articles on webhook security, published October 18 and 19, 2026, into one updated reference. The October 18 URL now redirects here. We added provider documentation references, a provider comparison and tested code.

## Sources and verification

Checked on October 22, 2026.

| Important claim | Source | Verification |
|---|---|---|
| Stripe header format, `v1` only, `v0` test signature, signed string `timestamp.body`, constant-time comparison, default 5-minute tolerance, never 0, NTP, new timestamp per retry, multiple signatures during secret roll (up to 24 hours) | [Stripe: Receive Stripe events in your webhook endpoint](https://docs.stripe.com/webhooks) | Verified |
| Raw body required; frameworks that reorder keys or change whitespace break verification; Express middleware order | [Stripe: Resolve webhook signature verification errors](https://docs.stripe.com/webhooks/signature) and the Stripe webhooks page | Verified |
| Stripe retries up to three days in live mode; duplicate events; log event IDs; don't use `created`; IP list; CSRF exemption; subscribe only to needed events | [Stripe: webhooks best practices](https://docs.stripe.com/webhooks) | Verified |
| GitHub `X-Hub-Signature-256`, hex digest starting `sha256=`, never `==`, test vector | [GitHub Docs: Validating webhook deliveries](https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries) | Verified |
| GitHub IP list via `GET /meta`; respond within 10 seconds; `X-GitHub-Delivery` against replay; same value on redelivery | [GitHub Docs: Best practices for using webhooks](https://docs.github.com/en/webhooks/using-webhooks/best-practices-for-using-webhooks) | Verified |
| Shopify `X-Shopify-Hmac-SHA256`, Base64, raw body, client secret; idempotency; `X-Shopify-Webhook-Id` and `X-Shopify-Event-Id`; 8 retries over 4 hours | [Shopify: Verify webhook deliveries](https://shopify.dev/docs/apps/build/webhooks/verify-deliveries) | Verified |
| Verification code results | Run by us on October 22, 2026 with Python 3.13 | Verified; not tested against live provider traffic |
