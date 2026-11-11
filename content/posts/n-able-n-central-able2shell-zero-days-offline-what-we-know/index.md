+++
title = "N-able N-central Offline After Able2Shell Zero-Days"
date = 2026-11-11T04:56:00Z
tags = ["hacking news", "n-able", "n-central", "rmm", "msp security", "zero-day", "able2shell", "incident response"]
categories = ["security-operations"]
summary = "A researcher published exploit code for what Huntress counts as 33 critical N-able N-central flaws on November 8. N-able took hosted N-central offline, told on-premises customers to shut their servers down, and on November 10 published seven CVEs and a hotfix. What is confirmed, what is not, and what MSPs and IT teams should check."
description = "N-able pulled hosted N-central offline after Able2Shell exploits went public Nov 8. Seven CVEs, a hotfix, no confirmed customer compromise. What to check."
author = "Craig Leslie"
imageAlt = "A long aisle between rows of open grey metal equipment cabinets under a steel-truss warehouse roof"
imageCredit = "Photo by [İsmail Enes Ayhan](https://unsplash.com/photos/server-room-aisle-with-metal-equipment-racks-lVZjvw-u9V8) on Unsplash"
takeaways = [
  "On Sunday, November 8, 2026 an independent researcher published exploit code on GitHub for flaws in N-able N-central, a remote monitoring and management (RMM) platform used by managed service providers. Huntress counts 33 critical vulnerabilities forming four exploit chains ('Able2Shell'): three to remote code execution, one to root.",
  "N-able took its hosted N-central environments offline and told on-premises customers to keep servers offline until it confirmed they could be restored. As of November 9, 15:15 UTC, N-able said it had not seen active exploitation.",
  "On November 10 N-able, as CVE Numbering Authority, published seven CVE records. Two are unauthenticated network flaws scored CVSS v4 9.3: XXE (CVE-2026-125883) and SSRF (CVE-2026-125881). CSO Online reports the fix as N-central 2026.4 HF2; the CVE records list versions before 26.4.1 as affected.",
  "watchTowr says it saw exploitation attempts against N-central honeypots after the disclosure. That is attempted exploitation, not a confirmed customer compromise.",
  "If you run N-central: keep it offline until you can patch, upgrade agents and probes with it, then review logins, new admin accounts, remote sessions and scripts pushed since November 8."
]

[[faq]]
q = "What is Able2Shell?"
a = "Able2Shell is the name the researcher gave to the exploit chains published on GitHub on November 8, 2026 against N-able N-central. Huntress describes 33 critical vulnerabilities forming four chains: three lead to remote code execution and one to privilege escalation to root. The research targeted N-central Appliance 2026.4.0.31; earlier versions are likely affected, per Huntress."

[[faq]]
q = "Is there a patch for the N-central Able2Shell vulnerabilities?"
a = "Yes. CSO Online reports N-able shipped an emergency hotfix, N-central 2026.4 HF2, on November 10, and that customers must also upgrade Agents and Probes to restore compatibility. N-able's seven CVE records, published the same day, list N-central versions before 26.4.1 as affected. N-able has not said how many of the 33 published issues it reproduced."

[[faq]]
q = "Has N-central been exploited in the wild?"
a = "Not confirmed for customer environments. N-able said it had not seen active exploitation as of November 9 at 15:15 UTC, and TechCrunch quotes it as having 'no evidence of successful exploitation against any of its customer environments.' watchTowr reported exploitation attempts against N-central honeypots after the disclosure. None of the seven new CVEs is in CISA's KEV catalog as of version 2026.11.10."

[[faq]]
q = "Is the hosted N-central service back online?"
a = "We could not confirm restoration at the time of writing. N-able's status page said hosted N-central was offline 'while we take the necessary actions to secure the environments and implement appropriate remediation,' as quoted by TechCrunch on November 10. Check N-able's status page for the current state."
+++

*Reported as of November 11, 2026, 05:00 UTC. We will add dated updates here if confirmed facts change.*

N-able has taken its **cloud-hosted N-central** service offline and told customers who run N-central on their own servers to **shut them down**, after an independent researcher published exploit code for dozens of unpatched flaws on Sunday, November 8. N-central is a remote monitoring and management (RMM) platform: managed service providers (MSPs) and IT teams use it to push scripts, patches and remote sessions to the machines they manage, which is why a takeover of the server can reach every downstream customer.

