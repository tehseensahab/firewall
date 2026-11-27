# Editorial log 2026-11-27

Guard: no post dated 2026-11-27 before this run. GSC quick fixes already done (11-02 log). DAILY.md hacking-news trial ended 2026-11-22 (runs normal prompt; owner should review GSC for [news] rows). Hub exists (vulnerability-prioritization-workflow-cve-record-to-patch-ticket); both articles link it.
Timely cap: 2 timely CVE posts already this week (vCenter 11-23, Cisco Expressway 11-24), so Article B = cluster explainer.
Candidate dropped: SSVC SelectionList in CSAF 2.1 (overlaps csaf-2-1-metrics-epss-ssvc-cvss-v4-per-product, which already maps ssvc_v2).

## Article A: kev-notes-field-parse-links-vendor-advisory-bod-26-04-nvd (John Marshall, security-operations)
Data: kev-data known_exploited_vulnerabilities.json catalog 2026.11.25 (dateReleased 2026-11-25T19:48:12Z, 1,805), schema file; cvelistV5 main records for 772 NVD-only entries (768 JSON, 4 HTML error pages); cve-schema reference-tags.json.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 3,606 links: nvd 1805/1805, vendor 1368/1009, bod-26-04 370/185, directive 31/23, cisa-other 24/24, archive 8/8; 789 no vendor link | parser run (kev_notes.py output) | 2026.11.25 | VERIFIED | current catalog |
| links per entry 772/686/93/172/42/21/6/5/5/1/2 | parser run | same | VERIFIED | |
| 772 NVD-only: 2021 294, 2022 474, +4 since 2024 | parser run | same | VERIFIED | |
| NVD last link in 1,804; exception CVE-2026-56155 | script | same | VERIFIED | |
| 186 labelled; forensicTriage Yes 121 / No 65; No spread Jun-Nov (Nov 12); CVE-2026-104935 Yes w/o labels; 188 added since 06-11, 2 unlabelled | script | same | VERIFIED | |
| schema: notes "Any additional notes about the vulnerability"; forensicTriage "'Yes' if this vulnerability requires forensic triage per BOD 26-04; ..." | known_exploited_vulnerabilities_schema.json | 2026-11-27 | VERIFIED | |
| separators: ' ; ' 1292, ';␠' 412, ' ;' 1, bare ';' (TIBCO CVE-2018-5430) | script | same | VERIFIED | glibc URL's 2 in-URL ';' excluded from separator claim |
| glibc CVE-2023-4911 URL with ';'; https:/ in CVE-2026-104935, CVE-2013-2597; ED links with ')' 11; titles in CVE-2026-96951; '; ;' in CVE-2026-105134 | script | same | VERIFIED | |
| boilerplate: open-source/third-party 87; CISA Mitigation Instructions 16; ED 21-03/21-02 prose 11 | substring counts | same | VERIFIED | |
| top hosts apple 220, msrc 137, github 87, git.kernel.org 50, cisco 44 | script | same | VERIFIED | |
| 494 refs tagged vendor-advisory/patch/x_refsource_CONFIRM; 306 vendor-advisory; 28 patch; 36 untagged; 326 CONFIRM | cvelistV5 records | 2026-11-27 | VERIFIED | 768 of 772 |
| tag definitions (vendor-advisory, patch); x_ extension pattern | cve-schema | 2026-11-27 | VERIFIED | |
| 38 notes content edits since Jan 2025 | existing post kev-catalog-changes | 2026-11-26 | VERIFIED (own prior analysis) | |
| labels are a template | inference | | QUALIFIED (labelled as our reading) | |

