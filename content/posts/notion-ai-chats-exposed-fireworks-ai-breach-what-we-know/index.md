+++
title = "Notion AI Chats Exposed in Fireworks AI Breach: What We Know"
date = 2026-11-13T04:40:00Z
tags = ["hacking news", "notion", "fireworks ai", "data breach", "llmjacking", "ai vendors", "zero data retention", "third-party risk"]
categories = ["ai-security"]
summary = "Notion says chat transcripts from fewer than 1% of workspaces were exposed after attackers reached its inference vendor Fireworks AI. What Notion and Fireworks have confirmed, the October timeline, and what to check if your product sends prompts to an AI vendor."
description = "Notion says Notion AI chat transcripts from under 1% of workspaces were exposed in a Fireworks AI breach. What is confirmed, the timeline, and what to check."
author = "Craig Leslie"
imageAlt = "Macro close-up inside a hard drive: an orange flexible circuit with copper contacts curving around the silver spindle hub, next to a teal circuit board"
imageCredit = "Photo by [Andrew Dawes](https://unsplash.com/photos/a-close-up-of-the-inside-of-a-hard-drive-FpJ-CEPdofc) on Unsplash"
takeaways = [
  "Notion says a security incident at its AI vendor Fireworks AI affected fewer than 1% of Notion workspaces and exposed Notion AI chat transcripts: model inputs and outputs written in Notion AI chats.",
  "Notion says its zero data retention commitment did not cover data it had to store for features such as chat history and Insights, and that its investigation found data was retained at the Fireworks endpoints it used.",
  "Fireworks says a third-party cloud provider hosting its R&D machines had an incident on October 23, and the intruder ran an unauthorized workload on October 24. It links the activity to a financially motivated LLMJacking group it does not name.",
  "Notion says it disconnected from Fireworks as of November 3, deleted data held there, disabled Insights and told customers to treat the data as exposed and rotate any credentials pasted into Notion AI.",
  "For engineering teams the lesson is per-feature retention: ask each AI vendor which endpoints store content (batch jobs, datasets, evaluations), and rotate leaked secrets at the issuer, not just in the vendor's secret store."
]

[[faq]]
q = "What data did the Fireworks AI breach expose at Notion?"
a = "Notion says Notion AI chat transcripts, meaning any model input or output written to a Notion AI chat, were affected for fewer than 1% of workspaces. It says AI Meeting Notes audio, transcripts and summaries were not affected unless used as input in a Notion AI chat, and that record, workspace, user and thread IDs it added for analysis were not exposed."

[[faq]]
q = "How did attackers get into Fireworks AI?"
a = "Fireworks says a third-party cloud provider that hosted its R&D machines had a security incident on October 23, 2026, and that the unauthorized party used that access to reach Fireworks development machines and run an unauthorized workload on October 24. Fireworks has not said how the provider was compromised. A separate earlier incident, identified on October 6, involved unauthorized use of internal Fireworks credentials."

[[faq]]
q = "What should Notion customers do?"
a = "Notion says workspace owners who were contacted can open Security incident review from the help menu in a desktop browser to download affected-member and, with a verified domain, affected-content CSVs. It recommends treating the data as exposed and immediately rotating any passwords, API keys or other credentials pasted into Notion AI. Notion says customers it has not contacted need take no action now."

[[faq]]
q = "Did Notion's zero data retention promise fail?"
a = "Notion says its zero data retention commitment did not cover data it had to store to provide features such as chat history and Insights, and that during the investigation it learned data was retained from the Fireworks endpoints it used. Neither company has publicly said which Fireworks feature stored the transcripts."
+++

**What happened.** Notion says a security incident at Fireworks AI, a vendor it used to run open-weight models and classification jobs, exposed Notion AI chat transcripts from fewer than 1% of Notion workspaces. Fireworks says the intruder came in through a third-party cloud provider that hosted its R&D machines, and Notion says it has cut its systems off from Fireworks and is notifying affected customers. SecurityWeek and VentureBeat reported the disclosure on November 11 and 12, 2026.

This post sticks to what Notion and Fireworks have published, attributes everything else, and ends with the checks worth running if your own product sends prompts or customer content to an AI inference vendor.

## What Notion has confirmed

From Notion's help-center notice, [Notice about the Fireworks AI incident that may impact some Notion workspaces](https://notion.com/help/security-incident-involving-a-third-party-ai-vendor) (the page carries no publish date; we read it on November 13, 2026):

