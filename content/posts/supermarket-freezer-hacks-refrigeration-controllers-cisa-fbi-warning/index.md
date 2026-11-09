+++
title = "Supermarket Freezer Hacks: What the CISA-FBI Warning Says"
date = 2026-11-09T04:56:00Z
tags = ["hacking news", "ot security", "ics", "refrigeration controllers", "cisa", "danfoss"]
categories = ["security-operations"]
summary = "Attackers remotely switched supermarket freezers to heating in hundreds of French stores in October and in Belgium, Sweden, Estonia and other countries on November 2. On November 5 CISA, the FBI and three other US agencies told operators to pull refrigeration controllers off the internet. What is confirmed, what is not, and what to check."
description = "Supermarket freezer hacks: attackers set refrigeration controllers to heat in France, then Belgium and Sweden. What CISA and the FBI advise operators to do."
author = "Craig Leslie"
imageAlt = "Close-up of feathery frost crystals spreading across a pale blue frozen window pane"
imageCredit = "Photo by [Kumiko SHIMIZU](https://unsplash.com/photos/a-close-up-of-ice-crystals-on-a-window-IrIDuo7U5HU) on Unsplash"
takeaways = [
  "In a first wave around October 11-12, 2026, attackers took control of refrigeration controllers in French supermarkets and pushed units into heating and defrost; the Paris prosecutor's office opened an investigation and, per The Record, counts around 700 victims.",
  "A second wave on November 2 hit stores in Belgium, Sweden, Luxembourg, Estonia and the Netherlands. Retailers including Delhaize, Carrefour Belgium, ICA and Coop confirmed affected stores; Swedish stores reported freezers set to 50°C.",
  "On November 5, CISA, the FBI, HHS, USDA and DoT published a joint warning that attackers may use 'unpatched or internet-accessible controllers' to force 'continuous heating and defrost cycles'. It names no vendor and no CVE.",
  "Danfoss equipment was reported in France and Estonia, Copeland equipment in Belgium. Both vendors said after the French attack that affected devices were mainly discontinued products. How attackers got in has not been confirmed publicly.",
  "What to do: take controller panels off the public internet, change default passwords, retire end-of-life controllers, alert on setpoint changes, and keep a temperature alarm that does not depend on the controller."
]

[[faq]]
q = "How were supermarket freezers hacked in Europe?"
a = "Attackers remotely took control of store refrigeration controllers and changed their settings so units heated or defrosted continuously. The initial access method has not been confirmed publicly. The Record reports that the October attack in France compromised internet-exposed remote controllers, and the US joint warning says actors may exploit unpatched or internet-accessible controllers through authentication bypass, code injection or weak configurations."

[[faq]]
q = "Which countries were affected by the refrigeration cyberattacks?"
a = "France in the first wave around October 11-12, 2026. The second wave on November 2 was reported in Belgium, Sweden, Luxembourg, Estonia, the Netherlands and Ireland. Later reports mention incidents in Germany, Italy, Portugal and Romania, but we have not confirmed those against primary sources."

[[faq]]
q = "Is CVE-2025-41450 being exploited in the supermarket attacks?"
a = "No source has linked it. CVE-2025-41450 (authentication bypass) and CVE-2025-41451 (command injection) affect Danfoss AK-SM 8xxA controllers before versions 4.2 and 4.3.1. Neither is in CISA's KEV catalog as of version 2026.11.06, and CISA's enrichment of both records still says Exploitation: poc. If you run these controllers, patch them anyway."

[[faq]]
q = "Who is behind the supermarket freezer attacks?"
a = "Nobody has claimed them and no government has attributed them. Belgium's Centre for Cybersecurity said it is not known who is behind the attack and that it may never be possible to identify them. It is also not known whether the same actor carried out both waves."
+++

Attackers have twice switched supermarket freezers into heaters across Europe. In the first wave, around October 11-12, 2026, refrigeration controllers in hundreds of French supermarkets were remotely pushed into heating and defrost cycles. On November 2 a second wave hit stores in Belgium, Sweden, Luxembourg, Estonia and the Netherlands, with Swedish stores reporting freezers set to 50°C. On November 5, CISA, the FBI and three other US agencies published a joint warning telling operators to take refrigeration controllers off the internet.

Nobody has claimed the attacks, and the way in has not been confirmed. The defensive lesson is clear anyway: these are internet-reachable OT devices, often past end of support, controlling equipment whose failure costs money within hours.

## What happened

