+++
title = "Uber Driver License Data Stolen in Fireworks AI Breach"
date = 2026-11-14T04:50:00Z
tags = ["hacking news", "uber", "fireworks ai", "data breach", "ai vendors", "third-party risk", "credentials"]
categories = ["ai-security"]
summary = "Uber says an unauthorized party used compromised credentials at a service provider to reach Uber data, and TechCrunch reports the provider is Fireworks AI and that drivers' license information was taken. State filings so far list 7,870 people in three states. What is confirmed, the timeline, and what engineering teams should check."
description = "Uber says compromised credentials at an AI vendor, reported as Fireworks AI, exposed driver data. State filings list 7,870 people so far. What is confirmed."
author = "Craig Leslie"
imageAlt = "A dark car with red tail lights driving along a wet city road at night, with the background streaked by motion blur"
imageCredit = "Photo by [Atul Pandey](https://unsplash.com/photos/car-driving-on-a-wet-road-at-night-fSBYj0VMNd4) on Unsplash"
takeaways = [
  "Uber's notice on the California attorney general's site, dated November 10, 2026, says an unauthorized party used compromised credentials at a service provider to access Uber data. Reuters reports Uber says it cut its data connections with the provider and has not identified any misuse of the data.",
  "TechCrunch reports the provider is Fireworks AI, the same AI inference vendor whose breach exposed Notion AI chat transcripts, and that drivers' personal and driver's license information was stolen.",
  "Per the reporting, the provider told Uber on October 9 that credentials were compromised, and Uber's investigation found on October 13 that they had been used to access its data.",
  "State filings reported so far list 2,567 people in Massachusetts, 3,430 in South Carolina and 1,873 in Rhode Island (7,870 combined). Illinois and California filings did not give a number in the reporting, so the total is not known.",
  "For engineering teams: inventory every credential your company has handed to an AI vendor (API keys, cloud tokens, data-connector secrets), scope them to the minimum, and plan to revoke them at the issuer the day a vendor reports an incident."
]

[[faq]]
q = "What data was stolen in the Uber breach?"
a = "TechCrunch reports that Uber's notices to drivers say personal information and driver's license information were stolen. Reuters reports that the California filing itself did not list the data involved. Uber says it has not identified any misuse of the data."

[[faq]]
q = "Was Uber itself hacked?"
a = "Uber's notice says an unauthorized party used compromised credentials at a service provider to access Uber data. TechCrunch identifies the provider as Fireworks AI and reports Uber described it as a security incident impacting one of its third-party vendors. Uber has not said its own systems were breached by other means."

[[faq]]
q = "How many Uber drivers were affected?"
a = "Uber has not given a total. Reported state filings list 2,567 people in Massachusetts, 3,430 in South Carolina and 1,873 in Rhode Island. TechCrunch reports Illinois residents are affected with a count pending and California drivers were notified without a number."

[[faq]]
q = "Is this the same Fireworks AI breach that affected Notion?"
a = "TechCrunch and Reuters link it to Fireworks AI, which has disclosed two October 2026 incidents: unauthorized use of internal credentials identified on October 6, and an October 23 incident at a cloud provider hosting its R&D machines. Neither Uber nor Fireworks has said publicly which path reached Uber's data."
+++

**What happened:** Uber says an unauthorized party used compromised credentials at one of its service providers to access Uber data. [TechCrunch](https://techcrunch.com/2026/11/13/uber-confirms-hackers-stole-thousands-of-drivers-license-information-in-data-breach/) reports that the provider is **Fireworks AI**, the AI inference company whose breach [exposed Notion AI chat transcripts](/posts/notion-ai-chats-exposed-fireworks-ai-breach-what-we-know/), and that drivers' personal and driver's license information was stolen. State filings reported so far list 7,870 people across three states; Uber has not given a total.

Uber is the second well-known company this week to say its data was taken through Fireworks. That makes it a useful case for any team that sends data or credentials to an AI vendor.

## What Uber has confirmed

The core facts come from Uber's own breach notice, as reported by [Reuters](https://finwire.io/news/stock-markets-news/uber-says-us-drivers-license-data-stolen-in-data-breach) and TechCrunch on November 13, 2026:

- **Cause.** Per the notice on the California attorney general's website, an "unauthorized party used compromised credentials at a service provider to access its data" (Reuters' paraphrase of the filing).
- **Vendor.** Uber, in a statement reported by TechCrunch, described "a security incident impacting one of our third-party vendors, Fireworks.ai." Reuters says the filing itself did not name the provider.
- **Data.** TechCrunch reports driver notices say personal and driver's license information was stolen. Reuters notes the California filing did not list the data types.
- **Response.** Uber severed its data connections with the provider and opened an investigation, and is offering credit monitoring and fraud assistance through Cyberscout, a TransUnion company (Reuters).
- **Misuse.** Uber said it "had not identified any misuse of the data to date" (Reuters).

## Timeline

