+++
title = "Coles Cyber Incident: What the Supermarket Has Confirmed"
date = 2026-11-17T04:56:00Z
tags = ["hacking news", "coles", "retail security", "incident response", "breach disclosure", "australia", "acsc"]
categories = ["security-operations"]
summary = "Australian supermarket group Coles told the ASX on Monday, November 16, 2026 that it is investigating a cyber security incident in its IT environment. It says stores and online shopping are running normally and it has found no evidence so far that customer, team or supplier data was compromised or removed. Here is what is confirmed, what is not, and what engineers can take from the disclosure."
description = "Coles told the ASX on November 16 it is investigating a cyber incident. Stores and online run normally; no evidence so far of data theft. Confirmed vs unknown."
author = "John Marshall"
imageAlt = "A long row of nested blue shopping carts lined up against a bright yellow wall on a dark asphalt car park"
imageCredit = "Photo by [Fabio Bracht](https://unsplash.com/photos/e3oE-l-rtpA) on Unsplash"
takeaways = [
  "Coles disclosed a cyber security incident to the ASX on Monday, November 16, 2026, according to Forbes Australia, Information Age and Inside Retail.",
  "Coles says operations continue and customers can shop as normal in stores and online, and that it has found no evidence so far that customer, team or supplier data was compromised or removed.",
  "Coles says it is working with the Australian Cyber Security Centre and global cyber security experts to contain and secure its IT environment.",
  "Coles has not said what kind of incident it is, which systems are involved or when it started. No group has publicly claimed it in the reporting we reviewed.",
  "\"No evidence so far\" is an interim finding, not a clean bill of health; suppliers and staff should expect follow-up notices and watch for phishing that uses the news."
]

[[faq]]
q = "Was Coles hacked?"
a = "Coles says it is investigating a cyber security incident affecting its IT environment and is working to contain it. It has not described the incident in more detail, and it says it has found no evidence so far that customer, team or supplier data was compromised or removed."

[[faq]]
q = "Is Coles customer data affected?"
a = "Not according to Coles' initial findings. Its ASX update, as reported on November 16, 2026, says it has found no evidence so far that customer, team or supplier data was compromised or removed. The investigation is continuing, so that could change."

[[faq]]
q = "Can I still shop at Coles?"
a = "Yes, according to Coles: \"Operations continue and customers are able to shop as normal with Coles in stores and online.\" Information Age separately reported that a small number of customers had problems with Liquorland click-and-collect orders; Coles has not linked that to the incident."

[[faq]]
q = "Who is behind the Coles cyber attack?"
a = "Nobody has been identified. Coles has not named a threat actor, and none of the reporting we reviewed on November 16 and 17, 2026 mentions a public claim of responsibility."
+++

Australian supermarket group Coles told the Australian Securities Exchange on Monday, November 16, 2026 that it is "investigating a cyber security incident." The company says its stores and online shopping are running normally and that it has found no evidence so far that customer, team or supplier data was compromised or removed. It has not said what happened, which systems are involved or when the incident began.

