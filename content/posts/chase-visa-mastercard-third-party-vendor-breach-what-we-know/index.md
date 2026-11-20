+++
title = "Chase, Visa, Mastercard Vendor Breach: What We Know"
date = 2026-11-20T04:40:00Z
tags = ["hacking news", "third-party risk", "data breach", "jpmorgan chase", "visa", "mastercard", "phishing", "vendor security"]
categories = ["security-operations"]
summary = "JPMorgan Chase, Visa and Mastercard each said on November 19, 2026 that a third-party provider was hit and that limited non-payment data, such as names and email addresses, may have been exposed. None named the vendors. Here is what the companies said, what the n0n extortion group claims, and what is not confirmed."
description = "Chase, Visa and Mastercard say vendors were breached and some names and emails may be exposed, not card data. What each firm said and what is unconfirmed."
author = "Craig Leslie"
imageAlt = "A hand holds a plain blue chip card against a white contactless card reader held in another hand"
imageCredit = "Photo by [SumUp](https://unsplash.com/photos/XBi0c3PBR14) on Unsplash"
takeaways = [
  "On November 19, 2026, JPMorgan Chase, Visa and Mastercard each said a third-party service provider had suffered a security incident. None named the provider.",
  "JPMorgan Chase said it believes attackers accessed marketing data held by vendors that may include some customer names and email addresses. Mastercard said a limited number of email addresses of cardholders in one benefit program were exposed.",
  "All three said their own systems and payment data were not affected. Visa said its provider is in Asia Pacific and that card numbers were not affected.",
  "The extortion group n0n claimed all three on its leak site, according to The Register and SOCRadar. SOCRadar told Yahoo Finance it had not independently verified the claim.",
  "The practical risk the companies' statements point to is targeted phishing that uses real names and email addresses. For engineers, the lesson is how much customer data marketing vendors hold."
]

[[faq]]
q = "Was my Chase, Visa or Mastercard card number stolen?"
a = "None of the three companies says so. Visa said no payments data such as card numbers was affected, Mastercard said the exposed data was non-payment email addresses, and JPMorgan Chase said the data may include some customer names and email addresses. JPMorgan said it will contact affected customers directly where appropriate."

[[faq]]
q = "Which vendor was hacked in the Chase, Visa and Mastercard breach?"
a = "Not disclosed. None of the three firms named its third-party provider. Visa said its provider is in Asia Pacific. It is also not confirmed whether the three incidents involve the same vendor."

[[faq]]
q = "Who is behind the attack?"
a = "An extortion group called n0n listed all three companies on its data-leak site, according to The Register, and SOCRadar told Yahoo Finance the group shared sample data. SOCRadar said it had not independently verified that the group carried out the intrusions. No company has attributed the incident."

[[faq]]
q = "Is this linked to the bank outages earlier in the week?"
a = "JPMorgan Chase and Visa both said no. Chase said there is no connection to service disruption some customers experienced earlier in the week, and Visa said the incident is unrelated to system disruptions across industries that week."
+++

**What happened:** On Thursday, November 19, 2026, JPMorgan Chase, Visa and Mastercard each confirmed that a third-party service provider had been hit by a cyberattack and that limited customer data held by that provider may have been exposed. According to their statements, the data is non-payment information, chiefly names and email addresses. All three said their own systems and payment networks were not affected. None has named the vendor or said how many customers are involved.

