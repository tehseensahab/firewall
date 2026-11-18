# Editorial log 2026-11-18

Run: scheduled, unattended. GSC quick fixes already done (2026-11-02 log), skipped. Hub exists (vulnerability-prioritization-workflow-cve-record-to-patch-ticket); Article A links to it.
News trial: Equinor cyberattack (Nov 17 statement) | chosen: well-known energy brand, <24h old, Norway at NSM risk level HIGH, IT/OT lesson | primary: equinor.com/news/20261711-equinor-detected-cyber-attack.

## Article A: kev-duedate-days-after-dateadded-3-14-21-day-deadlines (John Marshall, security-operations)
Data: KEV 2026.11.17 (1,782 entries, released 2026-11-17T17:53Z), kev-data git history (345 commits since 2025-01-27), 165 cvelistV5 records for KEV entries added >= 2026-06-10.
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| dueDate / forensicTriage schema descriptions (verbatim) | kev-data known_exploited_vulnerabilities_schema.json | 2026-11-18 | VERIFIED | schema |
| Gap counts per year (table) | kev JSON + kev_due.py | 2026.11.17 | VERIFIED (recomputed) | full catalog |
| 2021: 179 pre-2021 CVEs at 181d, 11 at 182d; 110 2021-CVEs at 14d | kev JSON | 2026.11.17 | VERIFIED | entries added 2021 |
| first 21d 2022-03-03; last 21d 2026-03-05; last 6-month 2022-03-07; last 2022 14d 2022-06-08 | kev JSON | | VERIFIED | |
| first 3d 2026-01-27 (CVE-2026-24858 Fortinet); first 14d of 2026 regime 2026-03-09 | kev JSON | | VERIFIED | |
| Since 2026-06-10: 3d/Yes 105, 3d/No 23, 14d/No 37 | kev JSON | | VERIFIED | 165 entries |
| SSVC TI cross-tab (104/1, 13/10, 19/18) | cvelistV5 CISA-ADP ssvc options | 2026-11-18 | VERIFIED | |
| Weekend due dates 26 Sat + 23 Sun, 44 Fri | kev JSON | | VERIFIED | |
| forensicTriage first in catalog 2026.09.01: 38 Yes, 1,649 No | kev-data git commit 2d5aab3 | 2026-09-01 | VERIFIED | |
| 23 dueDate edits; table rows | duehist.py replay of kev-data | 2025-01-27..2026-11-17 | VERIFIED | |
| BOD 22-01 6 months / two weeks / grave-risk adjustment (verbatim) | cisa.gov/binding-operational-directive-22-01 (WebFetch) | | VERIFIED | |
| BOD 26-04 published June 10, 2026 | our BOD 26-04 article; runZero post dated 2026-06-10 | | QUALIFIED (cisa.gov 26-04 pages client_error today) | |
| Reason for 21-day default / 2026 change | none found | | NOT VERIFIED -> stated as data-only, no cause claimed | |

## Article B: equinor-cyberattack-it-systems-what-we-know (Craig Leslie, security-operations) [news]
| Claim | Primary source | Date | Status |
|---|---|---|---|
| "ongoing cyber-attack against certain IT systems"; resources mobilised; no indications data stolen; ops/production unaffected; authorities informed; updates to follow; 18:55 CET, modified 19:40 | equinor.com statement | 2026-11-17 | VERIFIED |
| Reuters report, no named spokesperson | The Star (Reuters, Anna Ringstrom), Global Banking & Finance (Reuters) | 2026-11-17/18 | VERIFIED |
| No attacker identity / ransomware detail | IBTimes SG + Equinor statement | 2026-11-18 | VERIFIED (as of date) |
| NSM risk level HIGH, 5-step scale, Moderate normal, reasons | UiO IT notice (2026-11-03), DNV (2026-10-28) | | QUALIFIED (NSM page not fetched) |
| "state-majority" ownership; precautionary shutdown generalisation | none fetched | | REMOVED |
| Gas-market impact, links to other Norwegian incidents (Cryptopolitan/Aftenposten) | secondary only | | Left out; noted as unconfirmed |

## Skipped / failures
- cisa.gov BOD 26-04 page, implementation guidance, 2026-10-30 KEV alert: WebFetch client_error. bleepingcomputer.com/news/... client_error. upstreamonline.com robots_disallowed.

## Next-session candidates
1. [cluster] KEV dueDate change alerts: diff kev-data versions for dueDate/forensicTriage edits and page on them | guide | follows today's finding (23 edits incl. retroactive) | kev-data git history, schema | must not repeat kev-duedate (today), cve-exploitation-alerts, kev-in-cve-records
2. [cluster] SSVC Exploitation poc in CISA-ADP: what moves a CVE to poc and how many reach KEV | guide | 292 records gained poc in 30 days (11-16 diff) | cvelistV5 tag diffs, CERTCC/SSVC exploitation.py, vulnrichment README | must not repeat cve-exploitation-alerts, cisa-vulnrichment, kev-in-cve-records
3. [spec] OpenVEX spec v0.2.0 fields tools ignore: status_notes, action_statement_timestamp, last_updated, version | guide | raw openvex/spec OPENVEX-SPEC.md, go-vex statement.go, trivy pkg/vex | must not repeat vex-explained, openvex-products-subcomponents, vexctl, cyclonedx-vex
News (Article B, trial ends 2026-11-22): fresh 72h story; Equinor follow-up only if Equinor publishes scope/cause.
