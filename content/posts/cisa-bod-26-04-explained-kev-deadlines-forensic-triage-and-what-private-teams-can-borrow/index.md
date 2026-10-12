+++
title = "CISA BOD 26-04 Explained: KEV Deadlines, Forensic Triage and What Private Teams Can Borrow"
date = 2026-10-12T06:15:00Z
tags = ["vulnerability management", "process"]
categories = ["security-operations"]
summary = "CISA's Binding Operational Directive 26-04, issued June 10, 2026, replaces fixed patch deadlines for U.S. federal agencies with risk-based timelines and a three-day forensic triage requirement. A batch of five years-old flaws added to the KEV catalog on October 8, 2026 shows it in action."
description = "CISA BOD 26-04 explained: who it applies to, how the four risk inputs set remediation timelines, the forensic triage requirement, the phase dates, and which practices non-federal teams can borrow."
author = "FirewallSync Editorial"
imageAlt = "A small wooden hourglass with blue sand standing at a tilt on pebbles"
imageCredit = "Photo by [Aron Visuals](https://unsplash.com/photos/BXOXnQ26B7o) on Unsplash"
takeaways = [
  "BOD 26-04, \"Prioritizing Security Updates Based on Risk,\" is a Binding Operational Directive for U.S. Federal Civilian Executive Branch agencies. CISA's page is dated June 10, 2026, and states that it revokes BOD 22-01 and BOD 19-02. It does not legally bind private companies.",
  "Remediation time is set by four inputs: whether the flaw is in the Known Exploited Vulnerabilities (KEV) catalog, whether the asset is publicly exposed, whether exploitation is automatable, and whether the technical impact is total or partial control.",
  "Where the timeline table requires forensic triage, agencies must remediate or mitigate within three days and also assess whether the system is already compromised.",
  "On October 8, 2026, CISA added five older vulnerabilities (CVE IDs from 2015, 2016, 2021 and 2023) to KEV with a due date of October 11, 2026, three days later.",
  "Age and CVSS score did not decide those additions: one entry has a National Vulnerability Database base score of 4.9."
]

[[faq]]
q = "Does BOD 26-04 apply to private companies?"
a = "No. Per CISA's directive page it applies to Federal Civilian Executive Branch agency assets. Contractors are generally excluded unless a governing procurement contract directs otherwise. Private organizations can voluntarily borrow its approach."

[[faq]]
q = "What replaced the old KEV deadlines?"
a = "CISA's page states that BOD 26-04 revokes BOD 22-01 and BOD 19-02 and sets remediation timelines from a table keyed to KEV status, public exposure, automatability and technical impact. The table is published as an image in the directive and as Appendix A; we could not read its individual rows as text, so this article does not list every row."

[[faq]]
q = "What is forensic triage under BOD 26-04?"
a = "A rapid assessment of whether a system has already been compromised, carried out alongside the three-day fix. CISA's implementation guidance gives baseline steps, from scoping in the first two hours through an escalation decision at 48 to 72 hours, and says the directive requires adequate triage but not those specific timings."

[[faq]]
q = "Does an old CVE still matter if it was disclosed years ago?"
a = "It can. KEV is based on evidence of exploitation, not on age. Five CVEs published between 2015 and 2023 were added to KEV on October 8, 2026."
+++

If you work for a U.S. federal civilian agency, **Binding Operational Directive 26-04** (BOD 26-04) sets how fast you must fix known exploited vulnerabilities. If you do not, it still matters, because CISA's Known Exploited Vulnerabilities (KEV) catalog entries now carry its deadlines and its forensic-triage language, and many private teams use KEV as a patching signal. This article explains what the directive says, what we could and could not verify, and which parts transfer to organizations it does not bind.

We read CISA's directive page, CISA's implementation guidance page, the KEV catalog and National Vulnerability Database (NVD) records on October 12, 2026. This is research-based analysis; we did not test any system.

## What BOD 26-04 is and who it covers

| Item | What CISA's page says |
|---|---|
| Title | Prioritizing Security Updates Based on Risk |
| Page date | June 10, 2026 |
| Replaces | Revokes BOD 22-01 and BOD 19-02 (vulnerability remediation guidance that had been split across them) |
| Applies to | Assets in any federal information system of Federal Civilian Executive Branch (FCEB) agencies |
| Does not apply to | National security systems and certain Department of War and Intelligence Community systems |
| Contractors | Generally excluded unless a governing procurement contract directs otherwise |
| Cloud | Agencies must inventory third-party hosted systems; FedRAMP offerings are handled through the FedRAMP Program Management Office |

Source: [CISA, BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk).

## The four inputs that set the deadline

Instead of one deadline for every KEV entry, the directive uses a table (Table 1, Appendix A) with four yes/no style decision points, measured in calendar days:

