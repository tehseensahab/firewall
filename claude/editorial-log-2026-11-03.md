# Editorial log 2026-11-03

Run: scheduled, unattended. Guard note: content/posts/cloud-iam-vs-network-security-why-identity-has-become-the-new-perimeter is dated 2026-11-03T09:00Z, but it is a pre-scheduled post committed 2026-10-22 (76e8698), not an earlier run today, so the run continued. GSC quick fixes already done (2026-11-02 log), skipped. Hub (vulnerability-prioritization-workflow-cve-record-to-patch-ticket) exists; both posts link to it.

## Topic selection
- Article A [cluster]: CVE ADP containers (candidate 1 from 2026-11-02). Primary records: cve-schema, cvelistV5 README + records, vulnrichment README. Byline John Marshall. security-operations.
- Article B [cluster]: CycloneDX VEX mapping to OpenVEX/CSAF (candidate 3, re-angled to "CycloneDX VEX" so it does not repeat vex-explained, which explicitly skipped CycloneDX). Byline Craig Leslie. appsec.
- Timely check: kev-data catalogVersion 2026.10.30 (count 1766). Uncovered recent KEV adds: CVE-2026-76418 Cisco ASA/FTD (2026-10-29), CVE-2026-46300 Linux kernel (2026-10-28). Not taken: Cisco PSIRT pages were not returned by WebSearch on 11-01, and timely posts earned 0 clicks per the GSC review; two cluster pieces were stronger.
- Candidate 2 (cpeApplicability) held for a later run.

## Fact-check: Article A (cve-adp-containers-cisa-adp-cve-program-supplier-sadp)
| Claim | Primary source / quote or data | Date | Status | Scope |
| --- | --- | --- | --- | --- |
| One cna, multiple adp; "There can only be one 'cna' container ... there can be multiple 'adp' containers" | cve-schema CVE_Record_Format.json containers.description | repo ce5f5c8 (2025-10-29) | VERIFIED | schema 5.2.0 default |
| adpContainer required ["providerMetadata"], minProperties 2, patternProperties ^x_[^.]*$ | same, definitions.adpContainer | same | VERIFIED | |
| "For the most part, the 'cna' and 'adp' containers contain the same properties. The main differences are the source" | same | same | VERIFIED | |
| providerMetadata: orgId required, shortName, dateUpdated | same | same | VERIFIED | |
| CVE Program Container title/shortName, refs after 7/31/2024, x_transferred, duplicates, "These two containers are minimally required" | cvelistV5 README lines 42-63 | fetched 2026-11-03 | VERIFIED | |
| CISA-ADP: SSVC, KEV, Vulnrichment; "launched on June 4" retro to February 2024 | cvelistV5 README lines 65-72 | same | VERIFIED | year 2024 from README context |
| "For those CVEs that do not already have these fields populated by the originating CNA ... At no point will CISA overwrite" | vulnrichment README (develop) | fetched 2026-11-03 | VERIFIED | |
| Siemens SADP: "The SADP comes handy if a supplier like Siemens wants to add information to a vulnerability"; introduced April 2026; known-not-affected planned | siemens.com/en-gb/content/cert-services-sadp (WebFetch, quote limit 125 chars; April 2026 from tool summary) | 2026 | QUALIFIED | vendor page |
| Sample: 2,000 files, 1,963 published, 37 rejected; any ADP 1,847; CISA-ADP 1,844 (93.9%); CVE 43 (2.2%); SADP 24 (1.2%: redhat 18, siemens 6) | stats.py over random 2,000 of 84,066 cves/2026 files, cvelistV5 1a44d59 | 2026-11-03 | VERIFIED (code) | 2026 only |
| CISA-ADP SSVC 1,844; CVSS 389 (19.8%), 381 CNA had none (97.9%), 1 cvssV4_0 (CVE-2026-101296); CWE 336 (17.1%), 326 CNA none (97.0%); KEV 5 | same | same | VERIFIED (code) | |
| x_adpType "supplier" on all 24 SADP containers; Red Hat x_generator sadp-cli 1.0.0; siemens defaultStatus unknown | same sample | same | VERIFIED (code) | |
| CVE-2026-70373: CNA TuranSec 8.8 AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H vs CISA-ADP 6.5 .../C:H/I:N/A:N | record file | same | VERIFIED | |
| CVE-2026-46300 container output (CNA Linux 7.8; CVE 4 refs; redhat 39 affected, 33 solutions, CWE-123, Important; siemens 10 affected; CISA SSVC active/no/total, KEV 2026-10-28, CWE-456) | containers.py on record; KEV dateAdded 2026-10-28 in kev-data | same | VERIFIED (code) | |
| Merge policy | editorial recommendation, labelled as such | | QUALIFIED | |
Removed: none. Not used: cve.org ADP/Structure pages (JS-rendered, empty to WebFetch).

