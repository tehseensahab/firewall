# Editorial log 2026-11-10

Run: scheduled. DAILY.md hacking-news trial active (run 3 of 15). GSC quick fixes already done (2026-11-02 log), skipped.

## Article A [cluster]: KEV knownRansomwareCampaignUse: 114 Unknown-to-Known Flips
Slug: kev-knownransomwarecampaignuse-unknown-to-known-flips | security-operations | Craig Leslie | primary kw: kev known ransomware campaign use
Method: full clone of cisagov/kev-data (default branch develop), replayed all 341 commits touching known_exploited_vulnerabilities.json (2025-01-27 to 2026-11-10 03:13Z, catalog 2026.11.09) with python; 1 commit (15200f9, 2025-02-25) unparseable, skipped. Script tested on 2026.08.11 -> 2026.08.14 snapshots.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Known/Unknown definitions (verbatim schema description) | kev-data known_exploited_vulnerabilities_schema.json | schema commit 2026-09-17 | VERIFIED | field meaning |
| 114 flips, all Unknown->Known, 0 reversals | kev-data git replay | 2026-11-10 | VERIFIED (computed) | 2025-01-27..2026-11-10 |
| 59 in 2025, 55 in 2026; last flip CVE-2026-63077 on 2026-09-23 (48 days) | replay | | VERIFIED | |
| Batches: 14 on 2025-05-12, 10 on 2026-08-14 | replay | | VERIFIED | |
| Vendors: Microsoft 33, Ivanti 6, Fortinet 5, SonicWall 5, Oracle 5 | replay | | VERIFIED | |
| 524 new entries in window, 521 Unknown at listing, 50 later flipped; lag median 20, <=7:17, <=30:29, <=90:39, max 554 | replay | | VERIFIED | |
| CVE-2025-61882 lag -1 (repo 2025-10-06, dateAdded 2025-10-07) | replay | | VERIFIED | |
| 64 flips on baseline entries; all-114 median lag 352, max 1,771 (CVE-2016-7255, CVE-2019-0859) | replay | | VERIFIED | |
| Baseline 1,252 entries, 245 Known | first commit 2dd57cf | 2025-01-27 | VERIFIED | |
| Catalog 2026.11.09: 1,773 entries, 361 Known (20.4%); 289 2026 additions, 27 Known, 25 via flip | kev-data JSON + replay | 2026-11-09 | VERIFIED | |
| CVE-2025-6264 flipped then removed from catalog | replay (absent in current file) | | VERIFIED | |
| GreyNoise/Thorpe counted 59 in 2025; "no alert, no announcement"; "Just a field change in a JSON file" | theregister.com 2026/02/03 | 2026-02-03 | QUALIFIED (press; matches our 59 and Microsoft 16, max lag 1,353) | 2025 |
Removed: Register's "39% added before 2023" (our replay gives 31%; not used).

## Article B [news]: Vanderbilt BYOD Ransomware Attack: What We Know So Far
Slug: vanderbilt-university-byod-ransomware-attack-what-we-know | security-operations | John Marshall | primary kw: vanderbilt ransomware attack
News trial: Vanderbilt University device-shutdown incident (Nov 9) claimed by BYOD; chosen for mainstream reach (major US university, classes disrupted), fresh (<24h), and a pattern (3rd BYOD university claim in ~a month). Gate: two independent established outlets (FOX 17, Gizmodo) quoting Vanderbilt's own update; Vanderbilt's news page (news.vanderbilt.edu/2026/11/09/...) not returned by WebSearch, so not fetched.

| Claim | Source | Date | Status | Scope |
|---|---|---|---|---|
| Shut down devices / disconnect Wi-Fi on Nov 9 | FOX 17; Gizmodo quote "SHUT DOWN YOUR DEVICE IMMEDIATELY..." | 2026-11-09 | VERIFIED (2 outlets) | |
| 7 p.m. update quotes (Wi-Fi available, most systems restricted; working with government agencies; normal schedule) | FOX 17 verbatim | 2026-11-09 | VERIFIED (as quoted) | |
| Guidance on pop-ups, renamed files in OneDrive/Box, contact IT by phone/separate device | FOX 17 | | QUALIFIED (paraphrase via outlet) | |
| Brightspace off-limits; printed materials | FOX 17 | | VERIFIED (outlet) | |
| Vanderbilt Health unaffected | FOX 17 | | QUALIFIED (attributed) | |
| BYOD claims "Over 1 Million SSNs..." | Gizmodo quoting ransom message | | CLAIM, labelled | |
| MSU quotes, Oct 1 reset notice, 15-char passwords, 1.3M claim, BYOD emerged September | The Record | 2026-11-02 | VERIFIED (outlet quotes MSU) | |
| UNM: Oct 26 diversion, quotes "did not penetrate core systems or servers"; BYOD 36,000 systems / AD / Entra claim; decryptor + $2,500 offer | BleepingComputer | 2026-10-27 | VERIFIED / CLAIM labelled | |
| Texas HHSC BYOD claim | Gizmodo citing DataBreach.com | | NOT VERIFIED, excluded from timeline, mentioned as unconfirmed | |
News trial: Vanderbilt BYOD ransomware | fresh, high-curiosity, pattern across 3 universities | FOX 17 + Gizmodo (Vanderbilt statements quoted), The Record, BleepingComputer.

## QC
hugo --minify: zero errors, 537 pages; both posts built; no dead /posts/ links in either. Titles 58/54 chars, descriptions 156/160. Internal links: A -> hub, kev-json-feed, kev-time-to-listing, epss-kev (4, 3 cluster+hub); B -> tabletop, logging-for-incidents, today's A. Covers: Jason Leung control panel (YVSFMhXZAWw), Zsófia Hajnal lecture hall (I8PUo5Xk8DU); workflow committed cover.jpg (486bffc); imageAlt rewritten from the actual covers. Rejected covers: padlock photo (Facebook watermark + inscription), Unsplash+ padlock.
Live check: WebFetch firewallsync.com -> PROVENANCE_REQUIRED (not retried). Pushed; live not confirmed.

## Next-session candidates
1. [cluster] Alert when a CVE gains KEV or SSVC Exploitation: active by diffing CISA-ADP containers in cvelistV5 delta | guide | turns delta sync into alerts; pairs with today's flip diff | cvelistV5 deltaLog.json, cisagov/vulnrichment, CVE record ADP containers | must not repeat cvelistv5-delta, cisa-vulnrichment, cve-adp-containers, today's KEV flips post (link + hub)
2. [spec] KEV notes and cwes fields: what CISA puts in notes (vendor links, CVE.org) and how to parse them | guide | field-level follow-on to the KEV JSON guide | kev-data JSON + git history (schema commit 2026-09-17), cisa.gov/known-exploited-vulnerabilities via WebSearch | must not repeat cisa-kev-json-feed (link + hub)
3. [cluster] OpenVEX in OCI attestations: trivy --vex oci, cosign attest --type openvex | guide | VEX that travels with the image | raw trivy docs/guide/supply-chain/vex at tag, sigstore/cosign docs raw, openvex/spec | must not repeat openvex-products-subcomponents, cosign keyless
News (Article B, trial): fresh 72h story at run time; Vanderbilt follow-up if Vanderbilt confirms scope/data theft (add dated Update line to today's post).
