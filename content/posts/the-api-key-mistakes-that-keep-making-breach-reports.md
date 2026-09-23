+++
title = "The API Key Mistakes That Keep Making Breach Reports"
date = 2026-08-24
tags = ["secrets management", "appsec"]
summary = "Secrets scanning tools have gotten good. The breaches keep happening anyway, mostly for three preventable reasons."
+++

Secrets scanning is mature technology at this point — most CI pipelines can catch a hardcoded key before it merges. Yet leaked API keys remain one of the most common root causes in breach disclosures. The gap isn't tooling. It's three specific habits that scanners don't catch.

## Keys with no expiry

A scanner can tell you a key is exposed in a commit. It can't tell you that the key was never going to expire anyway, so rotating it after the leak doesn't actually close the window — the same key pattern gets reused in the next service, with the same no-expiry default. Default every new key to expire, and make the renewal request the normal path, not the exception.

## Shared keys across environments

Using the same API key for staging and production is still common because it's convenient — one less secret to manage. It also means a staging environment with weaker access controls becomes a direct path to production data. Environment-scoped keys should be a hard requirement in your provisioning process, not a "best practice" that gets skipped under deadline pressure.

## Keys stored in places scanners don't look

Secrets scanners are tuned for source code. They generally don't scan Slack messages, shared docs, or ticket comments — all places engineers paste a key "just this once" while debugging. That key often outlives the debugging session by months. If your threat model assumes secrets only live in git, you're missing the majority of where they actually leak from in practice.

## Where to focus first

1. Audit for non-expiring keys before adding more scanning tools
2. Split shared staging/production keys this quarter, not next
3. Treat chat and docs as a secrets surface, with periodic manual sweeps

Scanning your repos is necessary. It was never sufficient.
