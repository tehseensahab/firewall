# Editorial log 2026-11-25

Run notes: hacking-news trial (DAILY.md, 2026-11-08 to 11-22) has ended; normal SEO FOCUS rules applied. Owner should review GSC for the [news] rows in INDEX.md. GSC quick fixes already done (log 2026-11-02), skipped. Timely cap: 2 timely CVE posts already this week (vCenter 11-23, Cisco Expressway 11-24), so Article B was a cluster piece.

## Topic selection
- Shortlist: (1) SSVC object registry lookup [spec]; (2) SSVC poc->active vs KEV from vulnrichment history [cluster]; (3) SAP NetWeaver KEV [timely, dropped: weekly timely cap]; (4) KEV vs ADP kev-block monitor [dropped: overlaps 11-17 audit and 11-16 diff].
- A: ssvc-object-registry-namespace-key-version-lookup (appsec, Craig Leslie). B: ssvc-exploitation-before-kev-listing-vulnrichment-history (security-operations, John Marshall). Candidate 2 reframed from "poc->active lag" (the 11-16 diff already showed active only follows KEV) to "what did the record say before listing".

## Fact-check: Article A (SSVC object registry)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Registry top keys, schemaVersion 2.0.0, generatedAt 2026-10-20T16:15:07Z | CERTCC/SSVC data/json/ssvc_object_registry.json @11e6fdf | 2026-10-20 | VERIFIED | parsed |
| 105 DP keys/148 versions; 16 tables; per-namespace counts | same, python count | 2026-10-20 | VERIFIED | |
| ID format "namespace:key:version[:value_key]" | src/ssvc/registry/base.py lookup_by_id docstring | main | VERIFIED | |
| lookup_latest picks highest semver | base.py lookup_latest | main | VERIFIED | |
| E 1.0.0 vs 1.1.0 P definitions (verbatim) | registry | | VERIFIED | |
| EXP 1.0.1 U->O; HI 3 versions; commit "Correct HI:2.0.2 value definitions to match DT_HI:1.0.0" (525ffdb 2026-09-19) | registry + git log | | VERIFIED | |
| DT_CO 2.0.3 inputs, outcome cisa:CISA:1.1.0 (T, T*, AT, AC), 36 rows | registry | | VERIFIED | |
| ADR 0012 namespace rules (quotes), accepted 2025-07-22 | docs/adr/0012-ssvc-namespaces.md | 2025-07-22 | VERIFIED | |
| T* grandfathered (quote) | SelectionList_2_0_0.schema.json | | VERIFIED | |
| Vulnrichment version semantics (quotes) | cisagov/vulnrichment README (develop) | | VERIFIED | |
| 431,850 records; 226,884 CISA-ADP SSVC blocks, all 2.0.3 / CISA Coordinator / 3 options; value counts | cvelistV5 release 2026-11-25_all_CVEs_at_midnight, python census | 2026-11-25 | VERIFIED | snapshot |
| CVE-2026-76466 ADP block content | raw cvelistV5 record | 2026-10-21 timestamp | VERIFIED | |
| Script output (Attend for MWI L, Act for MWI H; validation messages) | run of post's code, extracted and diffed against tested file | 2026-11-25 | VERIFIED | |
| ADP version 2.0.3 == registry cisa:DT_CO:2.0.3 | inference | | QUALIFIED (stated as inference) | |

## Fact-check: Article B (SSVC before KEV)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| KEV catalog 2026.11.24, 1,795 entries; 139 added 08-01..11-24 (31/43/36/29) | cisagov/kev-data main | 2026-11-24 | VERIFIED | |
| vulnrichment develop 13,072 commits, head 0a75438 2026-11-24T19:17:34Z | git clone | 2026-11-25 | VERIFIED | |
| 138 with file; CVE-2026-132165 none; 1,083 versions | git log per path | | VERIFIED | |
| Pre-listing: none 75, unscored 54, poc 8, active 1 | lag.py, rerun from post code (same output) | | VERIFIED | |
| Unscored first commit offsets: 0d 42, 1d 6, 2-4d 6 | python | | VERIFIED | |
| none-group age: <=7 26, 8-30 23, 31-365 21, >365 5 | python | | VERIFIED | |
| Lag: -1 1, 0 94, 1 27, 2 9, 3+ 5 (3,3,4,4,20), never 2 | python | | VERIFIED | |
| Named CVEs vendor/product | KEV fields | | VERIFIED | |
| Metabase active commit 2026-08-10T20:16Z | git log | | VERIFIED | |
| 48,525 poc blocks | cvelistV5 census (A) | 2026-11-25 | VERIFIED | |
| Commit time ~ publication of decision | interpretation | | QUALIFIED | |
Removed in edit: an unsupported "Ivanti-style batch" characterization of the 3-4 day cases (replaced with the named CVEs).

## Internal links
A -> vulnrichment SSVC guide, BOD 26-04 table, CSAF 2.1 metrics, Cisco CVE-2026-76466, hub workflow. B -> cve-exploitation-alerts diff, public-poc census, KEV JSON feed, vulnrichment SSVC guide, hub workflow, A. Dead-link check: 0 dead.

## Images
A: Unsplash fCnYbTnJASs (photo 1769092992555-42c231deff34, Ilya Semenov, card catalogue drawers). B: Unsplash 2L6a8s2QMnc (photo 1660886072169-8e66caec4d0c, iSawRed; page titled "a close-up of a stopwatch" but image is an alarm bell; alt describes the bell). Both previewed, Unsplash License confirmed via web-fetch agent.

## Next-session candidates
1. [cluster] KEV catalog notes and cwes fields: how often CISA edits shortDescription/notes after listing (kev-data git replay) | guide | teams diffing KEV for changes | cisagov/kev-data git history, known_exploited_vulnerabilities_schema.json | must not repeat kev-duedate-..., kev-knownransomwarecampaignuse-..., kev-time-to-listing-...
2. [spec] SSVC SelectionList in CSAF 2.1 vendor advisories: which vendors ship ssvc_v2 today and with which namespaces | guide | consumers validating vendor SSVC | oasis-tcs/csaf csaf_2.1 examples, CERTCC/SSVC SelectionList schema, vendor CSAF feeds via WebSearch | must not repeat csaf-2-1-metrics-..., ssvc-object-registry-...
3. [cluster] CISA-ADP SSVC Automatable/Technical Impact vs CVSS v4 AU and VC/VI/VA: agreement audit across cvelistV5 | guide | teams choosing which field drives SLAs | cvelistV5 release zip, cve-schema cvss-v4.0.json, SSVC registry | must not repeat cvss-v4-supplemental-metrics-..., cve-json-cvss-metrics-...

## Live QA
Both posts live (HTTP 200, h1, "Short answer" opening and cover_hu hero image present) at ?v=8220a3c, checked via curl ~05:03 UTC. Covers committed by workflow (9c5bc3e); imageAlt already matches the previewed images.
