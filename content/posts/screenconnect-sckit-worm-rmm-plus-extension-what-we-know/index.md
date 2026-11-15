+++
title = "ScreenConnect SCKit Worm via RMM+ Extension: What We Know"
date = 2026-11-15T04:55:00Z
tags = ["hacking news", "screenconnect", "connectwise", "rmm", "msp security", "sckit", "incident response"]
categories = ["security-operations"]
summary = "Huntress reports rogue ScreenConnect clients and an SCKit toolkit on 288 hosts at 48 organizations on November 11, 2026 and 205 more hosts at 41 organizations on November 13. ConnectWise disabled five third-party extensions, including RMM+, across about 400 partner environments. What is confirmed, what is not, and what to check."
description = "Huntress counted 288 hosts in 48 orgs, then 205 in 41, hit by rogue ScreenConnect clients tied to the RMM+ extension. Confirmed facts, timeline and checks."
author = "John Marshall"
imageAlt = "Close-up of a wiring frame densely packed with red, yellow, green and white wires on terminal pins"
imageCredit = "Photo by [Ronald Crow](https://unsplash.com/photos/a-rack-of-wires-and-wires-in-a-room-Fps_LQw429c) on Unsplash"
takeaways = [
  "Huntress says rogue ScreenConnect clients and a toolkit it calls SCKit reached at least 288 managed endpoints across 48 organizations in about 90 minutes on November 11, 2026, and a second wave hit 205 hosts across 41 organizations on November 13.",
  "ConnectWise said it found no evidence of a compromise of its infrastructure or a vulnerability in ScreenConnect itself, and disabled five independently developed extensions (Labtech Plus, RMM Plus, RMM+, RMM Plus Password Link, RMM+ Password Link) across about 400 partner environments.",
  "Huntress describes the link to RMM+ as suggestive, not confirmed: versions 1.0.31 and 1.0.32 accept a blank access key when an administrator never set one. ConnectWise had not identified the initial access vector at the time of its advisory.",
  "If you run ScreenConnect: disable the RMM+-family extensions, confirm technician clients run 26.6.5 or later (the CVE-2026-84869 fix), and do not triage suspect hosts through ScreenConnect itself.",
  "No actor has been named by Huntress or ConnectWise."
]

[[faq]]
q = "What is the ScreenConnect SCKit attack?"
a = "A campaign Huntress first observed on November 11, 2026 in which rogue ScreenConnect clients were silently installed on managed endpoints, followed by a roughly 16-file toolkit Huntress calls SCKit. Huntress counted 288 hosts across 48 organizations in the first wave and 205 hosts across 41 organizations in a second wave on November 13."

[[faq]]
q = "Is ScreenConnect itself vulnerable?"
a = "ConnectWise said it found no evidence of a compromise of ConnectWise infrastructure or a vulnerability in ScreenConnect itself, and that its initial assessment points to abuse of independent third-party extensions. Separately, it told partners to confirm technician clients run 26.6.5 or later, the release that fixes CVE-2026-84869, a client-side file-transfer flaw that CISA added to KEV on September 11, 2026."

[[faq]]
q = "Which ScreenConnect extensions did ConnectWise disable?"
a = "Labtech Plus, RMM Plus, RMM+, RMM Plus Password Link and RMM+ Password Link, across about 400 partner environments where it could act remotely. It asked self-hosted (on-premises) partners to disable them as well. ConnectWise noted the roughly 400 environments were flagged for having the extensions installed, not for confirmed compromise."

[[faq]]
q = "Who is behind the SCKit campaign?"
a = "Neither Huntress nor ConnectWise has attributed it. Huntress notes the attacker participant name 'Addmin' in session data but does not link it to a known group."
+++

