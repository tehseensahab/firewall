# Editorial log 2026-11-17

Guard note: content/posts/shadow-ai-how-employees-accidentally-create-security-gaps-with-ai-tools is dated 2026-11-17T09:00Z but is a pre-scheduled post added 2026-11-02, not a run output; run proceeded.
GSC quick fixes: already done (2026-11-02 log); skipped.
News trial: Coles cyber incident (ASX disclosure Mon Nov 16). Chosen: major Australian retail brand, disclosure <24h old, no prior coverage. Primary ASX PDF not returned by WebSearch; confirmed via Forbes Australia, Information Age (ACS), Inside Retail, teiss (independent outlets). Trial runs to 2026-11-22.

## Article A: kev-in-cve-records-cisa-adp-kev-block-full-catalog-audit (Craig Leslie, security-operations)
Data: kev-data catalogVersion 2026.11.13 (1,781); cvelistV5 main a683955 (fetched 2026-11-17 ~04:53Z); release cve_2026-11-17_0000Z midnight zip (426,227 records); kev-data git history (344 commits from 2025-01-27).

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 1,781 entries, dateAdded 2021-11-03..2026-11-13; by year 311/555/187/186/245/297 | kev.json computed | 2026.11.13 | VERIFIED | catalog |
| 1,777 match, 2 missing (CVE-2026-48356, CVE-2026-111497), 2 date mismatch (PaperCut 81578/82078: 08-31 vs 08-28) | audit_kev_blocks.py output (run twice, incl. the bash fetch snippet) | 2026-11-17 | VERIFIED | records at main |
| All 1,781 have CISA-ADP SSVC Exploitation active | an.py Counter (1,779 kev) + direct read of 2 missing | 2026-11-17 | VERIFIED | |
| 0 kev blocks for non-catalog CVEs in corpus | scan.py over midnight zip | 2026-11-17 | VERIFIED | |
| README: "For those CVEs that are on the KEV, the CISA ADP will add a KEV block ... For those that aren't, no update will occur." | raw cisagov/vulnrichment develop README L79 | current | VERIFIED | |
| Removals: CVE-2025-4664 (in 2025.05.15, gone 2025.06.09), CVE-2025-6264 (2025.10.14 -> 2025.10.22), CVE-2026-69836 (17:28 -> 18:42 UTC 2026-08-21); CVE-2026-1281 dropped 19:14 back 20:41 2026-01-29 | kev-data git history replay | | VERIFIED (reasons NOT VERIFIED, stated as unknown) | since 2025-01-27 |
| Removed CVEs: no kev block, SSVC Exploitation none | midnight zip records | 2026-11-17 | VERIFIED | |
| PaperCut record kev dateAdded equals SSVC timestamp 2026-08-28 | records | | VERIFIED | |
| fetch ~11 s, reverse pass ~20 s | timed runs here | | QUALIFIED (this sandbox) | |

## Article B: coles-cyber-security-incident-what-we-know (John Marshall, security-operations, [news])
| Claim | Source | Date | Status |
|---|---|---|---|
| ASX disclosure Monday Nov 16; "investigating a cyber security incident" | Information Age; Forbes AU; Inside Retail | 2026-11-16/17 | VERIFIED (2+ outlets; ASX PDF not retrieved) |
| "Operations continue and customers are able to shop as normal..." | Forbes AU, Inside Retail | 11-16 | VERIFIED |
| "working with global cyber security experts to contain and secure the Coles IT environment" | Inside Retail | 11-16 | VERIFIED |
| ACSC; "engage with appropriate agencies and regulators..." | Information Age, Forbes AU | | VERIFIED |
| No evidence so far customer, team or supplier data compromised or removed | all three | | VERIFIED (Coles claim) |
| Apology quote | Inside Retail, Information Age | | VERIFIED |
| Liquorland click-and-collect "small number"; Reddit internal problems; Friday Microsoft email outage | Information Age only | 11-17 | QUALIFIED (attributed, labelled not linked/unverified) |
| No threat-actor claim | reporting reviewed | | QUALIFIED (as of review) |
Removed: nothing material; avoided Coles size/market-share claims (not sourced).

## Skipped / issues
- konbriefing.com: robots_disallowed. thenewdaily.com.au, computerweekly.com: WebFetch client_error. cyberdaily.au URL with token: proxy rejected (URL too long).
- No approval prompts hit.

## Next-session candidates
1. [cluster] SSVC Exploitation poc in CISA-ADP: what moves a CVE to poc and how many reach KEV | guide | engineers ask whether poc should page; 292 changed records gained poc in 30 days (11-16 diff) | cvelistV5 tag diffs, CERTCC/SSVC exploitation.py, vulnrichment README, kev-data | must not repeat cve-exploitation-alerts, cisa-vulnrichment, kev-in-cve-records (today)
2. [spec] OpenVEX spec v0.2.0 fields tools ignore: status_notes, action_statement_timestamp, last_updated, version | guide | follows vexctl post | raw openvex/spec OPENVEX-SPEC.md, go-vex statement.go, trivy pkg/vex | must not repeat vex-explained, openvex-products-subcomponents, vexctl, cyclonedx-vex
3. [cluster] KEV dueDate vs dateAdded: BOD 26-04 due-date intervals by catalog year and vendor | guide | due-date math is what federal-adjacent teams search; kev-data history shows date fields | kev-data JSON + git history, cisa.gov BOD 26-04 page via WebSearch | must not repeat cisa-bod-26-04-explained, kev-time-to-listing, kev-in-cve-records
News (Article B, trial ends 2026-11-22): fresh 72h story; Coles follow-up only if Coles issues a further ASX update with scope/data findings.
Live QA: both pages 200 with h1, opening paragraph and cover image (curl, after cover commit 10bbee2).