On November 10 N-able published **seven CVE records** and, per [CSO Online](https://www.csoonline.com/article/4247028/n-able-n-central-gets-emergency-fix-two-days-after-33-exploits-published.html), an emergency hotfix. N-able says it has **no evidence of successful exploitation** of customer environments. Below: what is confirmed, what is not, and what to check if N-central is in your environment.

## Timeline

| Date (2026) | Event | Source |
|---|---|---|
| Aug 3 to Sep 8 | Three earlier N-central flaws added to CISA's Known Exploited Vulnerabilities (KEV) catalog: CVE-2026-18577, CVE-2026-18556, CVE-2026-86218 | [CISA KEV data](https://github.com/cisagov/kev-data) |
| Sun Nov 8 | Researcher publishes "Able2Shell" exploit chains on GitHub | [TechCrunch](https://techcrunch.com/2026/11/10/n-able-takes-its-remote-access-service-offline-after-researcher-publishes-dozens-of-zero-day-bugs/) |
| Nov 9 | N-able takes hosted N-central offline; says no active exploitation seen as of 15:15 UTC; tells customers to keep servers offline until it confirms they can be restored | [Huntress](https://www.huntress.com/blog/n-able-disables-cloud-services-following-disclosure-of-able2shell-exploit-chains), [Cybersecurity News](https://cybersecuritynews.com/n-able-takes-n-central-servers-offline/) |
| Nov 9 to 10 | watchTowr reports exploitation attempts against N-central honeypots; Defused reports probing | [Cybersecurity News](https://cybersecuritynews.com/n-able-takes-n-central-servers-offline/) |
| Nov 10 | N-able publishes seven CVE records; hotfix N-central 2026.4 HF2 reported | CVE records (below), [CSO Online](https://www.csoonline.com/article/4247028/n-able-n-central-gets-emergency-fix-two-days-after-33-exploits-published.html) |

## Confirmed vs not confirmed

| Claim | Status |
|---|---|
| Hosted N-central taken offline by N-able | **Confirmed** by N-able's status page, as quoted by TechCrunch |
| On-premises customers told to take servers offline | **Confirmed**: N-able guidance reported by Huntress, TechCrunch and CSO Online |
| Seven CVEs, affected versions before 26.4.1 | **Confirmed** in N-able's own CVE records |
| 33 vulnerabilities in four chains | **Researcher's count**, as summarised by Huntress; N-able has not said how many it reproduced (CSO Online) |
| Exploitation of customer environments | **Not confirmed**: N-able says it has no evidence of successful exploitation |
| Exploitation attempts against internet-facing N-central | **Reported** by watchTowr (honeypots) and Defused (probing), via Cybersecurity News |
| Hosted service restored | **Not confirmed** by us at the time of writing |

### Why the researcher published

TechCrunch reports the researcher told BleepingComputer he released the exploits because N-able allegedly failed to patch flaws he had reported in a different product. That is his account; we have not seen N-able respond to it.

## The seven CVEs

All seven records were published on November 10, 2026 by N-able as the CVE Numbering Authority, with CVSS v4.0 scores from N-able. We read them from the [CVE Program's cvelistV5 repository](https://github.com/CVEProject/cvelistV5).

| CVE | Title (as published) | CWE | CVSS v4 | Privileges required |
|---|---|---|---|---|
| CVE-2026-125883 | Multiple XXE Vulnerabilities | CWE-611 | 9.3 Critical | None |
| CVE-2026-125881 | Schema-hint SSRF via service import schema validation | CWE-918 | 9.3 Critical | None |
| CVE-2026-125878 | Multiple OGNL Injection vulnerabilities | CWE-79 | 8.7 High | Low |
| CVE-2026-125879 | Local privilege escalation to root via nable-writable syslog-ng config | CWE-266 | 8.6 High | High |
| CVE-2026-125882 | RCE via file repository upload path traversal | CWE-23 | 8.6 High | High |
| CVE-2026-91000 | Insecure IPC Channels lead to local privilege escalation | CWE-306 | 8.4 High | Low (local) |
| CVE-2026-125880 | Stored XSS via MMS3 patch metadata (admin context) | CWE-644 | 8.3 High | High |

Two details worth noticing if you automate on CVE data:

- Six records say "before **26.4.1**"; CVE-2026-91000 says "before **2026.4.1**", both with `versionType` `custom`. The product's own builds are named like 2026.4.0.31, and the hotfix is reported as "2026.4 HF2". A naive version comparison can mis-handle that mix; our guide to [CVE affected versions, lessThan and versionType](/posts/cve-affected-versions-lessthan-defaultstatus-versiontype/) explains why `custom` ranges need a human check.
- CVE-2026-125878 is titled OGNL injection but carries CWE-79 (cross-site scripting). That is how N-able filed it; it may be corrected later.

None of the seven is in CISA's KEV catalog as of catalog version 2026.11.10 (released November 10, 19:03 UTC). Five older N-central CVEs are, the three from 2026 listed above plus CVE-2025-8875 and CVE-2025-8876. If you watch the feed, our [KEV JSON field guide](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/) shows how to match it against your inventory.

## How the attack works (as far as sources say)

Huntress describes four chains: three end in remote code execution on the N-central server and one escalates to root. Cybersecurity News notes one public proof of concept chains an XXE flaw into unauthenticated remote code execution. The CVE records confirm two flaws exploitable over the network with no privileges (XXE and SSRF, both 9.3) and two local paths to root (syslog-ng config and insecure IPC).

The exposure matters because of what N-central does. An attacker who controls the server can use it as designed: open remote sessions, deploy scripts and create administrator accounts across managed endpoints. Huntress's guidance focuses on exactly those downstream actions.

## What to check in your environment

From Huntress, N-able's guidance as reported, and the CVE records:

1. **On-premises N-central: keep it offline until you can patch.** Then apply the hotfix and, per CSO Online, upgrade Agents and Probes as well, or they will lose compatibility with the server.
2. **Review authentication from November 8 onward.** Huntress recommends checking login and authentication activity for unauthorized access, and involving incident response if you find any.
3. **Look downstream.** Anomalous remote access sessions, newly deployed scripts, and new administrator accounts on N-central and on managed endpoints.
4. **Check exposure.** If your N-central console was reachable from the internet between November 8 and patching, treat the probing reported by watchTowr and Defused as relevant to you.
5. **Hosted customers:** follow N-able's status page; you cannot patch the hosted service yourself. Plan for how you will reach managed endpoints without your RMM during the outage.

For a broader take on deciding what to patch first when several signals compete, see our [vulnerability prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/). Here the decision is easier than most: a public exploit, unauthenticated network flaws and a tool with administrative reach over every managed machine.

## What is not known yet

- Whether any customer environment was compromised. N-able's statement is "no evidence", and it has not said what logging that conclusion rests on.
- How many of the 33 published issues the hotfix addresses; seven CVEs were assigned.
- When hosted N-central will be fully restored.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Hosted N-central offline; N-able status page wording; "no evidence of successful exploitation"; on-prem customers told to go offline | [TechCrunch, Nov 10](https://techcrunch.com/2026/11/10/n-able-takes-its-remote-access-service-offline-after-researcher-publishes-dozens-of-zero-day-bugs/) | Verified (N-able status page quoted; we could not load the page directly) |
| 33 vulnerabilities, four chains, build 2026.4.0.31, no active exploitation as of Nov 9 15:15 UTC, review guidance | [Huntress, Nov 9](https://www.huntress.com/blog/n-able-disables-cloud-services-following-disclosure-of-able2shell-exploit-chains) | Verified; count is the researcher's |
| Hotfix 2026.4 HF2; agents and probes must be upgraded; N-able has not confirmed how many flaws it reproduced | [CSO Online, Nov 10](https://www.csoonline.com/article/4247028/n-able-n-central-gets-emergency-fix-two-days-after-33-exploits-published.html) | Qualified: trade press, not an N-able document we could read |
| watchTowr honeypot exploitation attempts; Defused probing | [Cybersecurity News, Nov 10](https://cybersecuritynews.com/n-able-takes-n-central-servers-offline/) | Qualified: secondary report of vendor statements |
| Seven CVEs, titles, CWEs, CVSS v4, affected ranges | N-able CVE records in [cvelistV5](https://github.com/CVEProject/cvelistV5), e.g. [CVE-2026-125883](https://www.cve.org/CVERecord?id=CVE-2026-125883) | Verified |
| Older N-central KEV entries; new CVEs not in KEV | [CISA KEV catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog), version 2026.11.10 | Verified |
