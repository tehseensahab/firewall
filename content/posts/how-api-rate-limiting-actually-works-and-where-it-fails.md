+++
title = "How API Rate Limiting Actually Works—and Where It Fails"
date = 2026-10-14T09:00:00Z
tags = ["api security", "appsec"]
summary = "Rate limiting is treated as a solved problem once it's implemented. In practice, the algorithm and the scope you choose determine whether it actually stops abuse or just adds latency to legitimate traffic."
description = "How API rate limiting actually works: fixed window, sliding window, and token bucket algorithms compared, and where rate limiting fails in practice."
author = "FirewallSync Editorial"
+++

Rate limiting is often treated as a solved problem the moment it's implemented — a number is picked, a library is wired in, and the box gets checked. In practice, the algorithm behind that limit and the scope it's applied at determine whether it actually stops abuse or just adds latency to legitimate traffic while doing little against a determined attacker.

## Fixed window: simple, and exploitable at the boundary

The simplest approach counts requests in a fixed time window — for example, 100 requests per minute, reset every minute on the clock. It's cheap to implement and reason about, but it has a well-known edge-case flaw: a client can send 100 requests in the last second of one window and another 100 in the first second of the next, achieving 200 requests in roughly two seconds while technically staying within the stated limit for each window. For any rate limit meant to actually cap burst behavior, this boundary effect matters.

## Sliding window: closes the boundary gap, costs more to compute

A sliding window log or sliding window counter evaluates the limit over a continuously moving time range rather than discrete fixed buckets, which removes the boundary exploit. The tradeoff is implementation cost — a true sliding log requires tracking individual request timestamps (or an approximation of them), which is more expensive to store and compute at scale than a simple fixed counter, especially across a distributed system where the limit needs to be enforced consistently across multiple servers.

## Token bucket: the common choice for allowing controlled bursts

A token bucket algorithm fills a bucket with tokens at a steady rate, and each request consumes one token; if the bucket is empty, the request is rejected or delayed. This naturally allows short bursts (as long as tokens have accumulated) while still enforcing an average rate over time, which better matches how real client traffic behaves — mostly steady, with occasional legitimate spikes — compared to a hard fixed-window cutoff. It's the algorithm most production API gateways default to for this reason.

## The scope you apply it at matters as much as the algorithm

A global rate limit — capping total requests to an endpoint regardless of caller — protects your infrastructure from being overwhelmed, but does nothing to stop one abusive client from degrading service for every other legitimate caller sharing that same limit. Per-identity (authenticated user or API key) or per-IP limiting contains the impact of abuse to the specific source causing it, which is almost always the intent when rate limiting is framed as a security control rather than purely a capacity control.

The two aren't mutually exclusive — a global ceiling protects infrastructure, and a per-identity limit protects fairness and contains abuse, and most production systems need both layered together rather than picking one.

## Where rate limiting fails even when correctly implemented

**Distributed attacks split under the limit.** An attacker using many IP addresses or many low-volume accounts can stay under a per-identity or per-IP limit while still generating meaningful aggregate load or completing a credential-stuffing campaign slowly enough to avoid triggering any single bucket's threshold. Rate limiting alone doesn't solve this — it needs to be paired with anomaly detection that looks at aggregate patterns across identities, not just individual limits.

**Expensive endpoints need lower limits than uniform ones provide.** A rate limit set uniformly across an entire API treats a cheap read endpoint the same as a computationally expensive report-generation endpoint, meaning the "safe" uniform limit for the expensive endpoint is often still high enough to cause real resource exhaustion. Limits should reflect the actual cost of the operation, not just be copied across endpoints for consistency.

**Legitimate retries can look like abuse, and vice versa.** A client retrying after a transient failure, without backoff, can trip the same limit as an actual attacker, while a well-behaved distributed attack can stay just under it. Rate limiting is a blunt instrument for distinguishing intent — it should be one layer in a broader strategy that includes authentication, anomaly detection, and endpoint-specific cost awareness, not the sole control standing between an API and abuse.

## A practical approach

- Use token bucket (or a sliding window if implementation cost allows) rather than fixed window, if burst behavior and boundary exploitation matter for your traffic
- Apply limits both globally (infrastructure protection) and per-identity (abuse containment) rather than choosing one
- Set limits per-endpoint based on actual computational cost, not a single number applied uniformly
- Treat rate limiting as one layer, not the whole strategy — pair it with monitoring for distributed patterns that individually stay under any single limit
