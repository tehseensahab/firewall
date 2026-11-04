# Editorial log 2026-11-04

Run: scheduled. GSC quick fixes already done (2026-11-02 log), skipped. Hub (vulnerability-prioritization-workflow-...) exists; both posts link to it.

## Topic selection
- Candidates from 11-03 log: (1) [spec] cpeApplicability -> picked as Article A. (2) [cluster] CSAF VEX product_tree -> deferred (overlaps cyclonedx-vex post's CSAF mapping; needs a vendor CSAF file). (3) [timely] Linux CVE-2026-46300 -> dropped for a stronger timely item.
- Source check: KEV catalog 2026.11.03 showed CVE-2026-119977 (WordPress Core) added 2026-11-03; CNA record reachable in cvelistV5; WordPress 7.1.4 release notes reachable via WebSearch. Qualifies for Article B (KEV, last 14 days, widely deployed). Timely posts this week: 1.

## Article A: cve-cpeapplicability-cpe-match-nodes-operators-version-ranges (Craig Leslie, appsec)
Claim | Primary source | Date | Status | Scope
- Fields/required/enums; "mostly copied/forked from the NIST NVD CVE API v2.0 schema"; "recommended that it align with (as much as possible) the product data provided within the affected block" | cve-schema main CVE_Record_Format.json (default dataVersion 5.2.0) | fetched 2026-11-04 | VERIFIED | schema
- cpeMatch required: vulnerable, criteria; node required: operator, cpeMatch; element required: nodes | same | VERIFIED
- cpeApplicability on cnaPublishedContainer and adpContainer | same | VERIFIED
- cpes description: "Consider using the newer cpeApplicability block..." | same | VERIFIED
- Added in 5.1.1; release note "Add new and expanded support for Common Platform Enumeration (CPE) Identifiers using the CPE Applicability Language." | gh.r-mj.com mirror of releases (QUALIFIED); v5.1.1 tag commit 2024-10-22 contains cpeApplicability (git fetch) | VERIFIED date of tag, QUALIFIED note text
- Advanced example AND + vulnerable:false platforms | schema/docs/full-record-advanced-example.json | VERIFIED
- "as of December 10, 2024, CISA will no longer be adding CPE strings" | cisagov/vulnrichment develop README | VERIFIED
- Sample: 2,000 seeded random of 84,849 2026 files @ f0b25a9 (2026-11-04T04:48Z); 1,969 published; 538 CNA cpeApp (27.3%); Linux 186, VulnCheck 110, microsoft 97, oracle 84 (477 = 88.7%); ADP 0; affected.cpes 195 (9.9%); elements 582, no element operator 489 (84.0%), AND 7, OR 86; nodes 598 all OR; matches 2,667; vulnerable false 10; specific version 170; vSI 2,397, vEE 2,333, vEI 113; matchCriteriaId 0 | computed with python | VERIFIED
- Evaluator outputs (Erlang CVE-2026-74994 28.5.0.5 True/28.5.0.6 False; example AND True only with Windows; Cervantes CVE-2026-115975 unknown; Linux CVE-2026-23122 6.15.4 F, 6.18.7 T, 6.18.9 T, 6.19 F) | script run with Python 3.13.18 | VERIFIED
- CVE-2026-23122 affected: 6.18.8 lessThanOrEqual 6.18.* unaffected | record | VERIFIED
- Removed: no NVD-uses-CNA-CPE claim (NVD page fetch returned empty).

## Article B: wordpress-cve-2026-119977-upgrade-race-rce-kev (John Marshall, security-operations)
- Description, 4.7.0-7.1.3 (25 lessThanOrEqual ranges), CVSS 3.1 8.1 AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:H, CWE-367, finder Umut Bayram, published 2026-10-31, disclosed 2026-10-28 | cvelistV5 record | VERIFIED
- KEV dateAdded 2026-11-03, dueDate 2026-11-06, ransomware Unknown, forensicTriage Yes | kev-data JSON 2026.11.03 | VERIFIED
- SSVC active/no/total (v2.0.3) | CISA-ADP container | VERIFIED
- 7.1.4 released 28 Oct 2026; "it is recommended that you update your sites immediately"; fix line; backport list; "only the most recent version of WordPress is actively supported"; 4.6 and earlier no updates | wordpress.org/documentation/?p=16371315 | VERIFIED
- All 25 branches fixed = last affected + 1 | computed | VERIFIED
- Diff 7.1.3 vs 7.1.4: get_working_dir_name with wp_generate_password(16,false); keep/write index.php with "web-served" comment; skip wp-config.php in update_core | raw.githubusercontent.com/WordPress/WordPress/<tag>/... | VERIFIED
- Core_Upgrader::upgrade calls unpack_package then copies new update-core.php | class-core-upgrader.php 7.1.3 L155-166 | VERIFIED (code reading; interpretation labelled)
- auto_update_core_minor default 'enabled' in should_update_to_version | class-core-upgrader.php 7.1.4 | VERIFIED
- 62,969 blocked attacks/24h, preconditions, setup-config.php polling | THN 2026-10-30 citing Wordfence | QUALIFIED
- Changed: removed SSVC "act" claim (outcome depends on deployer mission values); now attributed generally.
- Not done: exploit reproduction; web server rules untested (labelled illustrative); Wordfence advisory page not returned by WebSearch; securityweek amp fetch client_error.

## Publication status
Pushed to main: 2e62760 (posts, INDEX, covers.tsv), 081ce59 (cover images by workflow), then log + SOURCES commit. hugo --minify clean; both posts in pub/posts; dead-internal-link check 0. Live check: WebFetch returned PROVENANCE_REQUIRED (not retried); live NOT confirmed.

## Images
- A: Unsplash 3y1zF4hIPCg (Hans-Peter Gauster) jigsaw pieces. B: jp1gzzvH8RI (Willy the Wizard) scaffolding. Rejected hVYa0VajDko (building looked religious, visible signage).

## Next-session candidates
1. [cluster] CSAF VEX: reading product_tree, product_status and flags and joining to SBOM purls | guide | vendors (Red Hat, Siemens) ship CSAF; engineers must map it to purls | oasis-tcs/csaf csaf_2.0 schema + prose, a vendor CSAF VEX file via WebSearch, trivy pkg/vex/csaf.go | must not repeat vex-explained, cyclonedx-vex... (link both + hub)
2. [spec] packageURL (purl) in CVE JSON 5.2 affected entries: how many CNAs use it and how to join it to an SBOM | guide | 5.2.0 added packageURL; SBOM matching is purl-based | cve-schema (packageURL definition, rfds/0002-supporting-package-urls.md), cvelistV5 partial clone sample, purl-spec | must not repeat cve-affected-versions, cve-cpeapplicability (link both + hub)
3. [timely] Linux kernel CVE-2026-46300 (KEV 2026-10-28) only if still within 14 days and weekly timely cap (2; 1 used) allows; else [spec] EPSS model version changes in daily file headers | cvelistV5 record, kev-data, Red Hat CVE page via WebSearch | must not repeat cve-adp-containers (uses it as example)
