+++
title = "Maileva Data Breach: La Poste Says 22 Million Hit"
date = 2026-11-16T04:58:00Z
tags = ["hacking news", "maileva", "la poste", "docaposte", "data breach", "gdpr", "saas security", "third-party risk"]
categories = ["identity-access"]
summary = "La Poste told AFP on November 14, 2026 that its subsidiary Maileva, a business mail-sending platform, lost the first names, last names and postal addresses of 22 million people in a mid-September attack. What is confirmed, what is not, and what teams that upload recipient lists to a mailing platform should check."
description = "La Poste says Maileva lost names and postal addresses of 22 million people in September. Bank details not affected. Confirmed facts, timeline and checks."
author = "Craig Leslie"
imageAlt = "A tall, untidy stack of opened envelopes and papers in white, pink, green, yellow and purple, shot close up with a shallow depth of field"
imageCredit = "Photo by [Alexander Grey](https://unsplash.com/photos/pile-of-printing-papers-tn57JI3CewI) on Unsplash"
takeaways = [
  "La Poste confirmed to AFP on November 14, 2026 that Maileva, a Docaposte subsidiary that sends mail on behalf of businesses, suffered a mid-September theft of the contact details of 22 million people.",
  "The exposed data is first name, last name and postal address of recipients of Maileva's business customers. La Poste says bank details and other personal information are not affected.",
  "Maileva suspended all services on September 23 after what it described as unauthorized access attempts to client accounts aimed at sending mail illegitimately; Docaposte said services were fully back on September 29.",
  "Maileva notified France's data protection authority CNIL and filed a criminal complaint; a judicial investigation is under way. Telling affected people is left to Maileva's business customers, who are the data controllers.",
  "No attacker has been publicly named, and how the attacker got in has not been disclosed."
]

[[faq]]
q = "What data was stolen in the Maileva breach?"
a = "According to La Poste, quoted by AFP via Euronews, the exposed data is the first name, last name and postal address of the people concerned. La Poste says other personal information such as bank details is not affected. The people concerned are recipients of mail sent by Maileva's business customers, not necessarily Maileva account holders."

[[faq]]
q = "How many people are affected by the Maileva breach?"
a = "22 million people, according to La Poste and to a written response from Maileva published by Cyberattaque.org. Cyberattaque.org also reports that internal documents it attributes to Docaposte list about 39 million references that deduplicate to roughly 22 million people; that document figure has not been confirmed publicly by the company."

[[faq]]
q = "Who will notify people affected by the Maileva breach?"
a = "Maileva told Cyberattaque.org that all affected organizations were informed of the incident and that informing the people concerned is the responsibility of Maileva's client organizations. That matches the GDPR split in which a processor notifies the controller and the controller handles notification."

[[faq]]
q = "Who is behind the Maileva attack?"
a = "Nobody has been named. None of the sources we reviewed reports a claim of responsibility or an attribution, and the method of access has not been disclosed."
+++

La Poste has confirmed that Maileva, its group's online platform for sending business mail, lost the names and postal addresses of 22 million people in an attack in mid-September 2026. The company disclosed the figure to AFP on Saturday, November 14, almost two months after it took the whole platform offline. Bank details are not affected, according to La Poste. The affected people are mostly not Maileva's customers but the recipients of letters those customers sent, which makes this a supply-chain data breach for thousands of French organizations.

## What happened

