+++
title = "What Is Token Theft and Why MFA Doesn't Always Stop It?"
date = 2026-10-08T09:00:00Z
tags = ["authentication", "incident response"]
summary = "MFA verifies who's logging in, not who's still using the session afterward. Token theft attacks steal what MFA leaves behind: the authenticated session itself."
description = "Token theft explained: how adversary-in-the-middle attacks steal session cookies after MFA succeeds, and what detection actually needs to catch it."
author = "FirewallSync Editorial"
+++

Multi-factor authentication verifies identity at the moment of login. It says nothing about what happens to the session afterward — and that gap is exactly what token theft attacks exploit. A user can enter their password, complete their MFA prompt correctly, and still hand an attacker full account access, because the thing worth stealing isn't the password or the MFA code anymore. It's the session token issued after both succeed.

## How token theft actually works

The dominant technique is adversary-in-the-middle (AiTM) phishing, using widely available open-source tooling such as Evilginx. The attacker doesn't build a fake login page — they proxy the real one. The victim lands on a domain that looks wrong on close inspection, but the page itself is the actual login flow, relayed through the attacker's server in real time.

The victim enters their real username and password, and completes MFA exactly as they normally would — push approval, OTP, whatever the org uses. The legitimate service verifies everything correctly and issues a session cookie or token, because as far as the identity provider is concerned, a real authentication just happened. The attacker's proxy captures that session token in transit before relaying the successful login back to the victim, who notices nothing wrong.

From that point, the attacker doesn't need the password or MFA again. They load the stolen session token directly into their own browser and are treated as an already-authenticated user — because they are one, technically, just not the one the identity provider thinks.

## Why traditional MFA doesn't stop this

MFA that relies on a human relaying a value — typing an OTP, tapping "approve" on a push notification — is phishable by design, because nothing prevents that value from being captured and relayed through a proxy. The code or approval doesn't know which site it's being used on. This is a structural gap, not an implementation bug in any particular MFA product, which is why the technique works across Microsoft 365, Google Workspace, and most SSO platforms regardless of which MFA method they use.

Phishing-resistant authentication (FIDO2/WebAuthn passkeys and security keys) closes this specific gap because the cryptographic challenge is bound to the actual domain — an AiTM proxy sitting on a different origin can't get a valid signed response out of it, even with a perfect visual clone of the login page. But phishing-resistant login doesn't retroactively protect a session token that's already been issued under older MFA methods, which is why detection matters as much as prevention.

## What detection actually needs to catch

Standard login monitoring looks for failed authentication attempts and unusual login locations. Token theft produces neither — the original login succeeded legitimately, and the attacker's subsequent access uses a valid token, not a new login attempt. What it does produce, if you're watching for it:

- **The same session token used from two meaningfully different locations or devices close together in time** — not a new login, but continued use of an existing session from an inconsistent source
- **Impossible travel on session activity, not just login events** — a session that was active in one region and is suddenly active somewhere geographically implausible minutes later
- **Anomalous behavior after a legitimate-looking login** — mailbox rule changes, unusual OAuth app consent grants, or access patterns inconsistent with the user's normal activity, occurring shortly after a routine sign-in

## What actually reduces the risk

- **Shorten session and token lifetimes** so a stolen token has a narrower window of usefulness before it expires and forces re-authentication
- **Bind sessions to device and network signals** where your identity provider supports it, so a token replayed from a different device or context gets challenged again rather than accepted silently
- **Move toward phishing-resistant authentication** for the accounts where a compromised session would matter most, since it removes the initial credential-and-code capture step the whole attack depends on
- **Monitor session and token reuse patterns specifically**, not just login failures — this is the signal that actually exists in this attack, and most detection stacks aren't tuned to look for it

Token theft is a reminder that "did MFA succeed" and "is this session legitimate right now" are different questions. Most security programs have built strong controls around the first and comparatively little around the second, which is exactly the gap this attack class is built to walk through.