| Date (2026) | Event | Source |
|---|---|---|
| Oct 6 | Fireworks identifies unauthorized use of internal Fireworks credentials | Fireworks bulletin (see our [Notion report](/posts/notion-ai-chats-exposed-fireworks-ai-breach-what-we-know/)) |
| Oct 9 | Provider tells Uber its credentials were compromised | Reuters, TechCrunch |
| Oct 13 | Uber's investigation determines the credentials were used to access Uber data | Reuters |
| Oct 23-24 | Separate incident at a cloud provider hosting Fireworks R&D machines; unauthorized workload run | Fireworks update |
| Nov 10 | Date on Uber's notice | Reuters |
| Nov 13 | Uber's notices and state filings reported | TechCrunch, Reuters |

## How many people: what the filings show

| State | People | Source |
|---|---|---|
| Massachusetts | 2,567 | TechCrunch |
| South Carolina | 3,430 | TechCrunch |
| Rhode Island | 1,873 | TechCrunch, Reuters |
| Illinois | affected, count pending | TechCrunch |
| California | drivers notified, no number given | TechCrunch |

The three numbered states add up to 7,870. That is a floor for those states, not a total: TechCrunch says the figure is expected to rise, and Reuters reports the notice also carried instructions for residents of the District of Columbia, Maryland, North Carolina, New York and Pennsylvania.

## Confirmed vs not confirmed

| Claim | Status |
|---|---|
| Unauthorized access to Uber data using credentials compromised at a service provider | Confirmed by Uber's notice (via Reuters) |
| The provider is Fireworks AI | Confirmed by Uber, as reported by TechCrunch |
| Driver's license and personal information stolen | Reported by TechCrunch from driver notices |
| Total number of people affected | Not disclosed |
| Which Fireworks incident path (October 6 credentials or October 23 cloud provider) reached Uber data | Not stated by Uber or Fireworks |
| What Uber data Fireworks held, and why | Not stated |
| Who did it | Fireworks links its incidents to a financially motivated group selling stolen LLM access; it has not named the group, and TechCrunch says no group has claimed the Uber data theft |

The dates line up with Fireworks' first incident (identified October 6, with Uber told on October 9), but neither company has said so. Treat that link as unconfirmed.

## What this means for engineering teams

Uber's notice describes the failure in one phrase: credentials at a service provider. Fireworks' own bulletin, covered in our [Notion report](/posts/notion-ai-chats-exposed-fireworks-ai-breach-what-we-know/), said it believes API keys and tokens stored as secrets in some customer accounts' evaluation jobs were captured. Whatever the exact path here, the pattern to check in your own environment is the same.

1. **List what you have handed to AI vendors.** API keys, cloud storage tokens, database or data-warehouse connectors, webhook secrets and service-account keys placed in vendor job settings, eval configs or "bring your own bucket" integrations. Most teams track the vendor; few track the secrets inside it.
2. **Scope those credentials to one job.** Read-only, single bucket or dataset, short expiry where the vendor supports it. A key that can read the whole driver table should not sit in an evaluation job.
3. **Rotate at the issuer.** Deleting a secret from the vendor's store does not revoke it. Revoke and reissue in your own cloud or identity provider; our guide on [detecting and rotating leaked API keys](/posts/how-to-detect-and-rotate-leaked-api-keys-before-attackers-use-them/) covers the order of operations.
4. **Cut the data path, then investigate.** Uber says it severed its data connections with the provider. Know in advance which network paths, connectors and OAuth grants you would disable, and who owns each.
5. **Watch access logs for the vendor's credentials.** If a vendor-held key was used from unfamiliar infrastructure, your own cloud audit logs are the fastest place to see it.
6. **Ask vendors per-feature questions.** Which features store your data or credentials, where, and for how long. Our [third-party SaaS vetting guide](/posts/vetting-third-party-saas-tools-before-they-touch-your-data/) has a question list to start from.

## Limits of this article

We could not retrieve the California attorney general filing or the state notices directly in this run; the filing details are as reported by Reuters (via finwire.io syndication) and TechCrunch on November 13, 2026. Fireworks did not respond to either outlet. We will add a dated update if Uber or Fireworks publishes more detail.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Notice says compromised credentials at a service provider used to access Uber data; notice dated Nov 10; Oct 9 and Oct 13 dates; Cyberscout; no misuse identified; RI 1,873; DC, MD, NC, NY, PA instructions | [Reuters via finwire.io, Nov 13, 2026](https://finwire.io/news/stock-markets-news/uber-says-us-drivers-license-data-stolen-in-data-breach) | Verified (press report of the filing) |
| Uber names Fireworks.ai; driver's license data; MA, SC, RI counts; Illinois and California status; no group has claimed it | [TechCrunch, Nov 13, 2026](https://techcrunch.com/2026/11/13/uber-confirms-hackers-stole-thousands-of-drivers-license-information-in-data-breach/) | Verified (press report) |
| Fireworks' October 6 and October 23-24 incidents, LLMJacking description | Fireworks bulletins, as cited in our [Notion report](/posts/notion-ai-chats-exposed-fireworks-ai-breach-what-we-know/) | Verified (Nov 13 run) |
| 7,870 combined across three states | Sum of the state counts above | Computed |
