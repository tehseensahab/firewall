# Editorial log 2026-11-28

Hacking-news trial (DAILY.md, 2026-11-08 to 11-22) has ended; owner should review GSC for the [news] rows in INDEX.md. GSC quick fixes already done (11-02 log). Hub exists (vulnerability-prioritization-workflow-cve-record-to-patch-ticket); both posts link to it.

## Published
1. kev-requiredaction-text-variants-ticket-actions-bod-26-04 | security-operations | John Marshall | [cluster] | live 200 at ?v=95fc4ac
2. cve-reference-tags-patch-vendor-advisory-fix-link-cvelistv5 | appsec | Craig Leslie | [cluster] | live 200 at ?v=95fc4ac
Both use the theme placeholder image (no cover: Unsplash fetch via web-fetch agent DENIED by classifier this run; all 4 card-catalog photo ids found by search already in covers.tsv).

## Fact-check: Article A (KEV requiredAction)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| catalogVersion 2026.11.27, 1,808 entries, 45 distinct requiredAction strings (45 trimmed and raw) | kev-data main JSON | 2026-11-27 | VERIFIED (script) | full catalog |
| 893 "Apply updates per vendor instructions." 2021-11-03..2023-06-23; 323 BOD 22-01 template 2023-10-10..2026-06-09; 260 mitigations-or-discontinue 2023-07-17..2025-02-24; 190+1 BOD 26-04 2026-06-11..2026-11-27 | kev-data JSON | 2026-11-27 | VERIFIED | |
| 853 entries added after 2023-06-23, none plain update text; 108 Microsoft mitigate-legacy since 2023-07 | kev-data JSON | | VERIFIED | |
| 340 entries contain "BOD 22-01" | kev-data JSON | | VERIFIED | |
| 52 "end-of-life and should be disconnected"; last EoL wording in requiredAction 2025-07-22; 30 EoL flags in shortDescription outside retire (23+7); CVE-2026-131914 and CVE-2026-90436 shortDescription quote | kev-data JSON | | VERIFIED | |
| Classifier buckets 912/606/191/83/14/2; forensicTriage Yes 123 of 191 | kev-data JSON | | VERIFIED (script output pasted) | |
| requiredAction schema description, type string, required | kev-data schema | | VERIFIED | |
| BOD 26-04 dated June 10 2026, revokes BOD 22-01 | BOD 26-04 page (verified 2026-10-12 log); CISA BOD 22-01 page title "(Revoked)" in WebSearch result | 2026-06-10 | VERIFIED (prior reading + search title) | |
| Wording reflects template era, not patch status | editorial interpretation of date ranges | | QUALIFIED (labelled) | |

## Fact-check: Article B (CVE reference tags)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 19 standard tags, definitions quoted, x_ pattern, minItems 1, cna requires references | cve-schema main reference-tags.json + CVE_Record_Format.json | fetched 2026-11-28 | VERIFIED | |
| 433,336 files, 414,102 published, 1,358,350 CNA refs, 299,580 untagged (22.1%), 199,548 no standard tag | cvelistV5 cve_2026-11-28_0000Z | 2026-11-28 | VERIFIED (script) | published only |
| per-tag record counts (patch 22,081; mitigation 182; etc.), x_refsource_MISC 185,043, CONFIRM 148,977 | same | | VERIFIED | |
| 2026: 105,225 records, patch 16,862, VA 28,102, both 11,240, mitigation 77; no pre-2019 patch tags | same | | VERIFIED | by datePublished year |
| patch hosts github 13,898, msrc 8,081, ibm 2,462 | same | | VERIFIED | per reference |
| Ladder results (all/2026/KEV) incl. none 235,503 / 56,197 / 818; login-gated 66 | same + KEV 2026.11.27 | | VERIFIED | 2 KEV CVEs (CVE-2026-120705, -129243) have no record |
| ADP refs 955,866, x_transferred 902,160; "marks copies" | same | | QUALIFIED (meaning of x_transferred not schema-defined) | |
| NVD tags claim | removed (unverified) | | REMOVED | |

## Next-session candidates
1. [cluster] KEV vulnerabilityName and product normalization: map KEV vendorProject/product strings to CVE affected vendor/product and CPE for scanner joins | guide | engineers whose scanner exports miss KEV matches on naming | kev-data JSON, cvelistV5 affected[].vendor/product/cpes, cve-schema | must not repeat cisa-kev-json-feed-..., cve-packageurl-purl-...
2. [cluster] CVE references exploit tag vs SSVC Exploitation poc: does a CNA exploit tag predict CISA's poc call? | guide | teams using exploit links as a priority signal | cvelistV5 release zip (ref tags + CISA-ADP SSVC), vulnrichment README | must not repeat public-poc-cves-..., cve-reference-tags-...
3. [spec] CISA-ADP CVSS v3.1 entries: when CISA adds a score, how often the CNA later supersedes it | guide | teams deciding which CVSS to trust | cisagov/vulnrichment history, README | must not repeat cve-json-cvss-metrics-..., cve-no-cvss-score-..., cve-adp-containers-...