- **Scope.** The incident affected "fewer than 1% of Notion workspaces."
- **What Notion used Fireworks for.** Three things: Insights (classification jobs that help customers understand their own AI usage), general inference for serving open-weight models inside Notion, and LEAP, an early-access program whose volunteers' data Notion used to experiment with training task-specific models on Fireworks.
- **What data.** Chat transcripts: any model input or output written to a Notion AI chat.
- **What was not affected.** AI Meeting Notes audio, transcripts and summaries, unless they were used as input in a Notion AI chat. Notion says metadata it added for analysis (record, workspace, user and thread IDs, dates) was not exposed, and that for most workspaces it added no metadata tying a transcript to a specific workspace, user or company.
- **Retention.** Notion says its zero data retention commitment did not cover data it had to store to provide features such as chat history and Insights, and adds: "Unfortunately, during our investigation we learned that data was retained from the Fireworks endpoints that we used."
- **What Notion did.** As of November 3 it disconnected its systems from Fireworks, deleted all data in the Fireworks system, stopped sending data and traffic there, halted training runs, disabled Insights during the investigation, stopped serving open-weight models through Fireworks, contacted affected customers and began auditing critical vendors for zero data retention compliance.

## What Fireworks has confirmed

Fireworks published an [October 2026 security incident update](https://fireworks.ai/security/bulletins/october-2026-security-incident-update), last updated November 9, 2026, on top of its [original October bulletin](https://fireworks.ai/security/bulletins/october-2026-security-incident).

- **First incident.** "On October 6, Fireworks identified a security incident involving unauthorized use of internal Fireworks credentials." An unauthorized party accessed environment variables used in evaluation jobs in a limited number of customer accounts, and Fireworks believes API keys and tokens stored as secrets in some of those accounts were captured. Fireworks has not said how the credentials were obtained.
- **Second path.** "A third-party cloud provider that hosted Fireworks R&D machines experienced a security incident on October 23." On October 24 the unauthorized party used that access to reach Fireworks development machines and ran an unauthorized workload that affected customer data; Fireworks says it detected this the same day. It does not name the provider or say how the provider was compromised.
- **Data accessed.** Resource metadata (identifiers, display names, descriptions, creation times); billing information (addresses, invoice and payment history, balances, credit usage; Fireworks says payment card numbers were not stored and not affected); "for certain customers, a subset of incomplete model weights and datasets"; and secrets for a limited set of accounts.
- **Zero data retention products.** "We have not detected any impact to Inference, Training SDK and Nexus," which Fireworks describes as zero data retention by default. It says the investigation is ongoing.
- **Who.** Fireworks links the activity to "a cybercriminal threat actor group" it describes as financially motivated and focused on selling tokens from unauthorized LLM access to illicit routing gateways, which it calls LLMJacking. It does not name the group.
- **Response.** Fireworks says it worked with Palo Alto Networks Unit 42, notified law enforcement, revoked and replaced credentials and service accounts, isolated affected systems, tightened access to storage and analytics systems, and disabled self-serve dataset uploads and downloads for Batch Inference and dataset-based training.

## Timeline

| Date (2026) | Event | Source |
|---|---|---|
| Oct 6 | Fireworks identifies unauthorized use of internal credentials; evaluation-job environment variables accessed | Fireworks bulletin |
| Oct 9 | Fireworks publishes its first security bulletin | Fireworks update page |
| Oct 23 | Security incident at a third-party cloud provider hosting Fireworks R&D machines | Fireworks update |
| Oct 24 | Unauthorized workload run on Fireworks development machines; detected the same day | Fireworks update |
| Nov 2 | Fireworks told Notion that Notion AI data had been accessed | SecurityWeek, citing the companies |
| Nov 3 | Notion disconnects its systems from Fireworks | Notion notice |
| Nov 9 | Fireworks updates its bulletin with billing, dataset, model-weight and secrets impact | Fireworks update |
| Nov 11-12 | Disclosure reported by VentureBeat and SecurityWeek | Press |

VentureBeat separately reports that Fireworks confirmed a "new dataset" to Notion on November 8; we could not match that date to either company's own pages, so treat it as the outlet's reporting.

## Confirmed vs not confirmed

| Claim | Status |
|---|---|
| Fewer than 1% of Notion workspaces affected | Confirmed by Notion |
| Notion AI chat transcripts (inputs and outputs) exposed | Confirmed by Notion |
| Entry via a third-party cloud provider hosting Fireworks R&D machines | Confirmed by Fireworks |
| Fireworks billing data, some datasets and incomplete model weights accessed | Confirmed by Fireworks |
| Fireworks Inference, Training SDK and Nexus unaffected | Fireworks says no impact detected; investigation ongoing |
| Which Fireworks feature stored Notion's transcripts | Not stated by either company |
| Number of Notion customers notified | Not stated (SecurityWeek says Notion did not give a number) |
| Identity of the attacker group | Not named; Fireworks describes it as a financially motivated LLMJacking group |
| Whether the October 6 credential incident and the October 23-24 activity are linked | Not stated |

## What this means for engineering teams

Most product teams that ship AI features send prompts to at least one inference vendor. This incident shows where the assumptions break.

**Zero data retention is a per-feature property, not a vendor property.** Notion says its own commitment did not cover data it had to store for chat history and Insights, and that it found data retained at the Fireworks endpoints it used. Fireworks says its zero data retention default covers Inference, Training SDK and Nexus. VentureBeat quotes the Fireworks policy page: "A few features do store customer content, such as stored responses, batch jobs, and training." Ask each vendor, per endpoint you call (synchronous inference, batch jobs, fine-tuning datasets, evaluations, stored responses), whether content is written to storage, for how long, and how you verify the setting is on. Then check your own account configuration rather than the vendor's default.

**Classification and analytics pipelines are data stores too.** The affected Notion feature was Insights, a classification job over chat transcripts, not the chat itself. Batch analytics over prompts tends to create copies that outlive the conversation. Put those pipelines in your data inventory with an owner and a retention period, and include them in [the same vendor review you run for SaaS tools](/posts/vetting-third-party-saas-tools-before-they-touch-your-data/).

**Assume users paste secrets into AI chat.** Notion's advice to rotate any credentials pasted into Notion AI is the right default for any chat surface. Secret scanning on prompt logs, and on anything you send to a vendor, catches some of it; our guide to [detecting and rotating leaked API keys](/posts/how-to-detect-and-rotate-leaked-api-keys-before-attackers-use-them/) covers the rotation side. The broader patterns are in [LLM data leakage](/posts/llm-data-leakage-how-ai-applications-accidentally-expose-sensitive-information/).

**Rotate at the issuer.** Fireworks' first bulletin makes a point that applies to every platform with a secrets store: "Removing a stored secret alone does not invalidate the underlying credential." If you stored third-party API keys in a vendor's evaluation or job environment, revoke them with the provider that issued them, then check that provider's access logs.

**Vendor-of-vendor exposure.** The intrusion path ran through a cloud provider Fireworks used for R&D, two hops from Notion's customers. Your vendor questionnaire should ask whether development and research environments can reach production customer data, because here they apparently could.

## Limits of this article

We relied on the companies' own pages and two news outlets. Neither company has named the cloud provider, the attacker group or the storage feature involved, and both say investigations are ongoing. If either company changes its account, we will add a dated update at the top of this post.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Fewer than 1% of workspaces; chat transcripts; what Fireworks was used for; not-affected data; retention statement; actions as of Nov 3; customer guidance | [Notion help center notice](https://notion.com/help/security-incident-involving-a-third-party-ai-vendor) | Verified (read Nov 13, 2026; page undated) |
| Oct 23 provider incident, Oct 24 workload, data accessed, ZDR products unaffected, LLMJacking attribution, response steps | [Fireworks October 2026 security incident update](https://fireworks.ai/security/bulletins/october-2026-security-incident-update), last updated Nov 9, 2026 | Verified |
| Oct 6 internal-credential incident, evaluation-job secrets, "Removing a stored secret alone does not invalidate the underlying credential" | [Fireworks October 2026 security incident bulletin](https://fireworks.ai/security/bulletins/october-2026-security-incident) | Verified |
| Fireworks told Notion on Nov 2; Notion did not give a number of affected customers | [SecurityWeek, Nov 12, 2026](https://www.securityweek.com/notion-customer-data-compromised-in-fireworks-ai-hack/) | Qualified: press report |
| Nov 8 "new dataset" confirmation; Fireworks policy-page quote on features that store content | [VentureBeat, Nov 11, 2026](https://venturebeat.com/security/attackers-breached-the-fireworks-ai-storage-where-notion-ai-chats-sat-outside-zero-data-retention) | Qualified: press report |
