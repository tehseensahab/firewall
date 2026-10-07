+++
title = "How to Secure OAuth Tokens in Production"
date = 2026-10-07T09:00:00Z
tags = ["api security", "authentication"]
categories = ["appsec"]
summary = "Most OAuth implementations follow the happy-path tutorial and skip the parts of the spec that exist specifically to stop token theft. Here's what the current best practice actually requires."
description = "How to secure OAuth 2.0 tokens in production: PKCE, refresh token rotation, sender-constrained tokens, and the mistakes RFC 9700 was written to stop."
author = "FirewallSync Editorial"
imageAlt = "Blurred laptop screen in a dark room showing JavaScript code in a code editor"
imageCredit = "Photo by [Mohammad Rahmani](https://unsplash.com/photos/8qEB0fTe9Vw) on Unsplash"
+++

Many OAuth implementations are built from a tutorial that gets the authorization flow working and stops there. The flow works, tokens get issued, and the implementation ships. What usually gets skipped is everything the specification's security guidance exists specifically to address: what happens when a token or authorization code is intercepted, replayed, or leaked.

The IETF (Internet Engineering Task Force) published [RFC 9700, "Best Current Practice for OAuth 2.0 Security"](https://www.rfc-editor.org/rfc/rfc9700.html) (BCP 240), in January 2025, consolidating years of real-world attack patterns into concrete implementation guidance. It's worth treating as the actual checklist, not the original OAuth 2.0 RFCs from over a decade earlier. Where this article says "must" or "should", it uses the RFC's own strength of wording, and says so when a point is general practice rather than something the RFC specifies.

## PKCE: required for public clients, recommended for everyone else

Proof Key for Code Exchange (PKCE, [RFC 7636](https://www.rfc-editor.org/rfc/rfc7636.html)) was originally associated mainly with mobile and single-page apps that can't keep a client secret confidential (so-called public clients). RFC 9700 section 2.1.1 says public clients "MUST use PKCE" and that for confidential clients (such as server-side apps that can authenticate to the authorization server) its use is "RECOMMENDED". PKCE protects against authorization code injection even when a client also holds a secret, so enabling it for backend clients too is a sensible hardening step. If your authorization server accepts a code exchange without a `code_verifier` for a public client, that is a gap to close now; for confidential clients, treat it as a gap worth closing, not a spec violation.

## Avoid the implicit grant

The implicit grant (`response_type=token`) returns access tokens directly in the URL fragment of the browser redirect, which exposes them to browser history, referrer headers and logging, as RFC 9700 describes in its discussion of token leakage. Section 2.1.2 says clients "SHOULD NOT" use it, or other response types that issue access tokens in the authorization response, unless access token injection is prevented and the leakage vectors are mitigated. The OAuth 2.1 specification omits the grant, but as of this writing OAuth 2.1 is still an IETF Internet-Draft (a work in progress), not a published standard. If any client in your stack still uses the implicit grant, plan a migration to the authorization code flow with PKCE.

## Sender-constrained tokens change what "stolen" means

A bearer token, which is what most implementations issue, is usable by anyone who has a copy of it — there's no check that the party presenting it is the party it was issued to. RFC 9700 says authorization and resource servers "SHOULD" use sender-constraining mechanisms, naming mutual TLS ([RFC 8705](https://www.rfc-editor.org/rfc/rfc8705.html)) and DPoP, Demonstrating Proof of Possession ([RFC 9449](https://www.rfc-editor.org/rfc/rfc9449.html)). Sender-constraining a token means binding it cryptographically to the client that requested it, so a token copied out of logs or intercepted in transit cannot be used without the client's private key. It doesn't stop leakage, but it reduces what a leaked token is worth, provided the attacker has not also stolen the key.

## Refresh token rotation, and what to do when reuse is detected

A refresh token that never changes is a long-lived credential wearing a short-lived token's reputation. Refresh token rotation means issuing a new refresh token with every refresh and invalidating the previous one. RFC 9700 (section 2.2.2) says refresh tokens issued to public clients "MUST" be either sender-constrained or rotated; confidential clients authenticate to the authorization server, which already limits replay. The part teams skip: what happens when a rotated-out refresh token gets used anyway. RFC 9700 (section 4.14.2) explains that this signals a breach, because either the attacker or the legitimate client is presenting an invalidated token. The authorization server cannot tell which party it is, so it revokes the active refresh token. Revoking everything issued under the same authorization grant, and forcing the user to reauthenticate, is the natural implementation of that, but it is our interpretation rather than explicit RFC wording.

## Where tokens actually leak in practice

Beyond the protocol-level attacks the RFC addresses, tokens can leak through mundane paths: logged in application or proxy logs, cached in browser storage longer than intended, or sent to a resource server over a redirect chain that includes a third-party domain. As general practice (not a requirement we verified in RFC 9700), audit logging configuration specifically for token values, redact them by default rather than relying on stripping them per log line, and keep access token lifetimes short so a leaked token has a narrow window of usefulness. What counts as "short" depends on your risk tolerance; there is no single figure that fits every system.

## A practical checklist

- PKCE enforced for every public client (required by RFC 9700) and enabled for confidential clients (recommended)
- No implicit grant unless token injection and leakage are demonstrably mitigated; migrate remaining usage
- Refresh tokens for public clients rotated on every use or sender-constrained, with reuse of an old token treated as a compromise signal
- Sender-constrained tokens (DPoP or mTLS) where the resource server supports it
- Access token lifetimes short enough to limit blast radius from an undetected leak
- Logging configuration audited to confirm tokens are redacted, not just assumed to be

None of this replaces basic hygiene — scoping tokens to the minimum permissions they need, and treating a leaked token with broad scope as a bigger incident than one scoped narrowly. The protocol-level protections reduce the chance of theft and what a stolen token is worth; they don't remove the need to limit what any single token can do in the first place.