1. **KEV status:** is the vulnerability in the KEV catalog?
2. **Publicly exposed:** is the asset reachable by unauthenticated or untrusted parties over public networks, wherever it physically sits? If several methods are used and any finds the asset exposed, the value is "yes."
3. **Automatable:** can exploitation be scripted reliably? CISA's heuristic: if a public proof-of-concept achieves remote code execution and reliably runs against a vulnerable system, it is automatable. CISA publishes results through its Vulnrichment Program.
4. **Technical impact:** *total* if the attacker can run arbitrary software, trigger all actions of the component, get a full-privilege account, or both CVSS confidentiality and integrity impacts are High; otherwise *partial*. Denial of service generally counts as partial.

The clock starts at whichever comes first: CISA adding the CVE to KEV, or the agency identifying the vulnerability on an asset and updating its Continuous Diagnostics and Mitigation (CDM) dashboard. Timelines are dynamic: removing an asset from public exposure can lengthen its deadline, and a KEV addition shortens it.

### What the deadlines actually are

This is where we must be careful. CISA's text states that where the table says "& forensic triage," the agency must remediate or mitigate **within three days** and also perform forensic triage. The page also describes "fix on system upgrade" for lower-risk cases. The individual day counts for every row are in an image of Table 1 that our reading tool could not extract, so we have not verified them against CISA's own table.

For orientation only, Tenable's [secondary summary](https://www.tenable.com/blog/cisa-bod-26-04-FAQ-vulnerability-remediation-impact) describes tiers of 3 days with triage, 3 days without triage, 14 days, 60 days and fix-on-upgrade. Treat that as a pointer, and read Appendix A on CISA's site before relying on a specific number.

## Phase dates

The directive phases its requirements. Phase I applies immediately; Phase II within 60 days of issuance; Phase III within 180 days.

| Phase | Requirement (summary) | Date if counted from June 10, 2026 |
|---|---|---|
| I | Update vulnerability management policies; monitor KEV and remediate to KEV timelines; report KEV status via CDM or manually every two weeks | Immediately |
| II | Update processes to cover vulnerabilities in the CVE database as well as KEV | August 9, 2026 |
| III | Remediate within Table 1 timelines; continuously tag externally reachable assets (manual reporters every seven days) | December 7, 2026 |

The dates in the last column are our arithmetic from the page date. The directive measures from issuance, and we found no separate issuance date, so treat them as approximate. On that count, Phase III had not yet begun as of October 12, 2026.

## Case study: five old CVEs added on October 8, 2026

The KEV catalog lists five entries added on 2026-10-08, each with a due date of 2026-10-11. NVD records for each show CISA's required action referring to BOD 26-04 and its "Forensics Triage Requirements."

| CVE | Product | Published (NVD) | What NVD says | CVSS v3.1 base score |
|---|---|---|---|---|
| CVE-2015-3306 | ProFTPD 1.3.5 | May 18, 2015 | mod_copy lets remote attackers read and write arbitrary files via site cpfr and cpto commands | 10.0 |
| CVE-2021-3199 | ONLYOFFICE Document Server before 5.6.3 | Jan 26, 2021 | Directory traversal with remote code execution in /upload when JWT is used | 9.8 |
| CVE-2023-22894 | Strapi through 4.5.5 | Apr 19, 2023 | Admin-panel users can infer sensitive user details, including password hashes and reset tokens for a super admin, via the query filter | 4.9 (NVD) / 7.2 (CISA) |
| CVE-2016-3081 | Apache Struts 2.3.19 to 2.3.28 (specified ranges) | Apr 26, 2016 | Remote code execution via method: prefix when Dynamic Method Invocation is enabled | 8.1 |
| CVE-2015-5477 | ISC BIND 9.x before 9.9.7-P2 and 9.10.x before 9.10.2-P3 | Jul 29, 2015 | Denial of service via TKEY queries (assertion failure and daemon exit) | 7.5 |