## Fact-check: Article B (cyclonedx-vex-analysis-state-justification-openvex-csaf-mapping)
| Claim | Primary source / quote or data | Date | Status | Scope |
| --- | --- | --- | --- | --- |
| CycloneDX states (6), justifications (9), responses (5) with meta:enum definitions quoted | bom-1.6 and bom-1.7 schema (identical enums) | master, 2026-11-03 | VERIFIED | |
| detail: "If a vulnerability is not exploitable, this field should include specific details on why..." | bom-1.7 schema | same | VERIFIED | |
| BOM-Link pattern ^urn:cdx:<uuid>/[1-9][0-9]*#.+$; syntax urn:cdx:serialNumber/version#bom-ref | schema bomLinkElementType; cyclonedx.org/capabilities/bomlink | same | VERIFIED | |
| OpenVEX statuses; 5 justifications from CISA July/June 2022 doc; "MUST include either a status justification or an impact_statement"; action_statement rule; inline_mitigations "cannot be configured or disabled by the user" | openvex/spec OPENVEX-SPEC.md v0.2.0 | main 2026-11-03 | VERIFIED | |
| CSAF product_status keys; flags label enum (same 5); remediation categories 2.0; threats category impact | csaf_2.0/json_schema/csaf_json_schema.json (oasis-tcs/csaf c8047c8) | 2026-10-28 | VERIFIED | |
| CSAF VEX profile 4.5 known_not_affected / known_affected rules; no_fix_planned/none_available permitted | csaf_2.0/prose/csaf-v2-editor-draft.md | same | QUALIFIED | TC repo text, not OASIS-hosted |
| Trivy cdxStatus: false_positive+not_affected -> not_affected; resolved(+pedigree) -> fixed; exploitable -> affected; in_triage -> under_investigation; skips BOM-Link with serial/version mismatch ("URN doesn't match with SBOM") | aquasecurity/trivy pkg/vex/cyclonedx.go, main 1d1ab074 | 2026-11-02 | VERIFIED | main branch |
| Trivy docs: separate VEX BOM, BOM-Links in affects.ref, CycloneDX SBOM only, experimental, example command | trivy.dev/docs/latest/supply-chain/vex/file (v0.67) | fetched 2026-11-03 | VERIFIED | |
| Justification mapping (2 map, 7 text) | editorial reading; no published CycloneDX/CISA mapping found (WebSearch) | | QUALIFIED (stated in post) | |
| Converter run: 3 statements + 1 WARN; output valid vs openvex_json_schema 0.2.0; inputs valid vs CycloneDX 1.6 (check-jsonschema) | our run, Python 3.13 | 2026-11-03 | VERIFIED (code) | test data invented, labelled |
Removed: CVE-specific details in test data (feature names, fixed versions) replaced with generic text to avoid unverified claims.

## Internal links
A -> KEV JSON feed, Vulnrichment SSVC, cve-affected-versions, cve-record-states, prioritization workflow (hub). B -> vex-explained, hub, sbom-minimum-elements, cvss-vs-epss-vs-kev. Dead-link check over /tmp/pub: 0.

## Skipped / issues
- cve.org ProgramOrganization pages: JS-rendered, empty to WebFetch.
- Unsplash: zlMHJOdGCdE rejected (shipping line brand names visible); two Unsplash+ photos rejected; dyUp7WPu5q4 already in covers.tsv.

## Next-session candidates
1. [spec] cpeApplicability in CVE JSON 5.2: how CPE match criteria in a CVE record work vs NVD configurations | guide | 29.5% of sampled 2026 records carry it; "cpeApplicability cve json" | cve-schema cpeApplicabilityElement definition, cvelistV5 records (partial clone + parallel raw curl), CISA-ADP CPE vulnrichment (README) | must not repeat cve-affected-versions..., cve-adp-containers... (link both + hub)
2. [cluster] CSAF VEX documents: how to read product_tree, product_status and flags with a tested parser (Red Hat/Siemens publish CSAF) | guide | teams receive CSAF from vendors and need to join it to SBOM purls | oasis-tcs/csaf csaf_2.0 schema + prose, a vendor CSAF VEX file via WebSearch, Trivy pkg/vex/csaf.go | must not repeat vex-explained, cyclonedx-vex... (link both + hub)
3. [timely] Linux kernel CVE-2026-46300 (KEV 2026-10-28, SSVC active/total, Red Hat + Siemens SADP) | timely | widely deployed, in KEV | cvelistV5 record, kev-data, Red Hat CVE page via WebSearch | must not repeat cve-adp-containers... (which uses it as an example); only if still within 14 days and weekly timely cap allows

## Publication status
Pushed to main: 823f604 (posts, INDEX, covers.tsv), d753f68 (cover images, workflow), then alt text + log + SOURCES commit. hugo --minify clean (421 pages); both posts in /tmp/pub/posts; dead-link check 0. imageAlt rewritten after viewing cover.jpg. Live check: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED (not retried), so live NOT confirmed; owner to spot-check.
