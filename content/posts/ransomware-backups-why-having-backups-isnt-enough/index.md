+++
title = "Ransomware Backups: Why Having Backups Isn't Enough"
date = 2026-11-27T09:00:00Z
tags = ["incident response", "process"]
categories = ["security-operations"]
summary = "Modern ransomware operators specifically target backup infrastructure before encrypting production data, precisely because they know backups are the thing standing between their ransom demand and a straightforward recovery."
description = "Why simply having backups doesn't protect against modern ransomware — attackers specifically target backup infrastructure first, which is what the 3-2-1-1-0 rule exists to defeat."
author = "FirewallSync Editorial"
+++

"We have backups" used to be a reasonably confident answer to ransomware risk. It no longer is, because modern ransomware operators have adapted specifically around this defense — deliberately targeting and destroying or encrypting backup infrastructure before encrypting production systems, precisely because they know backups are the thing standing between their ransom demand and an organization simply restoring and moving on without paying.

## Why attackers go after backups first

A ransomware operation that only encrypts production systems, leaving backups untouched, gives the victim a straightforward recovery path that removes most of the leverage behind a ransom demand. Attackers who have studied this dynamic — and ransomware-as-a-service operations increasingly do reconnaissance specifically to identify and target backup systems as an early step — will locate backup servers, backup catalogs, and any network-accessible backup storage during their lateral movement phase, and deliberately compromise, delete, or encrypt those before triggering the main encryption event on production data. If your backups are reachable from the same network and same credentials as your production environment, they're reachable by the same attacker who's already inside that environment.

## Why "we have backups" isn't the same as "we can recover"

Even when backups survive an attack, several failure modes commonly prevent them from actually being usable for recovery:

**Backups that were never tested for restoration.** A backup job completing successfully confirms data was written somewhere — it doesn't confirm that data can actually be restored into a working system under real conditions. Corruption, incomplete backups, and configuration drift between the backed-up state and current infrastructure all can silently break a restore process that nobody discovers until the moment they actually need it to work.

**Backups that were already compromised before the ransomware event was detected.** If an attacker has dwell time in an environment before triggering visible encryption — which is common, since ransomware deployment is often the final stage of a longer intrusion — backups taken during that dwell time may already contain the same malware or backdoor the attacker used to gain access in the first place, meaning a restore from those backups can reintroduce the compromise rather than cleanly recovering from it.

**Backups reachable from the compromised network with the compromised credentials.** As covered above, if backup infrastructure isn't meaningfully isolated from the production environment, an attacker with sufficient access to the production environment has a direct path to the backups too — negating the protection backups are supposed to provide.

## The 3-2-1-1-0 framework as the current standard

The traditional 3-2-1 backup rule (three copies of data, on two different media types, with one copy offsite) predates modern ransomware's specific targeting of backup infrastructure, and has been extended industry-wide to 3-2-1-1-0 specifically to address it:

- **3 copies** of data — production plus at least two backups, so no single failure or compromise leaves only one copy
- **2 different media types** — so a single storage platform's compromise or failure doesn't take down every copy simultaneously
- **1 copy offsite** — geographically separated, protecting against site-level events
- **1 copy immutable or air-gapped** — this is the addition specifically targeting the ransomware threat model: a copy that cannot be modified, encrypted, or deleted, even by someone holding valid administrative credentials, for a defined retention period, or a copy fully disconnected from the network entirely
- **0 errors** — verified through regular, automated restore testing, since an unverified backup is a hypothesis about recoverability, not a confirmed one

The immutable/air-gapped copy is the element that specifically defeats the "attacker targets backups first" pattern: even an attacker with full administrative access to the rest of the environment cannot modify or delete a properly configured immutable backup within its retention window, because that's precisely the property immutability is designed to guarantee, independent of what credentials are compromised elsewhere.

## What immutability actually means in practice

Immutable backup storage — implemented through WORM (write-once-read-many) configurations on cloud object storage, or through dedicated backup appliances with hardware-enforced immutability — makes a stored backup unmodifiable and undeletable for a set retention period, regardless of what account or credential attempts to change it. This is a meaningfully different guarantee than access-control-based protection (restricting who can delete backups through permissions) because access controls can be bypassed by an attacker who compromises a sufficiently privileged account, while true immutability holds even against that scenario, since the protection is enforced at the storage layer itself rather than through a permission check that a compromised credential could pass.

## Why this needs to be a deliberate architectural decision, not a checkbox

Simply enabling a vendor's "immutability" feature without verifying how it's actually configured — the retention period, whether it covers the specific backup jobs that matter, whether the air-gapped copy is genuinely disconnected on a meaningful schedule rather than nominally offline while remaining reachable — can leave a gap between what's assumed to be protected and what actually is. This is worth validating explicitly, including through the kind of adversarial testing covered in a dedicated look at actually testing backup resilience against ransomware, rather than trusting a configuration was implemented correctly based on the feature simply being enabled.

## The practical shift required

Moving from "we have backups" to "we can actually recover from a ransomware attack that specifically targeted our backups" requires treating backup infrastructure as a security-critical system in its own right — network-isolated from production, protected by immutability rather than access control alone, and regularly tested for actual restoration — not as a passive, background IT function that only needs attention when something already went wrong.
