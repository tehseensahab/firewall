+++
title = "How to Secure OAuth Tokens in Production"
date = 2026-10-07T09:00:00Z
tags = ["api security", "authentication"]
summary = "Most OAuth implementations follow the happy-path tutorial and skip the parts of the spec that exist specifically to stop token theft. Here's what the current best practice actually requires."
description = "How to secure OAuth 2.0 tokens in production: PKCE, refresh token rotation, sender-constrained tokens, and the mistakes RFC 9700 was written to stop."
author = "FirewallSync Editorial"
+++

Most OAuth implementations are built from a tutorial that gets the authorization flow working and stops there. The flow works, tokens get issued, and the implementation ships. What usually gets skipped is everything the specification's security guidance exists specifically to address: what happens when a token or authorization code is intercepted, replayed, or leaked.

The IETF published RFC 9700, "Best Current Practice for OAuth 2.0 Security," in January 2025, consolidating years of real-world attack patterns into concrete implementation guidance. It's worth treating as the actual checklist, not the original OAuth 2.0 RFCs from over a decade earlier.

## PKCE is not optional, for any client type

Proof Key for Code Exchange (PKCE) was originally recommended mainly for mobile and single-page apps that can't keep a client secret confidential. RFC 9700 now requires it for all client types, including confidential server-side clients. The reasoning: PKCE protects against authorization code injection regardless of whether the client can also hold a secret, and there's no meaningful downside to requiring it universally. If your authorization server allows a code exchange without a `code_verifier`, that's a gap worth closing even for your backend-only clients.

## The implicit grant is deprecated — stop using it

The implicit grant (`response_type=token`) returns access tokens directly in the URL fragment, which means they end up in browser history, referrer headers, and proxy or server logs, and they cannot be sender-constrained. RFC 9700 formally deprecates it, and OAuth 2.1 removes it entirely. If any client in your stack still uses it, migrate it to the authorization code flow with PKCE — this isn't a hardening nice-to-have, it's a known-broken pattern still in production in more codebases than it should be.

## Sender-constrained tokens change what "stolen" means

A bearer token, which is what most implementations issue, is usable by anyone who has a copy of it — there's no check that the party presenting it is the party it was issued to. Sender-constraining a token (binding it cryptographically to the client that requested it, via mechanisms like DPoP or mutual TLS) means a token copied out of logs or intercepted in transit is useless to the attacker, because they can't produce the binding proof. This is the difference between "token theft is prevented" and "token theft is survivable" — it doesn't stop leakage, but it neutralizes what the leaked token is worth.

## Refresh token rotation, and what to do when reuse is detected

A refresh token that never changes is a long-lived credential wearing a short-lived token's reputation. Rotating refresh tokens on every use — issuing a new one and invalidating the previous one each time — limits how long a stolen refresh token remains useful. The part teams skip: what happens when a rotated-out refresh token gets used anyway. That's a strong signal of token theft (an attacker replaying an old value), and RFC 9700's guidance is to treat it as a compromise event — invalidate the entire token family, not just the one reused token, and force reauthentication.

## Where tokens actually leak in practice

Beyond the protocol-level attacks the RFC addresses, tokens commonly leak through mundane paths: logged in application or proxy logs, cached in browser storage longer than intended, or sent to a resource server over a redirect chain that includes a third-party domain. Audit logging configuration specifically for token values (redact them by default, don't rely on remembering to strip them per log line), and set token lifetimes short enough that a leaked access token has a narrow window of usefulness even before rotation or revocation kicks in.

## A practical checklist

- PKCE enforced for every client type, no exceptions for "trusted" confidential clients
- No implicit grant anywhere in the stack — migrate any remaining usage
- Refresh tokens rotated on every use, with reuse detection treated as a compromise signal
- Sender-constrained tokens (DPoP or mTLS) where the resource server supports it
- Access token lifetimes short enough to limit blast radius from an undetected leak
- Logging configuration audited to confirm tokens are redacted, not just assumed to be

None of this replaces basic hygiene — scoping tokens to the minimum permissions they need, and treating a leaked token with broad scope as a bigger incident than one scoped narrowly. The protocol-level protections reduce how often theft happens and how much a successful theft is worth; they don't remove the need to limit what any single token can do in the first place.
