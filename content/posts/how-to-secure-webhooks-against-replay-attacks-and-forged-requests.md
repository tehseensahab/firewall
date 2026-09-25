+++
title = "How to Secure Webhooks Against Replay Attacks and Forged Requests"
date = 2026-10-18T09:00:00Z
tags = ["api security", "appsec"]
summary = "A webhook endpoint is a public URL that triggers real actions when it receives a POST request. That combination is exactly what makes it worth securing deliberately, not by default configuration."
description = "How to secure webhook endpoints against forged requests and replay attacks: signature verification, idempotency, IP allowlisting, and what each control actually stops."
author = "FirewallSync Editorial"
+++

A webhook endpoint is, structurally, a public URL that triggers a real action — fulfilling an order, provisioning access, updating a record — whenever it receives a POST request shaped correctly. That combination is exactly what makes it worth securing deliberately: unlike most of your API, a webhook receiver is designed to accept unsolicited, unauthenticated-by-default requests from the outside, because it doesn't get to choose when the sending service decides to call it.

## Forged requests: proving the request actually came from who it claims

Without any verification, anyone who discovers your webhook URL can send a request shaped like a legitimate event — a fake `payment_intent.succeeded`, a forged `user.created` — and your system will act on it as if it were real. Signature verification is the control that closes this: the sending service signs the payload with a shared secret (typically HMAC-SHA256), includes that signature in a header, and your endpoint recomputes the signature from the raw request body and compares it before processing anything.

The detail that trips up a lot of implementations: signature verification has to happen against the raw, unparsed request body. If your framework parses the JSON first and you compute the signature from the re-serialized object, whitespace or key-ordering differences can cause a legitimate request to fail verification, or — more dangerously — lead teams to weaken verification to work around the mismatch rather than fixing the root cause.

## Replay attacks: a valid signature doesn't mean a fresh request

A correct signature proves the request was signed by someone holding the shared secret. It doesn't prove the request is happening now rather than being a captured copy of a legitimate request from earlier, resent by an attacker who intercepted it. If that webhook triggers a one-time action — issuing a refund, granting access, sending a notification — a replay causes real harm even with a perfectly valid signature.

This is why timestamp-based replay protection matters as a distinct control from signature verification, not a redundant one. The sending service includes a timestamp as part of what gets signed, and your endpoint rejects any request where that timestamp is too far from the current time — typically a window of a few minutes. Critically, the timestamp itself has to be part of the signed payload, not just present alongside it; otherwise an attacker can replay an old payload with a freshly forged timestamp appended.

## Idempotency: the backstop for legitimate duplicate delivery

Most webhook providers explicitly don't guarantee exactly-once delivery — network issues or retries on their end can cause the same legitimate event to arrive more than once. This means your endpoint needs idempotent processing regardless of replay protection, using the event's unique ID (which providers include specifically for this) to detect and skip duplicates you've already processed, rather than assuming signature and timestamp checks alone guarantee single delivery.

## IP allowlisting, as a secondary layer, not a primary control

Some providers publish the IP ranges their webhooks are sent from, and allowlisting those ranges at the network level adds a layer that doesn't depend on your application code being correct. It shouldn't be relied on as the primary defense, though — IP ranges change, some providers don't publish stable ranges at all, and it does nothing against an attacker who has actually compromised the legitimate sending service. Treat it as defense in depth alongside signature verification, not a replacement for it.

## What to do when verification fails

Reject the request immediately, with no partial processing, and log enough detail to investigate (source IP, timestamp, which check failed) without logging the payload itself if it might contain sensitive data. A pattern of failed verifications from the same source is worth alerting on specifically — it's a more direct signal of an active probing attempt than most other logs your system produces.

## A practical checklist

- Verify signatures against the raw request body, before any JSON parsing
- Require timestamp validation as a distinct check from signature validity, with the timestamp itself included in the signed payload
- Process events idempotently using the provider's event ID, regardless of replay protection
- Treat IP allowlisting as a secondary layer, not a substitute for signature verification
- Reject-and-log on any verification failure, and alert on repeated failures from the same source

Every one of these addresses a different failure mode — forgery, replay, and legitimate duplication are three distinct problems that happen to look similar from the outside. A webhook endpoint that only handles one of them is still exposed to the other two.
