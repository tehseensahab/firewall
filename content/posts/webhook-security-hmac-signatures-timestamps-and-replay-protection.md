+++
title = "Webhook Security: HMAC Signatures, Timestamps, and Replay Protection"
date = 2026-10-19T09:00:00Z
tags = ["api security", "appsec"]
summary = "Nearly every major provider signs webhooks with HMAC-SHA256, but the implementation details differ enough between them that copying one provider's verification code for another is a common source of silent bugs."
description = "A technical look at how HMAC webhook signatures actually work — Stripe, GitHub, and Shopify's implementations compared, and where verification code commonly breaks."
author = "FirewallSync Editorial"
+++

Nearly every major provider — Stripe, GitHub, Shopify, Twilio — signs webhook payloads using HMAC-SHA256. The core mechanism is the same across all of them: compute a hash of the payload using a shared secret, send that hash alongside the request, and let the receiver recompute and compare it. The implementation details differ enough between providers that copying verification code written for one and pointing it at another is a common, quiet source of bugs.

## The core mechanism

HMAC (Hash-based Message Authentication Code) combines the payload with a shared secret through a cryptographic hash function in a way that's infeasible to forge without knowing the secret, and infeasible to reverse to recover the secret from the output. The receiver, holding the same secret, performs the identical computation and checks whether the result matches what was sent. If the payload was altered in transit, or if the request wasn't actually signed by someone holding the real secret, the computed and provided signatures won't match.

## Why comparison method matters as much as the hash itself

A naive equality check between the computed and provided signature strings (`==` in most languages) leaks timing information — comparison typically short-circuits at the first mismatched character, meaning a correct partial match takes marginally longer to reject than a completely wrong guess. Over enough attempts, this can theoretically let an attacker reconstruct a valid signature byte by byte. The fix is a constant-time comparison function (`crypto.timingSafeEqual` in Node.js, `hmac.compare_digest` in Python, and equivalents in other languages) that takes the same amount of time regardless of where the mismatch occurs.

## Provider differences that break naive implementations

**Raw body vs. parsed body.** Every provider signs the exact raw bytes of the request body they sent. If your framework parses the JSON body before your verification code runs, and you compute the signature from re-serializing that parsed object, the byte-level output can differ from the original even if the data is logically identical — different whitespace, different key ordering — causing verification to fail on entirely legitimate requests. Capture and verify against the raw body before any parsing happens.

**Encoding differences.** Most providers hex-encode the HMAC output, but not all — Shopify uses Base64 encoding for its `X-Shopify-Hmac-SHA256` header, for example. Verification code written assuming hex encoding everywhere will reject valid Shopify signatures. Check each provider's documentation for its specific encoding rather than assuming consistency.

**Header format and signed content.** Stripe's `Stripe-Signature` header includes a timestamp and one or more versioned signatures in a structured format (`t=<timestamp>,v1=<signature>`), and the signed content is the concatenation of the timestamp and the raw body, not the raw body alone — meaning Stripe's signature can't be verified correctly without also parsing out and including that timestamp in the comparison. GitHub's `X-Hub-Signature-256`, by contrast, signs the raw body directly with no timestamp included, which means GitHub webhooks need a separate mechanism for replay protection since the signature itself doesn't encode freshness.

## Why the timestamp has to be inside what's signed, not just alongside it

This is the detail that makes replay protection actually work rather than being theater. If a timestamp is included in the request but not as part of what gets hashed, an attacker who captures a legitimate request can strip the old timestamp, attach a fresh one, and forward it — the payload and secret are unchanged, so the signature still validates, and your freshness check now passes too. Stripe's scheme avoids this specifically by signing `timestamp.rawBody` together, so changing the timestamp without knowing the secret invalidates the signature. Any custom HMAC implementation you build for your own outgoing webhooks should follow this same pattern if replay protection matters.

## A minimal correct verification pattern

Regardless of provider-specific quirks, the shape of correct verification is consistent:

1. Capture the raw, unparsed request body
2. Extract the signature (and timestamp, if the provider includes one in the signed content) from the appropriate header
3. Recompute the HMAC using the raw body (and timestamp, if applicable) and your shared secret
4. Compare using a constant-time comparison function, never a standard equality operator
5. If a timestamp is present, separately verify it falls within an acceptable tolerance window before or alongside the signature check

## What this doesn't cover

Signature verification proves the request came from someone holding the shared secret and wasn't altered in transit. It doesn't guarantee exactly-once delivery — that still requires idempotent processing keyed on the event's unique ID, handled as a separate concern from signature verification itself. Getting the HMAC check right is necessary but not sufficient for a fully secure webhook receiver.