The statements were reported the same day by [The Register](https://www.theregister.com/security/2026/11/19/chase-visa-mastercard-confirm-third-party-cyberattacks-that-may-have-exposed-customers-info/5311175), [ABC News](https://abcnews.com/US/jpmorgan-chase-reports-cyberattack-party-service-providers/story?id=138287705) and [Yahoo Finance](https://finance.yahoo.com/markets/article/jpmorgan-visa-and-mastercard-disclose-cyberattack-on-third-party-vendors-190314490.html). JPMorgan Chase also posted its statement on X.

## What each company said

**JPMorgan Chase**, in a statement quoted by all three outlets: "We have learned that third parties who provide services to the firm were the target of a cyber attack," and "Based on our investigation so far, we believe the attackers accessed certain marketing data held by those vendors, which may include some customer names and email addresses." ABC News also quotes the bank: "Where appropriate, we will contact affected customers directly and offer support," "including complimentary credit monitoring."

**Mastercard**, in a statement The Register attributes to Seth Eisen, a senior vice president: "We were recently informed of an incident at a third-party provider that resulted in the exposure of a limited amount of email addresses - non-payments information - from a small subset of cardholders enrolled in a specific benefit program." It added: "There is no impact to the Mastercard payment network or the ability for people to use their cards," and "At this time, the exposure has been contained."

**Visa**, in a statement to The Register and ABC News: "They are associated with an incident involving a third-party service provider in Asia Pacific," "Visa's systems were not involved and were not impacted. No payments data such as card numbers were affected."

## Timeline

| Date (2026) | Event | Source |
| --- | --- | --- |
| Week of Nov 16 | Service disruptions at several US firms, including some Chase customers. Chase and Visa say the vendor incident is unrelated. | Company statements via The Register, ABC News |
| Monday (Nov 16) | Extortion group n0n posts all three firms to its data-leak site | The Register |
| Nov 19 | JPMorgan Chase, Visa and Mastercard issue statements on third-party incidents | The Register, ABC News, Yahoo Finance |

When each vendor was breached has not been disclosed. The Register reports that none of the three firms would say when the breaches occurred.

## Confirmed vs not confirmed

| Claim | Status | Who says so |
| --- | --- | --- |
| A third-party provider to each firm had a security incident | Confirmed | Each company |
| Exposed data may include some customer names and email addresses (Chase) | Stated with hedging ("we believe", "may include") | JPMorgan Chase |
| Email addresses of a small subset of cardholders in one benefit program exposed (Mastercard) | Confirmed by the company | Mastercard |
| No card numbers or payment data affected | Stated | Visa; Mastercard ("non-payments information") |
| Company systems and payment networks not affected | Stated | All three |
| Name of the vendor or vendors | Not disclosed | None of the firms |
| Whether the three incidents share one vendor | Not confirmed | No company has said |
| Number of customers affected | Not disclosed | None of the firms |
| n0n carried out the intrusions | Claimed, not verified | n0n's leak-site post, per The Register and SOCRadar; SOCRadar said it had not independently verified it |
| Link to the week's service outages | Denied | JPMorgan Chase, Visa |

## What the n0n claim amounts to

According to The Register, "Extortion crew n0n claimed responsibility for all three alleged hacks, posting the financial giants to its data-leak site on Monday." Yahoo Finance reports, citing cybersecurity firm SOCRadar, that the group "shared sample data as proof," and that SOCRadar "hasn't independently verified whether the ransomware group carried out the intrusion." Yahoo adds that The Wall Street Journal first reported the connection.

The Register describes n0n as a group that emerged in September and is "believed to be based in Russia." That attribution is the outlet's description, not a statement by the companies or a government agency. We have not reviewed the leak-site post and will not link to it.

## How the attack worked

No source describes it. The companies have said only that the affected data was held by vendors. There is no public statement on the entry point, whether the vendors' own systems or a shared software platform were involved, or whether any data was encrypted. We will update this section if a company, vendor or regulator publishes details.

## What it means for engineers

The data in question is marketing data, which is easy to underrate. A few things to check in your own environment:

- **Inventory what marketing and benefits vendors hold.** Names plus email addresses tied to a known bank or card brand are enough for convincing phishing. SOCRadar's CISO Ensar Seker told Yahoo Finance that "The most immediate risk for consumers is targeted phishing that impersonates their bank or card provider." Find out which vendors receive customer exports, which fields, and how often.
- **Minimise the export.** If a campaign tool needs an email address and a segment, it does not need account numbers, balances or full names. Trim exports at the source and expire old lists the vendor no longer needs.
- **Use per-vendor identifiers.** A pseudonymous customer ID per vendor, rather than your internal one, limits how breached data can be joined with other leaks.
- **Contract for notification.** Mastercard's wording ("We were recently informed") is a reminder that you learn about vendor incidents on the vendor's timeline. Check that contracts set a notification window and what details the vendor must hand over.
- **Prepare customer-facing anti-phishing guidance.** If you are a brand whose customers' emails might be in a vendor breach, publish how you do and do not contact customers before attackers use the list.

This is the same pattern as the recent breach at an AI inference vendor that exposed downstream customers' data, covered in our reports on [Notion](/posts/notion-ai-chats-exposed-fireworks-ai-breach-what-we-know/) and [Uber](/posts/uber-driver-license-data-stolen-fireworks-ai-breach-what-we-know/): the brand in the headline was not the system that was breached.

## What to do if you are a customer

Watch for emails that use your name and claim to come from Chase, Visa or Mastercard, especially ones that ask you to log in, confirm card details or call a number. Go to the bank's app or the number on the back of your card instead of following links. JPMorgan Chase says it will contact affected customers directly where appropriate.

## Sources

- The Register, "Chase, Visa, Mastercard confirm third-party cyberattacks that may have exposed customers' info," November 19, 2026: [theregister.com](https://www.theregister.com/security/2026/11/19/chase-visa-mastercard-confirm-third-party-cyberattacks-that-may-have-exposed-customers-info/5311175)
- ABC News, "JPMorganChase, Mastercard, Visa report cyberattack on third-party service providers," November 19, 2026: [abcnews.com](https://abcnews.com/US/jpmorgan-chase-reports-cyberattack-party-service-providers/story?id=138287705)
- Yahoo Finance, "JPMorgan, Visa, and Mastercard disclose cyberattack on third-party vendors," November 19, 2026: [finance.yahoo.com](https://finance.yahoo.com/markets/article/jpmorgan-visa-and-mastercard-disclose-cyberattack-on-third-party-vendors-190314490.html)