The [BleepingComputer report of October 12](https://bleepingcomputer.com/news/security/cyberattack-shuts-down-refrigerators-at-french-supermarkets) said attackers hijacked controllers on the Sunday night and used them to raise temperatures by triggering the built-in automatic defrost. Citing French outlets, it put the impact at 250 to 350 stores across chains including Intermarché, Coopérative U, Carrefour Market, Monoprix and Leclerc. Coopérative U's president called it "an extremely serious matter and is unprecedented", and the Paris prosecutor's office opened an investigation into "the large-scale cyberattack affecting the refrigerators of several major food retail chains across France", according to AFP as quoted by BleepingComputer.

The second wave came in the early hours of Monday, November 2. [The Record](https://therecord.media/cyberattack-grocery-freezers-europe) quoted a Swedish store manager: "We can't adjust the temperatures, we can't change them. Heat is blowing into the freezers. Everything is ruined." Retailers confirmed affected stores to [AP, as published by ITV](https://www.itv.com/news/2026-11-02/freezers-at-supermarkets-across-europe-hit-by-apparent-cyberattacks): Delhaize said several dozen stores, mostly in Belgium; Carrefour Belgium said 15 of its more than 700 stores, with "an extremely limited impact"; ICA said "a limited number" of Swedish stores.

## Timeline

| Date (2026) | Event | Source |
| --- | --- | --- |
| Oct 11-12 | Refrigeration controllers in French supermarkets switched to heating/defrost; 250-350 stores reported | BleepingComputer, citing French outlets |
| By Oct 12 | Paris prosecutor opens an investigation | AFP via BleepingComputer |
| Nov 2 | Second wave: Belgium, Sweden, Luxembourg, Estonia, Netherlands, Ireland | The Record; AP via ITV |
| Nov 2 | Belgium's Centre for Cybersecurity (CCB) says it is aware but cannot identify the actor | The Record |
| Nov 5 | CISA, FBI, HHS, USDA and DoT publish a joint hardening warning | [Joint advisory (IC3 PDF)](https://www.ic3.gov/CSA/2026/261105.pdf) |

## Confirmed vs not confirmed

| Claim | Status |
| --- | --- |
| Refrigeration controllers in French stores were remotely manipulated in October | Confirmed by retailers and a criminal investigation |
| Around 700 victims in the French attack | Attributed: the Paris prosecutor's office, as reported by The Record |
| Stores hit on Nov 2 in Belgium (Delhaize, Carrefour), Sweden (ICA, Coop), Estonia (Selver) | Confirmed by the retailers to AP; Coop's six stores per Swedish news agency TT |
| More than 50 Belgian stores affected | Attributed: The Record |
| Danfoss equipment involved | Reported: older Danfoss controllers in France (BleepingComputer) and an "older Danfoss system" in Estonia (a contractor, per The Record) |
| Copeland equipment involved | Reported by Dutch broadcaster NOS, per The Record |
| How attackers got in | Not confirmed. The Record says the French attack compromised internet-exposed remote controllers; no source has published the method for Nov 2 |
| A specific CVE was exploited | Not confirmed by any source |
| Who did it | Not claimed and not attributed. Not known whether one actor carried out both waves |
| Later incidents in Germany, Italy, Portugal and Romania, and EU emergency meetings | Reported by [Latin Times](https://www.latintimes.com/eu-emergency-meetings-supermarket-refrigeration-cyberattacks-600921); we have not confirmed these with primary sources |

## What the vendors said

According to The Record, both Danfoss and Copeland said after the French attack that the affected devices were mainly discontinued products that no longer received security updates. Stephan Moelans, CEO of the Belgian installer Sabcobel, said he knew of about 20 affected units out of hundreds his company manages, and that they need physical modifications, not just a software update. The Record also cites an earlier Danfoss newsletter saying stores hacked in Israel lacked adequate firewall or VPN protection.

## What the US agencies said

The [joint document](https://www.ic3.gov/CSA/2026/261105.pdf), titled "US Government Partners Urge Hardening Industrial Refrigeration and Cold Chain Monitoring Systems", is dated November 5, 2026. It says the agencies are aware of malicious activity targeting "electronic temperature controllers and commercial refrigeration controllers" in retail grocery and cold storage, across healthcare, chemical, food and agriculture, and transportation. Actors may exploit "unpatched or internet-accessible controllers" to "remotely alter settings and force units into continuous heating and defrost cycles", using authentication bypass, arbitrary code injection and weak configurations. It also warns of "denial-of-view", where operators lose sight of real temperatures.

It names no vendor, product, port or CVE. Its eight mitigations, each mapped to CISA's Cross-Sector Cybersecurity Performance Goals:

1. Do not expose controller panels to the internet; put any needed remote access behind an up-to-date firewall or edge device.
2. Put OT devices on a dedicated VLAN separate from business networks.
3. Change default passwords, enforce strong passwords, and use phishing-resistant MFA where feasible.
4. Keep firmware current, and retire end-of-life devices the manufacturer no longer supports.
5. Allowlist the devices and IP addresses allowed to make changes.
6. Keep tested offline and offsite backups.
7. Enable and review logs; where OT logging is poor, capture network traffic between assets.
8. Define reasonable setpoint ranges and alert on deviations.

## The known Danfoss CVEs

No source has tied these attacks to a specific vulnerability. Two published flaws in Danfoss AK-SM 8xxA store controllers are still worth checking if you run that line. From the [CVE records](https://github.com/CVEProject/cvelistV5) published by Danfoss as CNA:

| CVE | Weakness | Affected | Score in record | CISA-ADP SSVC |
| --- | --- | --- | --- | --- |
| CVE-2025-41450 | Authentication bypass with privileged access | AK-SM 8xxA Series before 4.2 | CVSS 3.1 8.2 | Exploitation: poc; Automatable: no |
| CVE-2025-41451 | Post-authentication OS command injection via alarm-to-mail configuration fields | AK-SM8xxA Series before 4.3.1 | CVSS 4.0 8.7 | Exploitation: poc; Automatable: no |

Neither is in CISA's KEV catalog (version 2026.11.06), and CISA's enrichment still records proof-of-concept rather than active exploitation. That is consistent with what is public: real attacks on refrigeration controllers, but no confirmed link to these CVEs. Our guides to [the KEV JSON feed](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/) and [reading SSVC values in a CVE record](/posts/cisa-vulnrichment-how-to-read-ssvc-values-in-a-cve-record-and-turn-them-into-a-patch-decision/) show how to alert when either changes.

## What engineers should check

Retail is the headline, but the joint warning also names healthcare, chemical and transportation cold chains. If your organisation runs refrigeration, HVAC or building-management controllers, or your IT team supports sites that do:

- **Find them from the outside.** Scan your own public IP ranges and check your external attack surface tool for controller web interfaces. Contractors and installers often add remote access without IT knowing; ask them for a list.
- **Remove direct exposure.** Put remote access behind a VPN or managed gateway with MFA, and allowlist the installer's addresses. Treat a controller panel reachable from the internet as an incident to close today.
- **Check firmware against the vendor's advisories**, including the AK-SM 8xxA versions above if you run them. Where the vendor says the model is discontinued, plan replacement: the vendors say affected devices were mainly discontinued, and the installer quoted above says some units need physical modifications, not just a software update.
- **Change default and shared passwords**, especially those set at installation and shared across stores.
- **Alert on setpoint and defrost-schedule changes**, and set hard limits where the controller supports them.
- **Keep an independent temperature alarm.** A separate sensor and alerting path is what tells you a freezer is warming when the controller's own display has been altered.
- **Write the runbook now:** who can go on site to switch units to local or manual control, and how stock decisions get made.

## Limits of this article

This is a fast-moving incident. Store counts come from retailers and press reports and differ between outlets. We have not seen technical indicators, a vendor incident report or an official account of initial access. We will add a dated update if a vendor, CERT or prosecutor publishes the method or an attribution.

## Sources and verification

| Important claim | Source | Status |
| --- | --- | --- |
| Joint warning text, date, co-sealing agencies and eight mitigations | [CISA/FBI/HHS/USDA/DoT joint document (IC3)](https://www.ic3.gov/CSA/2026/261105.pdf) | Verified |
| French wave: timing, 250-350 stores, chains, prosecutor investigation | [BleepingComputer, Oct 12, 2026](https://bleepingcomputer.com/news/security/cyberattack-shuts-down-refrigerators-at-french-supermarkets) | Qualified (press, citing French outlets and AFP) |
| Nov 2 wave: countries, quotes, CCB statement, Sabcobel, Danfoss/Copeland statements, ~700 French victims | [The Record, Nov 2, 2026](https://therecord.media/cyberattack-grocery-freezers-europe) | Qualified (press) |
| Retailer confirmations: Delhaize, Carrefour Belgium, ICA, Coop, Selver | [AP via ITV, Nov 2, 2026](https://www.itv.com/news/2026-11-02/freezers-at-supermarkets-across-europe-hit-by-apparent-cyberattacks) | Verified (company statements quoted) |
| Later incidents and EU meetings | [Latin Times](https://www.latintimes.com/eu-emergency-meetings-supermarket-refrigeration-cyberattacks-600921) | Not confirmed; listed as reported |
| CVE-2025-41450 and CVE-2025-41451 details and SSVC | [cvelistV5 records](https://github.com/CVEProject/cvelistV5) | Verified (data) |
| Neither CVE in KEV | [cisagov/kev-data](https://github.com/cisagov/kev-data), catalog 2026.11.06 | Verified (data) |
