+++
title = "What Is PII, and Why Classification Is Harder Than It Sounds"
date = 2026-10-07T09:00:00Z
tags = ["privacy"]
categories = ["privacy-risk"]
summary = "PII sounds like it should be a simple list of field names to check for. In practice, whether something counts depends on context, combination with other data, and which regulation you're asking under."
description = "What actually counts as PII, why classification is genuinely harder than checking a list of field names, and a practical approach to identifying it across real systems."
author = "Tehseen Arbab"
imageAlt = "Close-up of code on a computer screen"
imageCredit = "Photo by [Markus Spiske](https://unsplash.com/photos/hvSr_CVecVI) on Unsplash"
+++

Personally identifiable information sounds like it should reduce to a simple list: name, email, phone number, check a box, done. In practice, whether something counts as PII depends on context, on combination with other data, and even on which regulation is asking the question — and treating classification as a simple field-name checklist is exactly how organizations end up missing PII that's genuinely present in their systems.

## Why there's no single universal definition

Different regulations define personal or personally identifiable information somewhat differently. GDPR's definition of "personal data" is broad and covers any information relating to an identified or identifiable natural person — which extends well beyond obvious direct identifiers to include things like IP addresses, device identifiers, and location data, since these can identify a specific person even without a name attached. U.S. frameworks (which vary by state, with no single federal standard) tend to use narrower, more enumerated definitions, often listing specific categories like Social Security numbers or financial account details. This means a piece of data might clearly count as personal data under GDPR while sitting in a grayer area under a narrower state-level definition — "is this PII" doesn't have one universal answer independent of which legal framework is actually being applied.

## Direct identifiers versus indirect identifiers

Direct identifiers are the obvious category: a name, a Social Security number, an email address, a phone number — data that identifies a specific person on its own, without needing to be combined with anything else. Indirect (or quasi-) identifiers are where classification gets genuinely harder: a birthdate, a ZIP code, a job title, a device ID. None of these identify a specific individual in isolation, but combined with a small number of other indirect identifiers, they very often do — a well-cited example is that birthdate, gender, and ZIP code together uniquely identify a large majority of the U.S. population, despite none of the three being PII in isolation by most narrow definitions.

This is the core reason field-by-field classification checklists miss real risk: a dataset can contain zero "obvious" PII fields and still be highly identifying once several fields are combined, especially when cross-referenced against other available datasets.

## Data that becomes identifying through combination, not through any single field

**Behavioral and usage data** — a sequence of pages visited, purchase history, app usage patterns — is rarely treated as PII in isolation, but a sufficiently detailed behavioral profile can uniquely identify an individual, particularly when it can be linked to a device or account identifier that persists across sessions.

**Technical identifiers** — IP addresses, device fingerprints, advertising IDs — sit in a genuinely ambiguous zone depending on the regulation and the specific use. GDPR generally treats these as personal data when they can be linked to an identifiable person, which in practice is most of the time given how tracking technology works, even though they don't look like traditional PII to someone scanning for name/email/phone fields.

**Data that's only identifying in combination with an external dataset.** A dataset containing no direct identifiers can still be de-anonymizing if it can be cross-referenced against another publicly or commercially available dataset — this has been demonstrated repeatedly in re-identification research, and it's a genuinely difficult category to account for in a simple classification process, since it depends on what other data exists outside your own systems.

## A more practical approach than a field-name checklist

**Classify by identifiability risk, not by field name alone.** Ask whether a field, alone or combined with other fields commonly present in the same dataset, could reasonably identify a specific individual — this catches indirect identifiers that a simple keyword-matching classification process would miss entirely.

**Treat technical identifiers (IP addresses, device IDs, session tokens) as PII by default**, rather than assuming they're exempt because they're not a "traditional" identifier — under most modern privacy frameworks, if it can be linked to a person, it's in scope.

**Review datasets for combination risk, not just individual field sensitivity.** A dataset with several individually-innocuous indirect identifiers deserves the same handling rigor as one with an obvious direct identifier, because the combination is often just as identifying.

**Revisit classification when data is combined or joined across systems.** Data that was appropriately classified as low-risk in one system can become high-risk once joined with another dataset that adds enough additional context to make combination-based identification possible — this is a common gap in data warehouses and analytics pipelines that join data from multiple sources without re-evaluating the combined sensitivity.

## Why getting this right matters beyond compliance

Underclassifying PII means applying weaker security controls than the data actually warrants, and it means a breach involving "non-PII" data can still result in real identification and harm to individuals, regardless of what your internal classification labeled it. Getting classification right isn't primarily about satisfying an audit checklist — it's about your security controls (encryption, access restriction, retention limits) actually matching the real sensitivity of what you're protecting, which requires the harder, combination-aware analysis rather than a simple field-name scan.
