+++
title = "JWT Security: 9 Mistakes That Can Turn Tokens Into an Attack Path"
date = 2026-10-17T09:00:00Z
tags = ["api security", "authentication"]
summary = "Most JWT vulnerabilities aren't flaws in the standard — they're implementation shortcuts that trust the token to describe its own validity. Here's what to check."
description = "9 real JWT security mistakes — algorithm confusion, the alg:none bypass, missing revocation, and more — with the fixes that actually close each one."
author = "FirewallSync Editorial"
+++

Most JWT vulnerabilities aren't flaws in the JWT standard itself. They come from implementations that trust information inside the token — like which algorithm to use for verification — that should never be trusted from an untrusted source in the first place. These nine account for the large majority of real-world JWT findings.

## 1. Trusting the algorithm specified in the token header

A JWT's header includes an `alg` field declaring which algorithm was used to sign it. If your verification code reads this field and uses it to decide how to verify the signature, an attacker can change it to whatever works in their favor. This single design mistake is behind most of the vulnerabilities below.

## 2. The `alg: none` bypass

Some JWT libraries historically honored an `alg` value of `none`, meaning no signature verification happens at all — an attacker can take a valid token, change the payload (for example, setting a role claim to admin), set the algorithm to `none`, and drop the signature entirely. Vulnerable versions of widely used libraries, including early versions of the Node.js `jsonwebtoken` package, accepted this. **Fix:** explicitly reject the `none` algorithm, and don't rely on a library's default behavior without verifying it.

## 3. RS256-to-HS256 algorithm confusion

This is the most severe common JWT attack. If your service issues tokens signed with RS256 (asymmetric — private key signs, public key verifies) but your verification code accepts both RS256 and HS256 without pinning which one to expect, an attacker can take your public key (often available, sometimes even published), sign a forged token using HS256 with that public key as the shared secret, and your verifier — trusting the header's claimed algorithm — will use the same public key to "verify" it, and it matches. This has affected multiple major JWT libraries historically. **Fix:** always explicitly specify the expected algorithm on the verify call; never let the library infer it from the token.

## 4. No expiration, or expiration that's never actually checked

A JWT without an `exp` claim, or a verification implementation that decodes the token without checking that claim, is effectively a permanent credential once issued. **Fix:** always set a reasonably short expiration, and confirm your verification library is actually enforcing it rather than assuming decode implies validation.

## 5. No revocation strategy

This is a structural property of JWTs, not a bug: a self-contained, signed token remains valid until it expires, because there's no server-side record being checked by default. If a user's access needs to be revoked immediately — account compromise, permission change, logout — a pure JWT approach can't do that on its own. **Fix:** either keep expiration short enough that this window is acceptable, or add an explicit revocation mechanism (a checked blocklist, or a version/session identifier in the token that gets invalidated server-side) for cases where immediate revocation actually matters.

## 6. Sensitive data stored in the payload

The JWT payload is Base64-encoded, not encrypted — anyone who has the token can decode and read every claim inside it, they just can't modify it without invalidating the signature. Storing anything sensitive (internal identifiers you don't want exposed, anything resembling a secret) in the payload treats "signed" as if it meant "confidential," which it doesn't. **Fix:** treat the payload as readable by the token holder and anyone they share it with; if something needs to stay confidential, it doesn't belong in the token.

## 7. Weak or hardcoded signing secrets

For HS256 tokens, the signing secret needs to be long and genuinely random — a short or guessable secret is brute-forceable offline once an attacker has a valid token to test against. Hardcoding the secret in source code is a related and common mistake that turns any code leak into a token-forging capability. **Fix:** use a cryptographically strong secret (256 bits or more), and load it from a secrets manager or environment configuration, never from source.

## 8. Not validating the issuer and audience claims

A token correctly signed by your identity provider for one application can sometimes be replayed against a different application if that second application doesn't check the `iss` (issuer) and `aud` (audience) claims — it just sees a validly signed token and accepts it. **Fix:** explicitly validate that a token was issued by the expected issuer and intended for your specific application, not just that the signature checks out.

## 9. Using JWTs for something that needed server-side session state anyway

Some applications adopt JWTs by default because they're common in tutorials, then end up rebuilding server-side session tracking on top of them to get revocation, activity monitoring, or forced logout working correctly — at which point the self-contained property that made JWTs attractive in the first place is gone, and a traditional server-side session token might have been the simpler, more appropriate choice from the start. **Fix:** choose the token approach based on whether you actually need statelessness, not because it's the default pattern in whatever framework you're using.

## The pattern underneath all nine

Every one of these traces back to trusting something that shouldn't be trusted from an untrusted source — the algorithm the attacker's token claims to use, the assumption that "signed" means "confidential," the assumption that a token issued for one purpose can't be replayed for another. Pin your algorithm explicitly, validate every claim that matters for your use case, and treat the token payload as public information the moment it leaves your server.
