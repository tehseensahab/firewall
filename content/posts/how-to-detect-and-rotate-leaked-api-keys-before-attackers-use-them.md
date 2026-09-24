+++
title = "How to Detect and Rotate Leaked API Keys Before Attackers Use Them"
date = 2026-10-05T09:00:00Z
tags = ["api security", "secrets management"]
summary = "A leaked API key isn't automatically compromised, but you often can't prove it wasn't used. Here's how to find exposure fast and rotate without breaking production."
description = "How to detect leaked API keys across GitHub, logs, and client bundles, and rotate them safely without breaking the services that depend on them."
author = "FirewallSync Editorial"
+++

An API key committed to a public repository is not automatically compromised. The problem is that you usually cannot prove who copied it, when, or what they did with it. Scanners and bots index public GitHub commits within minutes of a push, so the window between "leaked" and "found by someone else" is often shorter than the window between "leaked" and "found by you."

## How keys actually get exposed

Most leaks don't come from someone deliberately posting a credential. They come from ordinary developer workflow:

- A `.env` file committed because `.gitignore` was added after the first commit, not before it
- A key hardcoded during local testing and never removed before the branch was pushed
- A key embedded in client-side JavaScript because it was easier than building a backend proxy
- A key pasted into a CI log for debugging and left there, readable by anyone with log access
- A key shared in a support ticket, Slack thread, or screen-recorded demo

Client-side exposure deserves special attention because it isn't a mistake in the traditional sense — a key embedded in a frontend bundle is, by definition, sent to every visitor's browser. If a key must be used from the browser, it needs to be scoped so that exposure is expected and harmless, not treated as a leak when it inevitably surfaces.

## Finding out you're exposed

Don't wait for a scanner to tell you. Check these sources directly:

- **GitHub secret scanning** — enabled by default on public repos for known token formats; push protection can block the commit before it lands if you turn it on
- **Your own git history** — a key removed from the current file is still in every prior commit unless you've rewritten history; `git log -p` and grep for the key pattern across the full history, not just HEAD
- **CI/CD logs** — check whether your pipeline prints environment variables or command arguments that include secrets, especially in debug or verbose modes
- **Client-side bundles** — search your built JS/CSS output for the key string directly; source maps can also re-expose something that was minified out of the readable bundle

## Rotating without breaking production

Rotation fails when the old key is deactivated before every service using it has the new one. The order matters:

1. **Issue a new key** without deactivating the old one yet — most providers let both be valid simultaneously
2. **Deploy the new key** to every service, script, and integration that uses it, including ones that aren't obviously "yours" — third-party tools, scheduled jobs, and one-off scripts are the most common things forgotten
3. **Verify old-key usage has dropped to zero** using the provider's access logs or usage dashboard before deactivating anything; if usage doesn't drop, something is still using the old key and you haven't found it yet
4. **Deactivate the old key**, not just rotate the value in your own config — a key still valid on the provider's side is still usable by whoever leaked it, regardless of what your app currently points at

## Common mistakes

The most common rotation failure isn't forgetting to rotate — it's rotating the key in your secrets manager without confirming every consumer actually redeployed with the new value. A key that's "rotated" in Vault but still cached in a running process's memory, or in a service that reads secrets only at startup, means the old key is still functionally live until that service restarts.

The second most common mistake is treating rotation as the end of the incident. If the key had broad permissions, rotation stops future misuse but does nothing about anything already done with it during the exposure window — check the provider's audit log for activity on that key specifically, not just your own application logs.

## Detection and verification checklist

- Search full git history, not just current files, for the key pattern
- Check CI/CD logs for accidental secret printing
- Search built frontend bundles and source maps
- Confirm the provider's own access log shows old-key usage before deactivating it
- Review what the leaked key had permission to do, and audit that specific window of activity
- Scope any client-exposed keys narrowly enough that exposure is expected, not catastrophic

## Preventing the next one

Push protection (blocking commits containing recognizable secret patterns before they land) closes the most common exposure path at the point of failure, rather than relying on someone noticing afterward. Pair it with short-lived, scoped credentials where the provider supports them — a key with a narrow permission set and a defined expiry limits the damage of the next leak you don't catch immediately, which, at some point, you won't.
