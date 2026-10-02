+++
title = "Encryption at Rest vs Encryption in Transit: What Each Actually Protects Against"
date = 2026-10-04T09:00:00Z
tags = ["fundamentals", "privacy"]
categories = ["fundamentals"]
summary = "Both terms get used as a single checkbox on a compliance form, but they protect against completely different threats — and having one without the other leaves a specific, predictable gap."
description = "Encryption at rest vs encryption in transit: what each actually protects against, why compliance checklists treating them as one item miss a real gap, and where the boundary between them sits."
author = "Tehseen Arbab"
imageAlt = "Internal hard disk drive"
imageCredit = "Photo by [Vincent Botta](https://unsplash.com/photos/wYD_wfifJVs) on Unsplash"
+++

"Encryption at rest and in transit" gets treated as a single line item on compliance checklists and security questionnaires, as if it's one control rather than two separate ones addressing two distinct threats. Having one without the other is common, and it leaves a specific, predictable gap that's worth understanding rather than assuming the checkbox covers everything.

## Encryption in transit: protecting data while it moves

Encryption in transit protects data as it travels across a network — between a browser and a server, between two internal services, between a client application and a database. TLS is the dominant mechanism here, and its threat model is specifically about interception: preventing someone positioned on the network path (a compromised router, a malicious Wi-Fi access point, an attacker performing a man-in-the-middle attempt) from reading or altering data as it moves between two endpoints.

What it explicitly doesn't protect: data sitting at either endpoint once it arrives. TLS secures the pipe, not what's inside the buildings at either end of it — once data reaches its destination and is decrypted for processing or storage, encryption in transit's job is done, for better or worse.

## Encryption at rest: protecting data while it's stored

Encryption at rest protects data while it's stored on disk — a database, a file system, a backup, an object storage bucket. Its threat model is different: it protects against someone gaining direct access to the storage medium itself without going through the application's normal access controls — a stolen laptop, a compromised backup, a misconfigured storage bucket exposed publicly, or physical theft of a drive. If storage is encrypted at rest and an attacker only obtains the raw storage medium without the corresponding decryption key, the data itself remains protected even though they have physical or direct access to it.

What it explicitly doesn't protect: data that's already been decrypted for legitimate use. An application with proper access to a database will read data in its decrypted, usable form as part of normal operation — encryption at rest doesn't prevent an authenticated user or process with legitimate access from reading, it only protects against someone bypassing that access layer to read the raw stored bytes directly.

## The gap that shows up when only one is implemented

**Encryption in transit without encryption at rest** means data is protected while moving across the network but sits as plaintext on disk once it arrives — meaning a stolen backup, a compromised storage bucket, or physical access to the storage medium exposes everything, even though every network connection to that system was properly encrypted the entire time.

**Encryption at rest without encryption in transit** means data is protected on disk, but travels as plaintext across the network to reach an application or a user — meaning anyone positioned on that network path can intercept and read it in transit, even though it was perfectly protected the moment before and after that transmission.

Neither gap is hypothetical. Both configurations show up regularly in real environments, usually because one was implemented as part of a specific project (setting up HTTPS, for example) without a corresponding review of whether the data's storage layer received equivalent protection, or vice versa.

## Where the boundary actually sits, and why it matters for incident response

Understanding exactly where encryption in transit's protection ends and encryption at rest's protection begins matters directly for incident response: if an attacker intercepts network traffic, the relevant question is whether TLS was properly configured and not downgraded. If an attacker gains access to a storage snapshot or backup, the relevant question is whether at-rest encryption was enabled and whether the encryption keys were themselves adequately protected — these are different investigations, with different evidence to check, and conflating them as "was data encrypted" without specifying which layer leads to an incomplete assessment.

## Encryption in use: the gap neither one covers

Worth naming, even briefly: data being actively processed in memory — while an application is computing on it — is generally not protected by either encryption at rest or in transit, since the application needs the plaintext to actually operate on the data. This is what "encryption in use" or confidential computing technologies specifically address, though they remain less universally deployed than the other two. For most organizations, this represents an accepted gap rather than a solved problem, and it's worth being aware of as a limitation rather than assuming "encrypted at rest and in transit" means data is protected at every stage of its lifecycle.

## A practical checklist

- Confirm TLS is properly configured (not just present, but not downgradable to weaker or deprecated versions) for every network path handling sensitive data
- Confirm at-rest encryption is enabled for every storage layer — primary databases, backups, and object storage alike, since backups are a commonly missed layer
- Verify encryption keys themselves are properly managed and access-controlled, since at-rest encryption with poorly protected keys provides much weaker protection than it appears to
- Treat "encrypted at rest and in transit" as two separate items to verify independently, not one checkbox that covers both by association
