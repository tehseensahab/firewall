# Editorial log 2026-11-26

GSC quick fixes: already done (2026-11-02 log). Hub exists (vulnerability-prioritization-workflow-cve-record-to-patch-ticket); both posts link it.
Timely cap: 2 timely CVE posts already this week (vCenter 11-23, Cisco Expressway 11-24), so Article B = second cluster piece.

## Article A: KEV Catalog Changes: 157 Field Edits and 4 Removals (Craig Leslie, security-operations)
Slug kev-catalog-changes-field-edits-removals-kev-data-history | kw "kev catalog changes"
Internal links: kev-json-feed, kev-duedate, kev-knownransomwarecampaignuse, hub.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 350 first-parent commits to JSON, 349 parse, 15200f9 invalid ("Unterminated string") | kev-data clone head 51e0a77 (2026-11-25T22:59:40Z) | 2025-01-27..2026-11-25 | VERIFIED | |
| 157 content edits / 83 CVEs; 92 whitespace / 76 CVEs; per-field table | replay script (kev_edits.py, run twice incl. dev replay) | same | VERIFIED | 7 text fields |
| 86 trims in 2026.11.13; 6 vendorProject trims 2026.11.17 (SimpleHelp, Array Networks) | replay | | VERIFIED | |
| Zimbra: 10 CVEs edited 2025-02-24, 8 vendorProject Zimbra->Synacor | replay | | VERIFIED (corrected from "eleven" in draft) | |
| Example diffs (Palo Alto, HPE, PRTG, Kernel, Android, F5+CWE-121, SharePoint chaining + requiredAction text, React CVE-2025-66478 note, GeoVision EoL, CWE edits) | replay per-entry values | | VERIFIED | |
| Removals CVE-2025-4664 (2025.06.09), -6264 (2025.10.22), -2026-1281 (re-added same day), -69836 (2026.08.21); catalog 2026.11.25 = 1,805 | replay + grep current file | | VERIFIED | reasons NOT stated in data; no speculation |
| Schema descriptions of notes/shortDescription; no modified field | known_exploited_vulnerabilities_schema.json | | VERIFIED | |
| CWE-699 is a view | editorial knowledge | | QUALIFIED (well-known) | |

## Article B: SSVC Automatable vs CVSS: What Predicts CISA's Call (John Marshall, appsec)
Slug ssvc-automatable-technical-impact-vs-cvss-vector-cisa-adp | kw "ssvc automatable"
Internal links: bod-26-04 decision table, vulnrichment SSVC guide, cvss-v4-supplemental, hub, cvss-vs-epss-vs-kev.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 432,459 files, 413,235 PUBLISHED, 227,496 CISA-ADP SSVC; 52,160 yes; 79,334 total | cvelistV5 release cve_2026-11-26_0000Z, census.py + ssvc_vs_cvss.py (same counts) | 2026-11-26 | VERIFIED | |
| Automatable by source table; 90.2% / 1.2%; acc 96.7%; recall 96.0%; fp 4,509 | same; recomputed in python | | VERIFIED | v3.1 CNA-first |
| AC:H 164/7,954; PR:L 614/39,225; UI:R 452/27,864 | census pass 1 | | VERIFIED | |
| TI table 95.3/70.2/3.1/3.1; >=2 High acc 94.7%; S:C 96.9 / S:U 95.0 | same | | VERIFIED | |
| CVE-2024-47575, CVE-2020-1472, CVE-2024-0769 vectors + SSVC | same export | | VERIFIED | |
| SSVC definitions verbatim | CERTCC/SSVC automatable.py, technical_impact.py (raw, main) | 2026-11-26 | VERIFIED | |
| Vulnrichment README quotes (scoring order, drop own CVSS) | raw cisagov/vulnrichment develop README | | VERIFIED | |
| Vector rule as stand-in | editorial | | QUALIFIED | |
Removed in draft: none. Corrected: TI stand-in accuracy restated (all-3-High rule is 92.2%, >=2 High 94.7%).

## Images
A: Unsplash Ft5Mb25iNmI (Emmanuel Phaeton), previewed, no brands; added to covers.tsv.
B: no cover. Gauge photo M6xNMyYi4H8 rejected (FoamLogix/HALE brand text visible). Follow-up web-fetch of unsplash.com/s/photos/balance-scales DENIED by auto-mode classifier; post uses theme placeholder; image fields removed. Owner may add a cover.

## Next-session candidates
1. [cluster] KEV notes field parser: split " ; " lists, classify CISA mitigation vs vendor vs NVD links, count per entry (kev-data current + history) | guide | engineers pulling remediation links into tickets | cisagov/kev-data JSON + schema, cvelistV5 references | must not repeat kev-catalog-changes-..., cisa-kev-json-feed-...
2. [cluster] CISA-ADP SSVC with no CVSS at all: what the 37,425 SSVC-only records look like (CNA, year, Exploitation) and how to score them | guide | teams with CVSS-keyed SLAs missing records | cvelistV5 release zip, vulnrichment README | must not repeat ssvc-automatable-technical-impact-vs-cvss-..., cve-json-cvss-metrics-...
3. [spec] SSVC SelectionList in CSAF 2.1 vendor advisories (carried over) | guide | consumers validating vendor SSVC | oasis-tcs/csaf csaf_2.1 examples, CERTCC/SSVC schema | must not repeat csaf-2-1-metrics-..., ssvc-object-registry-...

## Live QA
Both posts live (HTTP 200, h1 and "Short answer" opening present) via curl ~05:10 UTC at ?v=c50888f3. Article A hero (cover_hu) present; cover committed by workflow c37c16d, imageAlt written from the previewed image. Article B has no hero image (see Images).