Sources: [CISA KEV catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) and the NVD records ([CVE-2015-3306](https://nvd.nist.gov/vuln/detail/CVE-2015-3306), [CVE-2021-3199](https://nvd.nist.gov/vuln/detail/CVE-2021-3199), [CVE-2023-22894](https://nvd.nist.gov/vuln/detail/CVE-2023-22894), [CVE-2016-3081](https://nvd.nist.gov/vuln/detail/CVE-2016-3081), [CVE-2015-5477](https://nvd.nist.gov/vuln/detail/CVE-2015-5477)). Scores are those listed in NVD, retrieved October 12, 2026; where two scorers differ, both are shown. The NVD records had been modified on October 9, 2026, so scores may change.

What this shows, and what it does not:

- **Age is not safety.** These flaws date from 2015 to 2023, yet were added with a three-day due date. The three-day interval is what the catalog and NVD show; we cannot tell from public data which row of Table 1 applies to any agency's asset, since that depends on exposure.
- **CVSS and KEV answer different questions.** The Strapi entry has an NVD base score of 4.9 yet is in KEV. Our guide to [CVSS, EPSS and KEV](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/) explains why exploitation evidence outranks severity.
- **We do not know how or by whom these were exploited.** The catalog entries we read do not say, and we have not assumed it.
- **Dates differ by product version.** If you run any of these products, check your exact version against the NVD affected ranges and your vendor's fixes; backported distribution patches can change the answer.

## Forensic triage: what "three days" includes

CISA's [implementation guidance](https://www.cisa.gov/news-events/directives/bod-26-04-implementation-guidance-prioritizing-security-updates-based-risk) presents baseline steps as best practice, and says the directive requires an adequate triage but not these specific timings. If a KEV entry has its own triage steps, those take precedence.

| Window | Step |
|---|---|
| First 2 hours after KEV addition | Scope: activate the team, define affected systems, set up out-of-band communication |
| 2 to 24 hours | Preserve evidence, volatile data first; patch and stabilize after collection |
| 6 to 24 hours | Contain and isolate affected and suspect systems |
| 24 to 48 hours | Analyze: unauthorized access, persistence, lateral movement, data staging |
| 48 to 72 hours | Report and decide: no evidence, suspected, or confirmed compromise (confirmed goes to CISA's reporting system) |

The ordering matters: evidence is collected before remediation where possible, because patching can destroy the traces you need.

## What non-federal teams can borrow

The directive does not bind you, so these are our suggestions, not requirements.

1. **Make exposure a first-class input.** Tag assets by environment, exposure and type, as the directive's Phase III tagging requires, so "is it internet-reachable?" is a query rather than a meeting.
2. **Treat KEV as a trigger for compromise checks, not only patching.** An exploited flaw that was exposed before you patched may already have been used. Compare with how we handled [recent zero-day roundups](/posts/fortimail-zero-day-cve-2026-104286-no-patch-yet-what-to-do/) and the [Cisco SD-WAN log checks](/posts/cisco-catalyst-sd-wan-manager-cve-2026-76504-authentication-bypass-fixed-releases-and-log-checks/).
3. **Rehearse the 72 hours.** Decide who runs scoping, where evidence goes and how you communicate if email is suspect. Our piece on [why vulnerability backlogs never shrink](/posts/the-vulnerability-backlog-that-never-shrinks/) covers the process side.
4. **Inventory old software.** The October 8 batch is a reminder that forgotten FTP daemons, unpatched Struts apps and DNS servers can matter. If you cannot list them, you cannot fix them.
5. **Know your response to a zero-day** before one lands: see [what to do when a zero-day is announced](/posts/what-is-a-zero-day-vulnerability-and-how-should-you-actually-respond-to-one/).

## Limits of this article

We could not read Table 1 as text and have not verified individual day counts beyond the three-day forensic triage requirement. We did not find a separate issuance date, so the phase dates are approximate. We did not verify whether any of the five products is exploited in a particular environment, nor the exploitation details behind the KEV additions. We did not review agencies' compliance with the directive.

## Sources and verification

Checked on October 12, 2026.

| Important claim | Source | Verification |
|---|---|---|
| BOD 26-04 page dated June 10, 2026; revokes BOD 22-01 and BOD 19-02; scope and exclusions; phases (immediate, 60, 180 days); four decision points; clock start; exposure, automatable and technical impact definitions | [CISA, BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk) | Qualified: no separate issuance date found; Table 1 day counts not readable as text |
| Three-day remediation plus forensic triage where the table says so | Same page | Verified |
| Tier descriptions (3, 14, 60 days, fix-on-upgrade) | [Tenable analysis](https://www.tenable.com/blog/cisa-bod-26-04-FAQ-vulnerability-remediation-impact) | Qualified: secondary source, not checked against Table 1 |
| Triage steps and timings; directive requires adequate triage, not these timings | [CISA implementation guidance](https://www.cisa.gov/news-events/directives/bod-26-04-implementation-guidance-prioritizing-security-updates-based-risk) | Verified |
| Five CVEs added to KEV 2026-10-08, due 2026-10-11 | [CISA KEV catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) and the five NVD records linked above | Verified as of October 12, 2026 |
| Publication dates, descriptions, affected versions, CVSS v3.1 scores | NVD records linked above | Qualified: records modified October 9, 2026 and may change |
| Phase II and III dates (August 9 and December 7, 2026) | Our calculation from June 10, 2026 | Qualified: assumes issuance date equals page date |
| Suggestions for non-federal teams | Our analysis | Qualified: editorial judgment |