## Article B: cve-no-cvss-score-cisa-ssvc-only-records-epss-fallback (Craig Leslie, appsec)
Data: cvelistV5 release cve_2026-11-26_0000Z all_CVEs zip (2026-11-27 asset 404, 9-byte body); KEV 2026.11.25; EPSS 2026-11-26 (model v2026.06.15); vulnrichment README.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 413,235 published; CVSS+SSVC 214,968; CVSS only 24,791; SSVC only 12,528; neither 160,948; 2026: 96,367/2,478/1,193/4,320 (104,358) | census2.py | 2026-11-26 snapshot | VERIFIED | sums checked |
| SSVC records 227,496; CNA-only CVSS 166,165; ADP-only 46,158 | census.py | same | VERIFIED | |
| CNA top 10 (Linux 4130, mitre 2947, oracle 2658, cisco 423, google_android 336, apple 256, Unisoc 191, WPScan 150, huawei 137, jpcert 134) | census | same | VERIFIED | |
| year counts; 2026 1,190 of 1,193 Linux | census | same | VERIFIED | by datePublished |
| SSVC values E 10845/1682/1; A 10128/2400; T 9849/2679; none/no/partial 7790; trigger 4738; version 2.0.3; ts years | census | same | VERIFIED | |
| CNA other ratings 51/27/5 | census | same | VERIFIED | |
| README trigger quote; CISA-ADP drops its data when CNA supplies; 2.0.3 meaning | raw vulnrichment/develop/README.md | 2026-11-27 | VERIFIED | |
| none in KEV; CVE-2021-21983 active, not KEV | kev.json 2026.11.25 | | VERIFIED | |
| EPSS median 0.00507; >=0.01 4247; >=0.1 232; pct>=0.9 727; poc median 0.0089 (29); none 0.00413 (202); CVE-2022-42889 0.95208/0.99915; CVE-2019-0232 0.99923 | epss_scores-2026-11-26 | 2026-11-26 | VERIFIED | |
| CVE-2022-42889 / CVE-2025-71119 field values | no_cvss.py run on cvelistV5 main | 2026-11-27 | VERIFIED | |
| Oracle CVE-2019-2435/2440 published Jan 2019, no CNA metrics | census rows | | VERIFIED | |
| NVD may have scores | not queried | | QUALIFIED (scope note) | |
| Fallback rule | editorial | | QUALIFIED | |
Removed before draft: claim about Linux kernel CNA CVSS policy (Documentation/process/cve.rst has no CVSS text; not verifiable).

## Images
A: Unsplash fMXC9nAWv3w (Brett Jordan), photo-1629441019244-e1fccee58f9e, previewed: tangled cables, no brands; added to covers.tsv.
B: no cover. Rejected XADG1a1LiqQ (looks AI-generated mockup), 3TBVDU2ydJE (shop-sign lettering in background), OQEepk6Fv24 (scale brand name on dial). Theme placeholder; owner may add a cover.

## Next-session candidates
1. [cluster] KEV requiredAction text: classify "apply mitigations per vendor instructions", BOD 26-04 and discontinue-use wording into ticket actions (kev-data 2026.11.x + history) | guide | engineers automating ticket actions from KEV | kev-data JSON + schema, kev-data git history, BOD 26-04 implementation guidance via WebSearch | must not repeat kev-notes-field-..., cisa-kev-json-feed-..., kev-catalog-changes-...
2. [cluster] CVE references tags census: vendor-advisory, patch, mitigation, exploit tags across cvelistV5 and how to pick the fix link | guide | engineers auto-filling "fix" links in tickets | cvelistV5 release zip, cve-schema tags/reference-tags.json | must not repeat kev-notes-field-... (only covers NVD-only KEV entries), cve-problemtypes-cweid-...
3. [spec] CISA-ADP CVSS v3.1 entries: when CISA adds a score, how often the CNA later supersedes it (vulnrichment git history) | guide | teams deciding which CVSS to trust | cisagov/vulnrichment history, README | must not repeat cve-json-cvss-metrics-..., cve-no-cvss-score-..., cve-adp-containers-...

## Live QA
Both posts live (HTTP 200, h1 and "Short answer" present) via curl at ?v=738c062 ~05:25 UTC. Article A hero (cover_hu) present after workflow commit 4f68415; cover.jpg re-read, imageAlt matches (tangled cables). Article B uses theme placeholder.
