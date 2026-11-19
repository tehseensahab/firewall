# Editorial log 2026-11-19

Quick fixes: already done (2026-11-02 log). DAILY.md hacking-news trial active (run 12 of 15).

## Article A: Public PoC CVEs: Pull All 47,926 SSVC poc Records
Slug: public-poc-cves-cisa-adp-ssvc-exploitation-poc-epss | security-operations | Craig Leslie | [cluster]
Data: cvelistV5 release 2026-11-18_all_CVEs_at_midnight.zip.zip (the 2026-11-19 asset 404'd, 9-byte body), KEV 2026.11.18 (1,786), EPSS 2026-11-18 model v2026.06.15.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Exploitation 1.0.0 PoC / 1.1.0 Public PoC / Active / None definitions (verbatim) | CERTCC/SSVC src/ssvc/decision_points/ssvc/exploitation.py (VERSIONS, LATEST = 1.1.0) | main 2026-11-19 | VERIFIED | |
| README: poc "indicating there was a public proof-of-concept available at the time of analysis"; CVE-2024-25522 options | cisagov/vulnrichment README | develop 2026-11-19 | VERIFIED | |
| 222,849 CISA-ADP SSVC blocks; none 173,136 / poc 47,926 / active 1,787; all version "2.0.3" | corpus count (scripts/ssvc.py) | 2026-11-18 00:00Z | VERIFIED | |
| KEV 1,786: 1,782 active, 3 none, 1 poc; all 4 non-active dateAdded 2026-11-18 | KEV join | 2026.11.18 | VERIFIED | |
| 5 active not in KEV (CVE-2023-24932, CVE-2022-21894, CVE-2021-30120, CVE-2021-30119, CVE-2021-21983) | corpus + KEV; raw record check for first two | | VERIFIED | |
| EPSS medians/thresholds per value and per poc slice; 17,558 CVEs EPSS>=0.1 of which 12,953 no SSVC | EPSS join | 2026-11-18 | VERIFIED | |
| Top poc/yes/total EPSS: CVE-2023-27372 0.99682, CVE-2025-1974 0.994; 394 poc/yes/total >=0.1 not in KEV; 308 poc >=0.5 | poc.csv + snippet run | | VERIFIED | product names deliberately not stated |
| Script runtime ~37 s, 47,926 rows, peak RSS ~2.2 GB | run in sandbox | | VERIFIED | |
| EPSS = exploitation in the wild next 30 days | empiricalsec/epss_scores README | | VERIFIED | |
| Coverage mostly 2024+ | SSVC timestamp years (2024: 58,851; 2025: 66,819; 2026: 96,672; earlier 507) | | QUALIFIED ("mostly") | |
Removed: none. Not claimed: which Exploitation version CISA applies (record does not say).

## Article B: Microsoft agent-framework PyPI Compromise: What We Know [news]
Slug: microsoft-agent-framework-pypi-compromise-1-26-1-1-26-2-what-we-know | ai-security | John Marshall
News trial: Microsoft agent-framework 1.26.1/1.26.2 PyPI stealer (Nov 17). Chosen: big brand, ~190k monthly downloads, direct engineer action (CI/OIDC secrets). Primary: PyPI JSON API (release list) + Python site docs; core event from Wiz, Chainguard, SecurityWeek (independent). No Microsoft blog/advisory found; maintainer GitHub post known only via SecurityWeek. BleepingComputer article SERVER_ERROR x2.

| Claim | Source | Status |
|---|---|---|
| 1.26.1/1.26.2 malicious, published Nov 17, gone ~21:30 UTC | Wiz; Chainguard times 20:35:20 / 21:08:39 | QUALIFIED (researchers, consistent) |
| PyPI latest 1.26.0 (uploads 2026-11-12T18:24:57/18:25:37Z), 1.26.1/1.26.2 absent | pypi.org/pypi/agent-framework/json via curl 2026-11-19 ~04:58Z | VERIFIED |
| ESRP client cert + key "appears to have compromised" | Wiz | QUALIFIED, in Not confirmed |
| Method unknown; vibiret/SafeDep account unconfirmed; ~190,000 downloads/month; maintainer confirmation | SecurityWeek 2026-11-18 | QUALIFIED |
| .pth file names, _AF_TEL, targets, OIDC audiences, IOCs, hashes, 3 exfiltrations of 50-request cap, 24h token validity | Wiz | QUALIFIED |
| 12 (Wiz) vs 9 (Chainguard) Azure resource types | both | disagreement stated |
| .pth import lines executed with exec(); 3.15 deprecation | cpython Doc/library/site.rst | VERIFIED |
| find/grep commands | tested on mock tree in sandbox | VERIFIED (mock only, stated) |

## Next-session candidates
1. [cluster] SSVC Exploitation poc to active: how long CVEs sit at poc before KEV (needs snapshot history: cvelistV5 tags or vulnrichment git log) | guide | follows today's poc post, which says current data cannot show it | cvelistV5 tag diffs, cisagov/vulnrichment history, kev-data | must not repeat public-poc-cves, cve-exploitation-alerts, kev-time-to-listing
2. [spec] OpenVEX spec v0.2.0 fields tools ignore: status_notes, action_statement_timestamp, last_updated, version | guide | raw openvex/spec OPENVEX-SPEC.md, go-vex statement.go, trivy pkg/vex | must not repeat vex-explained, openvex-products-subcomponents, vexctl, cyclonedx-vex
3. [cluster] KEV dueDate change alerts: diff kev-data versions for dueDate/forensicTriage edits | guide | kev-data git history | must not repeat kev-duedate, cve-exploitation-alerts
News (Article B, trial ends 2026-11-22): fresh 72h story; agent-framework follow-up only if Microsoft publishes a root cause or advisory.
