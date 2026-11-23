# Editorial log 2026-11-23

News trial (DAILY.md, 2026-11-08 to 2026-11-22) has ENDED. Article B reverted to SEO FOCUS rule 2 (timely KEV item). Owner: review GSC for the [news] rows in INDEX.md.
GSC quick fixes: already done on 2026-11-02; skipped.

## Article A: csaf-2-1-metrics-epss-ssvc-cvss-v4-per-product (appsec, John Marshall) [spec]
Primary: oasis-tcs/csaf commit e8fdccc (2026-11-18): csaf_2.1/json_schema/csaf.json, prose/edit/src/schema-elements-02-props-04-vulnerabilities.md, tests 6.1.47/48/49/51/56, 6.2.03/39/41/47; referenced_schema/certcc/SelectionList_2_0_0.schema.json; CERTCC/SSVC decision_points (exploitation, automatable, technical_impact); cvelistV5 CVE-2026-123890 (CISA ADP SSVC shape).

| Claim | Source / quote or value | Date | Status | Scope |
|---|---|---|---|---|
| metric requires content+products, source optional | schema "required": ["content","products"] | CS01 | VERIFIED | 2.1 |
| content props cvss_v2/v3/v4, epss, qualitative_severity_rating, ssvc_v2, x_extensions; minProperties 1 | schema | CS01 | VERIFIED | |
| EPSS strings + pattern; timestamp required | schema pattern ^(([0]\.([0-9])+)|([1]\.[0]+))$ | CS01 | VERIFIED | |
| "If no source is given, then the metric was assigned by the document author." | prose | CS01 | VERIFIED | |
| fixed product "should have a CVSS score of `0`, or simply no score listed" | prose | CS01 | VERIFIED | |
| "CSAF consumer SHOULD give preference to CVSS if both..." | prose | CS01 | VERIFIED | |
| 6.1.51 / 6.1.49 timestamp <= newest revision date, final/interim | test prose | CS01 | VERIFIED | numbering from test-data file names |
| 6.2.41 "not more than 15 days older" | test prose | CS01 | VERIFIED | |
| 6.1.56 no QSR + CVSS for product+source tuple | test prose | CS01 | VERIFIED | |
| 6.1.48 values order / decision point exists | test prose | CS01 | VERIFIED | |
| 6.1.47 target_ids = cve or ids text | test prose | CS01 | VERIFIED | |
| SelectionList required timestamp, schemaVersion const 2.0.0, selections; Selection requires namespace,key,version,values | schema | — | VERIFIED | |
| SSVC keys E 1.1.0 N/P/A; A 2.0.0 N/Y; TI 1.0.0 P/T | CERTCC/SSVC src | main 2026-11-23 | VERIFIED | |
| CISA ADP options for CVE-2026-123890 active/yes/total, version 2.0.3 | cvelistV5 | 2026-11-21 dateUpdated | VERIFIED | |
| Example file 0 errors; numeric probability 1 error; key "active" 0 errors | our run jsonschema 4.26 | 2026-11-23 | VERIFIED | own test |
| CVSS v4 vector -> 9.3 | python cvss lib | 2026-11-23 | VERIFIED | |
| Precedence table | editorial | — | QUALIFIED (labelled editorial) | |
Removed: "no production vendor feed publishes 2.1 metrics yet" (not surveyed); "Exploitation only moves upward in practice" (unsupported).

## Article B: vmware-vcenter-cve-2026-123890-vmdir-auth-bypass-kev (security-operations, Craig Leslie) [timely]
Qualifies: KEV dateAdded 2026-11-20 (3 days ago), widely deployed product, primary VMSA + CVE record. Timely CVE posts this week: 1.

| Claim | Source / quote | Date | Status |
|---|---|---|---|
| Description, attack vector quote, CVSS 9.8, Critical | VMSA-2026-0009 (Broadcom 39495) | 2026-11-19, upd 11-20 | VERIFIED |
| Fixed versions table, workaround "None", 7.0 "Contact Broadcom Support..." | VMSA response matrix | 2026-11-20 | VERIFIED |
| Other CVEs 123891-123894 with scores | VMSA | | VERIFIED |
| cumulative: "version 9.1.1.0200 is the latest available version and contains the fixes for all of these CVEs." | VMSA | | VERIFIED |
| Mandiant credited | VMSA acknowledgements | | VERIFIED |
| KEV dateAdded 11-20, dueDate 11-23, forensicTriage Yes, ransomware Unknown, CWE-288 | kev-data 2026.11.20 | | VERIFIED |
| SSVC active/yes/total, CNA ranges lessThan custom | cvelistV5 | | VERIFIED |
| Telco KB463116 text | Broadcom KB | | VERIFIED |
| Pre-patch exploitation, Armory Castle, Bonesaw 7.x/8.x, BeyondTrust CVE-2026-102764 initial access | SecurityWeek | ~2026-11-19/20 | QUALIFIED (press citing Mandiant) |
| "as early as September 2026"; no Quick Patch; mgmt interfaces unavailable; Back-in-Time restriction | Rapid7 ETR | 2026-11-19 | QUALIFIED; Back-in-Time flagged as unconfirmed in post |
| Network restriction / log review steps | editorial | | QUALIFIED (labelled ours) |

## Skipped / issues
- Hero images: web-fetch of unsplash.com/s/photos/* search pages was denied by the auto-mode classifier ("Undermining Oversight"); no covers.tsv lines added. Both posts render with the theme placeholder. Owner: add covers (scripts/covers.tsv) or next run retries.
- WebFetch tool not exposed directly; used the web-fetch helper agent for Broadcom/SecurityWeek/Rapid7 (worked).
- Hugo not preinstalled; v0.139.4 tarball worked.

## Next-session candidates
1. [cluster] SSVC Exploitation poc->active lag before KEV listing, from cisagov/vulnrichment git history | guide | engineers want to know how early SSVC "active" precedes KEV | cisagov/vulnrichment git log, cisagov/kev-data history, cvelistV5 | must not repeat public-poc-cves-cisa-adp-ssvc-exploitation-poc-epss, kev-time-to-listing, kev-duedate
2. [spec] SSVC Selection List 2.0.0: namespaces, keys, versions and how to validate a selection against CERT/CC decision points | guide | CSAF 2.1 and other producers now emit SelectionList; consumers need test 6.1.48 logic | CERTCC/SSVC data/schema/v2 + decision_points src, oasis-tcs/csaf tests 6.1.46-48, 6.2.34-37 | must not repeat cisa-vulnrichment-how-to-read-ssvc, csaf-2-1-metrics-epss-ssvc-cvss-v4-per-product
3. [cluster] KEV catalog vs CISA-ADP kev block: live mismatch monitor (only if distinct from 11-17 audit) | guide | cvelistV5 users | kev-data, cvelistV5 | must not repeat kev-in-cve-records-cisa-adp-kev-block-full-catalog-audit