Maileva is a subsidiary of Docaposte, itself part of the La Poste group. It describes itself as a "Plateforme spécialisée dans l'envoi de courriers pour les entreprises" (a platform for sending business mail) and claims more than 70,000 users and 180 million documents sent in 2024, according to [Euronews](https://fr.news.yahoo.com/cyberattaque-maileva-filiale-poste-22-081810170.html).

On November 14, La Poste told AFP that Maileva "a été victime à la mi-septembre d'un vol des coordonnées de 22 millions de personnes" (was the victim in mid-September of a theft of the contact details of 22 million people), as reported by Euronews. In a written response published by [Cyberattaque.org](https://www.cyberattaque.org/maileva-docaposte-la-poste-cyberattaque/) on November 13, Maileva said: "22 millions de personnes sont concernées par le vol de leurs données d'identification : prénom, nom, adresse postale" and "Plusieurs milliers d'entreprises clientes de Maileva sont concernées par cet incident" (several thousand Maileva business customers are concerned).

## Timeline

| Date (2026) | Event | Source |
|---|---|---|
| Mid-September | Data theft, per La Poste | La Poste via AFP/Euronews |
| September 23, 07:00 | Maileva suspends all services; tells clients of unauthorized access attempts by a cybercriminal seeking to send mail illegitimately | Docaposte and Maileva client message, via [Solutions Numériques](https://www.solutions-numeriques.com/cyberattaque-maileva-six-jours-de-coupure-apres-une-tentative-de-detournement-de-la-plateforme/) |
| September 24 | Incident first reported publicly by Cyberattaque.org and FrenchBreaches | Solutions Numériques |
| September 29 | Docaposte: services "de nouveau pleinement opérationnels" (fully operational again) | Solutions Numériques |
| November 13 | Maileva's written response puts the toll at 22 million people | Cyberattaque.org |
| November 14 | La Poste confirms the 22 million figure to AFP | Euronews, [Morocco World News](https://www.moroccoworldnews.com/2026/11/346483/france-cyberattack-on-la-poste-subsidiary-exposes-data-of-22-million-people/) |

## Confirmed vs not confirmed

| Claim | Status | Who says so |
|---|---|---|
| Names and postal addresses of 22 million people stolen | Confirmed by the company | La Poste (AFP), Maileva (written response) |
| Bank details and other personal information not affected | Company statement | La Poste (AFP) |
| Several thousand business customers affected | Company statement | Maileva |
| CNIL notified, complaint filed, judicial investigation open | Company statement | La Poste (AFP), Maileva |
| Attacker tried to use client accounts to send mail | Company statement (September) | Maileva client message, Docaposte |
| About 39 million references deduplicating to ~22 million people | **Not confirmed publicly.** Comes from internal documents attributed to Docaposte | Cyberattaque.org |
| Full contents of letters stolen | **Not reported.** Cyberattaque.org notes the 22 million figure covers identity and address, not that every letter was taken | Cyberattaque.org (editorial analysis) |
| How the attacker got in (stolen passwords, missing MFA, a platform flaw) | **Not disclosed** | Solutions Numériques reports no new findings from Docaposte |
| Who did it | **Not attributed**; no public claim found | None of the sources reviewed |

## How the attack worked, as far as sources say

Very little is public. In September, Maileva told customers it had detected "des tentatives d'accès non autorisé par un cyber criminel afin de procéder à l'envoi illégitime de courriers" (unauthorized access attempts by a cybercriminal in order to send mail illegitimately), according to Solutions Numériques. Docaposte described "tentatives d'accès non autorisées à la plateforme". The response reported at the time was to block the accounts concerned and stop the whole service as a precaution; Maileva also told individual customers that their own account had not been used and that no mail had been sent from their client space or API portal.

What is not public is the link between those access attempts and the data theft La Poste now dates to mid-September: whether the addresses were taken through compromised customer accounts, through the API, or from Maileva's back end. We are not going to guess.

## What it means for teams that use a mailing platform

Maileva's model is common: a business uploads a document and a recipient list, and the provider prints, posts or sends it. The provider ends up holding a large, cross-customer store of names and addresses. Three things follow, whichever vendor you use.

**You may be the one who has to notify.** Maileva said: "L'information des personnes concernées relève des organisations clientes de Maileva" (informing the people concerned is up to Maileva's client organizations). Under [GDPR Article 33](https://gdpr-info.eu/art-33-gdpr/), "the processor shall notify the controller without undue delay after becoming aware of a personal data breach", and the controller then has the 72-hour clock to the supervisory authority. If you use a mail or print-and-post service, check your contract's breach-notification clause and who on your side receives that notice.

**Lock down sending accounts like production credentials.** The attacker's stated goal was to send mail from customer accounts. A sending account can mail anyone in your name, so it deserves the controls you would put on a payments or email-sending API:

- Turn on multi-factor authentication for every user of the portal, and remove shared logins.
- Scope API keys to the minimum (send only, no address-book export if the vendor supports it), store them in a secrets manager, and rotate them after any vendor incident.
- Restrict API access by source IP where the vendor offers it.
- Ask for sending and login logs, and alert on sends outside your normal volume, hours or templates.

**Minimise what sits at the vendor.** Check how long the platform keeps uploaded recipient lists and sent documents, and delete or shorten retention where you can. A list that was purged after posting cannot be stolen months later. Our [third-party SaaS vetting guide](/posts/vetting-third-party-saas-tools-before-they-touch-your-data/) has a checklist for these questions.

**Expect follow-on fraud.** Names and postal addresses alone are useful for convincing phishing letters and calls that cite a real past letter from a known sender. If your organization sent mail through Maileva, tell customers how you will and will not contact them.

The pattern is the same one we saw when a single AI vendor breach exposed customer data at [Notion and others](/posts/notion-ai-chats-exposed-fireworks-ai-breach-what-we-know/): the incident is at the supplier, the obligations land on its customers.

## Limits of this article

Two French outlets that reported the 22 million figure, Franceinfo and Ouest-France, could not be retrieved for this article. We rely on Euronews's AFP-based report, Cyberattaque.org's published Maileva response and Solutions Numériques's September reporting. We did not retrieve a statement from Maileva's or La Poste's own websites. We will add a dated update if the company discloses the access method or the CNIL comments.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| 22 million people, mid-September theft, names and postal addresses, bank details not affected, CNIL and complaint | [Euronews via Yahoo Actualités, Nov 15 2026 (AFP)](https://fr.news.yahoo.com/cyberattaque-maileva-filiale-poste-22-081810170.html) | Verified (company statement as reported) |
| Maileva written response: 22 million, several thousand client companies, customers inform individuals | [Cyberattaque.org, Nov 13 2026](https://www.cyberattaque.org/maileva-docaposte-la-poste-cyberattaque/) | Verified (company statement as published) |
| 39 million references from internal documents | Cyberattaque.org | Qualified (not confirmed by the company) |
| Sept 23 suspension, Sept 29 restoration, access attempts to send mail, accounts blocked | [Solutions Numériques, Sep 30 2026](https://www.solutions-numeriques.com/cyberattaque-maileva-six-jours-de-coupure-apres-une-tentative-de-detournement-de-la-plateforme/) | Verified (company statements as reported) |
| La Poste confirmed to AFP on Nov 14 | [Morocco World News, Nov 15 2026](https://www.moroccoworldnews.com/2026/11/346483/france-cyberattack-on-la-poste-subsidiary-exposes-data-of-22-million-people/), Euronews | Verified |
| Processor-to-controller notification duty | [GDPR Article 33](https://gdpr-info.eu/art-33-gdpr/) | Verified |
| Access method, attribution | No source | Not disclosed |