**What happened:** On November 11, 2026, security firm Huntress saw rogue ScreenConnect clients appear on customer endpoints at 48 organizations within about 90 minutes, followed by a toolkit it calls **SCKit**. A second wave on November 13 hit 205 more hosts across 41 organizations. ConnectWise, which makes ScreenConnect, says it has found no compromise of its own infrastructure and no flaw in ScreenConnect itself, and has disabled five third-party extensions, including one called **RMM+**, across about 400 partner environments. How the attackers first got in is not yet confirmed.

ScreenConnect is remote-support software widely used by managed service providers (MSPs) and IT teams, so a single compromised console can reach every machine it manages. It is the second incident this week involving MSP remote-management software, after the [N-able N-central Able2Shell zero-days](/posts/n-able-n-central-able2shell-zero-days-offline-what-we-know/).

## Timeline

Times are UTC as given by [Huntress](https://www.huntress.com/blog/sckit-worm-rogue-screenconnect) unless noted.

| Date | Event | Source |
|---|---|---|
| Aug-Sep 2026 | Earlier rogue ScreenConnect "worm-like" activity; Huntress Rapid Response | [Huntress (Sept post)](https://huntress.com/blog/rogue-screenconnect-installations) |
| Sep 8, 2026 | ConnectWise publishes CVE-2026-84869 (CVSS 9.9), fixed in ScreenConnect 26.6.5 | CVE record |
| Sep 11, 2026 | CISA adds CVE-2026-84869 to KEV | [KEV catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) |
| Nov 11, ~17:47 | Huntress first observes suspicious activity; all 288 hosts hit within about 90 minutes | Huntress |
| Nov 11, 22:45 | ConnectWise publishes its advisory | Huntress |
| By Nov 12 | ConnectWise disables five RMM+-family extensions across about 400 partner environments | Huntress, [CyberScoop](https://cyberscoop.com/connectwise-screenconnect-sckit-attack/), [The Register](https://www.theregister.com/security/2026/11/12/hackers-exploiting-screenconnect-plugin-flaw-to-spread-malware-across-hundreds-of-pcs/5309361) |
| Nov 13, 16:12 | Second wave detected: 205 hosts across 41 organizations | Huntress (update 5:30pm ET) |

## Confirmed vs not confirmed

| Claim | Status | Who says so |
|---|---|---|
| 288 hosts across 48 organizations hit on Nov 11 | Reported | Huntress, from its own customer telemetry |
| 205 hosts across 41 organizations hit on Nov 13 | Reported | Huntress |
| No compromise of ConnectWise infrastructure or vulnerability in ScreenConnect itself | Vendor statement | ConnectWise, quoted by CyberScoop and The Register |
| Five third-party extensions disabled across about 400 environments | Vendor action | ConnectWise, via Huntress, CyberScoop, The Register |
| The ~400 environments are compromised | **No.** ConnectWise says they were flagged for having the extensions, not for confirmed compromise | The Register |
| RMM+ was the initial access vector | **Not confirmed.** Huntress calls the link suggestive; ConnectWise had "not yet identified an initial access vector and full scope" | Huntress |
| Spread from technician workstations to other customers | **Not observed succeeding.** Huntress reconstructed the capability but did not see it work in the logs it checked | Huntress |
| Who did it | **Not attributed** | Huntress, CyberScoop |

Huntress's counts come from organizations that use Huntress. The total number of affected organizations is not known publicly, and the two waves' organization counts should not be added together, since the same organization could appear in both.

## How the attack worked, as far as sources say

**Suspected entry point.** Huntress says the activity "seems to be related" to RMM+ versions 1.0.31 and 1.0.32. The Register, reporting the same finding, says "installations without a configured access key will accept a blank one." Per Huntress, RMM+ operates outside ScreenConnect's user accounts, roles and MFA, and it found no matching login activity in incident logs; the commands appeared in logs linked to RMM+. Huntress also says most RMM+ installations it saw were legitimate. The extension's developer has not been named in any of the reports we read.

**What was installed.** According to Huntress:

- A rogue ScreenConnect client, installed silently by a batch-script dropper.
- SCKit, about 16 files delivered as an encrypted package with keys tied to the victim machine's UUID.
- "RelayTrap" components that take over the legitimate client's connection slot, plus a `TrapWatch` scheduled task running as SYSTEM.
- Defender exclusions, AppLocker/SRP rules and, in one incident, a service posing as "Windows Update Agent".
- A `netsh portproxy` rule, a modified hosts file, and a tool that steals browser session cookies, including ScreenConnect's `.aspxauth` cookie, which Huntress describes as a way to reach further sessions.

Huntress also warns that isolating a host does not remove this persistence, and that infected systems were reinfected soon after isolation ended.

**How it relates to CVE-2026-84869.** The September flaw lets files be "transferred and executed through an active remote session without authorization or Host confirmation in certain circumstances," per the [CVE record](https://github.com/CVEProject/cvelistV5/blob/main/cves/2026/84xxx/CVE-2026-84869.json), and affects "All versions prior to 26.6.5". ConnectWise's November guidance tells partners to confirm every technician client runs 26.6.5 or later. Neither ConnectWise nor Huntress says the November campaign exploited this CVE, so treat the upgrade as hardening against the spread path, not as the root cause.

## What to check in your environment

If you run ScreenConnect, cloud or on-premises:

1. **Extensions.** Check for Labtech Plus, RMM Plus, RMM+, RMM Plus Password Link and RMM+ Password Link. ConnectWise disabled them on hosted instances; on-premises partners must disable them themselves.
2. **Client versions.** Confirm technician clients are on 26.6.5 or later.
3. **Do not triage through ScreenConnect.** Huntress advises against connecting to a suspect host through ScreenConnect and recommends WinRM or another out-of-band tool. If a technician already connected to a suspect host, investigate that technician's workstation from a clean device.
4. **Hunt for the artefacts Huntress lists:** an unfamiliar ScreenConnect client alongside the legitimate one, a `TrapWatch` scheduled task, `C:\ProgramData\RelayTrap\`, toolkit files in `%TEMP%`, a `RelayTrapLiteAlert` Run value, unexpected `netsh interface portproxy` rules, and hosts-file changes. Huntress publishes hashes and network indicators in its post.
5. **Sessions and credentials.** Terminate active ScreenConnect web sessions, rotate credentials, and revoke browser and identity-provider sessions.
6. **Audit history.** Review Run Command and Toolbox history and instance audit logs for activity with no matching user login.

For engineers outside the MSP world, the transferable lesson is about plugins: any extension that runs commands with its own authentication path is a second front door to your remote-access tool. Inventory extensions with the same rigour as user accounts, and require that their access keys are set rather than defaulting to empty. For tracking the ScreenConnect CVEs already in KEV, see [how to match the CISA KEV JSON feed against a scanner export](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/).

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Counts, timeline, RMM+ versions, toolkit components, recommendations | [Huntress, Nov 11 2026, updated Nov 13](https://www.huntress.com/blog/sckit-worm-rogue-screenconnect) | Verified (Huntress telemetry) |
| ConnectWise found no infrastructure compromise or ScreenConnect vulnerability | [CyberScoop, Nov 12 2026](https://cyberscoop.com/connectwise-screenconnect-sckit-attack/), [The Register, Nov 12 2026](https://www.theregister.com/security/2026/11/12/hackers-exploiting-screenconnect-plugin-flaw-to-spread-malware-across-hundreds-of-pcs/5309361) | Verified (vendor statement) |
| ~400 environments are an exposure count, not compromise | The Register | Qualified (vendor statement as reported) |
| CVE-2026-84869 description, CVSS 9.9, fixed in 26.6.5 | [CVE record](https://github.com/CVEProject/cvelistV5/blob/main/cves/2026/84xxx/CVE-2026-84869.json) | Verified |
| CVE-2026-84869 added to KEV on Sep 11, 2026 | [CISA KEV](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) (kev-data JSON) | Verified |
| No attribution | Huntress, CyberScoop | Verified |
