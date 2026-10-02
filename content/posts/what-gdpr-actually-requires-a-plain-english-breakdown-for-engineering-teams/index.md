+++
title = "What GDPR Actually Requires: A Plain-English Breakdown for Engineering Teams"
date = 2026-10-05T09:00:00Z
tags = ["privacy", "compliance"]
categories = ["privacy-risk"]
summary = "GDPR compliance often gets treated as a legal problem handed to legal teams. Several of its core requirements are actually engineering decisions, and they're easier to satisfy if you know which ones fall on your desk."
description = "What GDPR actually requires in practical terms for engineering teams: data minimization, the 72-hour breach rule, DPIAs, and what's genuinely an engineering decision versus a legal one."
author = "Tehseen Arbab"
+++

GDPR compliance often gets handed entirely to a legal or compliance team, with engineering treated as an implementation detail once the requirements are decided elsewhere. Several of GDPR's core requirements are actually engineering decisions at their core — not because engineers need to become lawyers, but because the requirement itself is about how systems are built, not just what policies exist on paper.

## Data minimization: collect only what you actually need

This is a design principle before it's a compliance requirement: personal data should be limited to what's actually necessary for the stated purpose of processing it. In practice, this means an engineering decision at the point a new field, form, or data collection is designed — does this feature genuinely need to capture this piece of personal data, or is it being collected because it might be useful someday. The compliance risk isn't abstract: every field of personal data collected is also a field that has to be secured, that expands what a breach would expose, and that eventually needs a documented retention and deletion policy. Minimization isn't just a legal nicety — it directly reduces your actual security exposure.

## The 72-hour breach notification requirement, and what it means for detection capability

Article 33 requires notifying the relevant supervisory authority within 72 hours of becoming aware of a personal data breach, unless the breach is unlikely to result in risk to individuals — and Article 34 adds a separate requirement to notify affected individuals directly when the risk is high. The clock starts from awareness that personal data may have been affected, not from when a full investigation concludes, and GDPR explicitly permits phased notification — an initial report with what's known, followed by updates as more detail emerges.

The engineering implication is concrete: 72 hours is not much time if your detection capability is slow. If it typically takes days or weeks to even notice that something unusual happened in a system handling personal data, the 72-hour clock has already been running the entire time you didn't know — meaning breach detection speed is itself a GDPR-relevant engineering capability, not solely a compliance policy question.

## Data Protection Impact Assessments (DPIAs) for high-risk processing

A DPIA is a structured assessment of privacy risk, required for processing activities likely to result in high risk to individuals — large-scale processing of sensitive data, systematic monitoring, or use of new technologies being common triggers. For engineering teams, this means: before building a feature that involves significant new personal data processing (a new tracking capability, a new category of sensitive data, an automated decision-making system), a DPIA should happen at the design stage, not retroactively after the feature ships — building the assessment into your feature planning process for anything touching personal data meaningfully is far cheaper than retrofitting privacy controls after launch.

## Data subject rights: access, rectification, erasure, portability

Individuals have specific rights under GDPR, including the right to access their data, correct inaccuracies, request deletion ("right to be forgotten"), and receive their data in a portable format. Each of these has a direct engineering dependency: can your systems actually locate all instances of a specific individual's data across every database, log, and backup where it might exist? Can a deletion request actually be fulfilled completely, including in backups and any downstream systems that received a copy of that data? Organizations that haven't designed for this from the start often discover, when a real request comes in, that personal data is scattered across systems with no clean way to locate or remove it comprehensively — this is a data architecture problem revealed by a legal requirement, not a legal problem in isolation.

## Encryption and security measures under Article 32

Article 32 requires "appropriate technical and organizational measures" to secure personal data, without prescribing exact technical requirements — but enforcement actions have specifically cited gaps in areas like MFA deployment, vulnerability scanning, and patch management as failures under this article. This is deliberately non-prescriptive, which means the practical standard is closer to "what would a reasonable security program for data of this sensitivity look like" than a fixed checklist — the general security fundamentals covered elsewhere on this site (access control, encryption, patch management, incident response) are, in a very direct sense, also GDPR compliance work when the systems involved process personal data.

## What's genuinely a legal decision versus an engineering one

Determining the lawful basis for processing, drafting privacy notices, and managing consent mechanisms are appropriately legal and product decisions. But the actual implementation — enforcing data minimization in what gets collected, building systems capable of fulfilling access and deletion requests, achieving detection speed fast enough to meet breach notification timelines, and applying genuinely appropriate security measures — sits with engineering, and treating these purely as "legal's problem" tends to produce compliance gaps that only surface during an actual incident or audit, when they're most expensive to fix.

## A practical starting point

If your organization processes any personal data of EU residents, the highest-leverage engineering actions are: auditing what personal data you actually collect against what you genuinely need, confirming you can locate and delete a specific individual's data across your full system landscape (including backups), and honestly assessing whether your detection capability could actually identify and characterize a breach within a 72-hour window. These three, done well, address a meaningful share of GDPR's practical engineering surface.
