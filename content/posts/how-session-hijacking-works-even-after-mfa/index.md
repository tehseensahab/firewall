+++
title = "How Session Hijacking Works Even After MFA"
date = 2026-11-21T09:00:00Z
tags = ["authentication", "incident response"]
categories = ["identity-access"]
summary = "MFA protects the login. It says nothing about the session token issued afterward — and several distinct attack techniques exist specifically to steal that token instead of touching the login at all."
description = "How session hijacking actually works after MFA succeeds — infostealer malware, XSS-based cookie theft, and AiTM relay — and why each bypasses MFA differently."
author = "FirewallSync Editorial"
+++

Multi-factor authentication secures a single event: the login. Once that login succeeds, the application issues a session token — typically a cookie — and for as long as that token remains valid, it represents the authenticated session without requiring MFA to be checked again. Several distinct attack techniques target exactly this token rather than the login itself, and each bypasses MFA in a genuinely different way, worth understanding separately rather than as one undifferentiated "session hijacking" category.

## Infostealer malware harvesting cookies directly from the browser

A significant share of real-world session hijacking doesn't involve any sophisticated network-level attack at all — it involves commodity infostealer malware, installed through a malicious download, a compromised software installer, or a phishing attachment, that simply reads session cookies directly out of the browser's local storage and exfiltrates them to the attacker. This requires no interaction with the login flow whatsoever; by the time the malware runs, the user may have been legitimately logged in for hours or days, and the malware simply steals whatever valid session tokens happen to be sitting in browser storage at that moment. This has become one of the most common initial-access vectors in real breach data, precisely because it's commoditized, cheap to deploy at scale, and doesn't require defeating any authentication mechanism directly.

## Cross-site scripting (XSS) exfiltrating session tokens

If an application has an XSS vulnerability, an attacker who can inject script into a page a victim visits can read any cookie accessible to JavaScript (any cookie not marked `HttpOnly`) and send it to an attacker-controlled endpoint. This is an application vulnerability being used specifically to defeat session security — the MFA that protected the original login is irrelevant, because the attacker never needs to log in at all; they simply capture and reuse a session token that a legitimate, already-authenticated user's browser handed over involuntarily through the vulnerable page.

## Adversary-in-the-middle (AiTM) phishing relay

Covered in more depth elsewhere: a phishing proxy sits between the victim and the real login page, relaying the entire authentication flow — including MFA — in real time, and captures the session token issued at the end of that legitimate flow before the victim notices anything wrong. This is distinct from the two techniques above because it does interact with the login and MFA process directly, but it defeats MFA's protection by capturing what comes immediately after MFA succeeds, rather than by defeating MFA itself.

## Network-level interception on unencrypted or improperly secured connections

Where session cookies are transmitted without TLS, or where TLS is improperly implemented (accepting invalid certificates, for example), an attacker positioned on the network path — a shared public Wi-Fi network, a compromised network device — can capture session tokens in transit. This is a less common vector in most modern web applications given widespread HTTPS adoption, but it remains a real risk for legacy internal applications or misconfigured deployments that don't enforce TLS strictly.

## Why each technique requires a different specific defense

**Against infostealer-based theft:** endpoint protection and application controls that reduce malware installation in the first place, combined with binding sessions to device characteristics so a token copied to a different machine is rejected or challenged.

**Against XSS-based theft:** marking session cookies `HttpOnly` (inaccessible to JavaScript entirely) removes this vector specifically, combined with standard XSS prevention (output encoding, Content Security Policy) addressing the underlying vulnerability.

**Against AiTM relay:** phishing-resistant authentication (passkeys/FIDO2) removes the initial credential-and-MFA capture step this technique depends on, since the origin-bound cryptographic challenge can't be relayed through a proxy on a different domain.

**Against network interception:** strict TLS enforcement, HSTS, and marking cookies `Secure` so they're never transmitted over an unencrypted connection.

No single control addresses all four vectors, which is why a session-security posture built around only one of these defenses (commonly, just moving to phishing-resistant MFA, which specifically addresses AiTM but does nothing about infostealer malware or XSS) leaves real gaps against the other techniques.

## The common thread: shorten the token's useful window regardless of theft method

Across all four vectors, one control helps regardless of how the token was obtained: shorter session and token lifetimes limit how long a stolen token remains useful, forcing more frequent re-authentication that gives a narrower window for any stolen token to be exploited before it naturally expires. This doesn't prevent theft through any of the four mechanisms, but it bounds the consequence of all of them simultaneously, which is a meaningfully different and more resilient property than a defense that only addresses one specific theft technique.

## A practical takeaway

Treating "session hijacking" as one problem with one fix — commonly, assuming that adopting phishing-resistant MFA solves it — misses that MFA-relay is only one of several distinct ways an attacker can end up holding a valid session token. A resilient posture needs to address the token itself (short lifetimes, `HttpOnly` and `Secure` flags, device binding where feasible) as a security boundary in its own right, separate from and in addition to hardening the authentication event that precedes it.
