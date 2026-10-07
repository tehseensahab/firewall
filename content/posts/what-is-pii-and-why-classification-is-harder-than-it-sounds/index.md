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

Different regulations define personal or personally identifiable information somewhat differently. The EU General Data Protection Regulation (GDPR) defines "personal data" in [Article 4(1)](https://gdpr-info.eu/art-4-gdpr/) as any information relating to an identified or identifiable natural person, and names identifiers such as location data and "an online identifier". [Recital 30](https://gdpr-info.eu/recitals/no-30/) gives IP addresses and cookie identifiers as examples of online identifiers that may leave traces that, combined with other information, can identify a person. So the definition reaches well beyond obvious direct identifiers. U.S. frameworks (which vary by state, with no single federal standard) tend to use narrower, more enumerated definitions, often listing specific categories like Social Security numbers or financial account details. This means a piece of data might clearly count as personal data under GDPR while sitting in a grayer area under a narrower state-level definition — "is this PII" doesn't have one universal answer independent of which legal framework is actually being applied.

## Direct identifiers versus indirect identifiers

Direct identifiers are the obvious category: a name, a Social Security number, an email address, a phone number — data that identifies a specific person on its own, without needing to be combined with anything else. Indirect (or quasi-) identifiers are where classification gets genuinely harder: a birthdate, a ZIP code, a job title, a device ID. None of these identify a specific individual in isolation, but combined with a small number of other indirect identifiers, they very often do — a well-known example is Latanya Sweeney's analysis of 1990 U.S. Census data, which estimated that [87% of the U.S. population](https://dataprivacylab.org/projects/identifiability/paper1.pdf) was likely unique on the combination of 5-digit ZIP code, gender and full date of birth. A later analysis of 2000 Census data by Philippe Golle, [Revisiting the Uniqueness of Simple Demographics in the US Population](https://crypto.stanford.edu/~pgolle/papers/census.html), put the figure at 63%. The exact share depends on the census year and method, but in both studies a majority of people were unique on those three fields, none of which is a direct identifier on its own.

This is the core reason field-by-field classification checklists miss real risk: a dataset can contain zero "obvious" PII fields and still be highly identifying once several fields are combined, especially when cross-referenced against other available datasets.

## Data that becomes identifying through combination, not through any single field

**Behavioral and usage data** — a sequence of pages visited, purchase history, app usage patterns — is rarely treated as PII in isolation, but a sufficiently detailed behavioral profile can uniquely identify an individual, particularly when it can be linked to a device or account identifier that persists across sessions.

**Technical identifiers** — IP addresses, device fingerprints, advertising IDs — sit in a genuinely ambiguous zone depending on the regulation and the specific use. GDPR treats these as personal data when they relate to an identifiable person (see Recital 30 above); whether a specific IP address qualifies depends on whether the organization or a third party has legal means to link it to a person, and it often can. These identifiers matter even though they don't look like traditional PII to someone scanning for name/email/phone fields.

**Data that's only identifying in combination with an external dataset.** A dataset containing no direct identifiers can still be de-anonymizing if it can be cross-referenced against another publicly or commercially available dataset — re-identification research, including the Sweeney and Golle studies above, shows this can happen, and it's a genuinely difficult category to account for in a simple classification process, since it depends on what other data exists outside your own systems.

## A more practical approach than a field-name checklist

**Classify by identifiability risk, not by field name alone.** Ask whether a field, alone or combined with other fields commonly present in the same dataset, could reasonably identify a specific individual — this catches indirect identifiers that a simple keyword-matching classification process would miss entirely.

**Treat technical identifiers (IP addresses, device IDs, advertising IDs) as personal data by default**, rather than assuming they're exempt because they're not a "traditional" identifier. This is a conservative engineering policy, not a legal conclusion: under GDPR, data that can be linked to a person is in scope, while U.S. state laws differ in what they list, so check the laws that apply to you.

**Review datasets for combination risk, not just individual field sensitivity.** A dataset with several individually-innocuous indirect identifiers deserves the same handling rigor as one with an obvious direct identifier, because the combination is often just as identifying.

**Revisit classification when data is combined or joined across systems.** Data that was appropriately classified as low-risk in one system can become high-risk once joined with another dataset that adds enough additional context to make combination-based identification possible — this is a common gap in data warehouses and analytics pipelines that join data from multiple sources without re-evaluating the combined sensitivity.

## Why getting this right matters beyond compliance

Underclassifying PII means applying weaker security controls than the data actually warrants, and it means a breach involving "non-PII" data can still result in real identification and harm to individuals, regardless of what your internal classification labeled it. Getting classification right isn't primarily about satisfying an audit checklist — it's about your security controls (encryption, access restriction, retention limits) actually matching the real sensitivity of what you're protecting, which requires the harder, combination-aware analysis rather than a simple field-name scan.