We have not been able to retrieve the ASX announcement itself. The quotes below come from three outlets that reported it on November 16 and 17: [Forbes Australia](https://www.forbes.com.au/news/world-news/coles-investigates-cyber-security-incident/), [Information Age](https://ia.acs.org.au/article/2026/coles-launches-investigation-into-cyber-incident.html) (the Australian Computer Society's publication) and [Inside Retail](https://insideretail.com.au/digital/security/coles-investigating-cyber-security-incident-202611), with [teiss](https://www.teiss.co.uk/news/australian-retailer-coles-investigates-cyber-security-incident-finds-no-evidence-of-customer-data-breach-18466) in the UK reporting the same statement.

## What Coles has said

As quoted by those outlets, Coles' update says:

- It is "investigating a cyber security incident."
- "Coles is also working with global cyber security experts to contain and secure the Coles IT environment."
- It is working with the Australian Cyber Security Centre (ACSC) and will "engage with appropriate agencies and regulators as investigations continue."
- "Operations continue and customers are able to shop as normal with Coles in stores and online."
- Its findings so far have not uncovered evidence of "customer, team or supplier data" being compromised or removed.
- "We apologise for any concerns this may cause our customers and key stakeholders."

## Timeline

| Date (AEDT) | Event | Source |
|---|---|---|
| Friday, November 13, 2026 | Coles' email system reportedly affected by a Microsoft outage; store operations continued. Not linked to the incident by Coles. | Information Age |
| Monday, November 16, 2026, morning | Coles tells the ASX it is investigating a cyber security incident. | Forbes Australia, Inside Retail, Information Age |
| November 16 to 17, 2026 | No update reported on scope, cause or attribution. | Reporting reviewed for this article |

Coles has not said when the investigation began or when it expects to give another update.

## Confirmed vs not confirmed

| Question | Status |
|---|---|
| Coles is investigating a cyber security incident in its IT environment | **Confirmed by Coles** |
| Stores and online shopping operating normally | **Confirmed by Coles** |
| ACSC and external experts engaged | **Confirmed by Coles** |
| Customer, team or supplier data stolen | **No evidence so far, per Coles**; investigation continuing |
| Type of incident (ransomware, intrusion, account compromise or other) | **Not disclosed** |
| Systems affected | **Not disclosed** |
| When the incident started or was detected | **Not disclosed** |
| Who is responsible | **Not disclosed**; no public claim found in the reporting we reviewed |
| Liquorland click-and-collect problems for "a small number" of customers | Reported by Information Age; **not linked to the incident by Coles** |
| Internal system problems described by Reddit users | Mentioned by Information Age, which did not confirm them; **unverified** |

Information Age also noted the recent attacks on supermarket refrigeration controllers in Europe as context while stating no link to Coles; we [covered the CISA-FBI warning on those attacks](/posts/supermarket-freezer-hacks-refrigeration-controllers-cisa-fbi-warning/) last week. Nothing published so far connects them.

## How to read this kind of disclosure

A listed company's first disclosure is written to satisfy market rules while the investigation is still running, so it tells you what the company can stand behind today and little else. A few points engineers and security teams can take from the wording:

- **"No evidence so far" is a point-in-time finding.** It depends on what logs exist and how far responders have got. Plenty of breach notices start this way and are revised later. Treat it as "not yet known", not "nothing taken".
- **"Contain and secure the IT environment" says responders are still active.** It does not say whether the intruder is out. Expect follow-up notices.
- **Normal operations are not the same as no impact.** Point-of-sale and e-commerce can keep running while corporate IT, email or back-office systems are isolated. Coles has not said which, if any, systems were taken offline.

## What to check if you work with Coles

If your organisation supplies Coles or integrates with its systems, Coles' statement gives you no reason to assume your data is affected. A few low-cost steps still make sense while the investigation is open:

1. **Watch for phishing that cites the incident.** Public breach news is a common lure for fake "verify your account" or "update your payment details" emails. Confirm any request through a contact you already have, not one in the message.
2. **Know which credentials and integrations you share.** List API keys, SFTP accounts, EDI connections and supplier-portal logins tied to Coles so you can rotate them quickly if Coles asks or if the scope changes.
3. **Look for an update before acting on rumours.** Coles has said it will engage regulators as the investigation continues; a material change would normally appear as a further ASX announcement.

## Sources

- [Forbes Australia: Coles investigates cyber security incident](https://www.forbes.com.au/news/world-news/coles-investigates-cyber-security-incident/) (November 16, 2026)
- [Information Age: Coles launches investigation into cyber incident](https://ia.acs.org.au/article/2026/coles-launches-investigation-into-cyber-incident.html) (November 17, 2026)
- [Inside Retail: Coles investigating 'cybersecurity incident'](https://insideretail.com.au/digital/security/coles-investigating-cyber-security-incident-202611) (November 16, 2026)
- [teiss: Australian retailer Coles investigates cyber security incident](https://www.teiss.co.uk/news/australian-retailer-coles-investigates-cyber-security-incident-finds-no-evidence-of-customer-data-breach-18466) (November 16, 2026)
