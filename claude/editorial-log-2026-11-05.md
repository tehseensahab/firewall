# Editorial log 2026-11-05

Run: scheduled, unattended. GSC quick fixes already done (log 2026-11-02), skipped. Hub (vulnerability-prioritization-workflow-cve-record-to-patch-ticket) exists; both posts link to it.

## Topic selection
- Shortlist from 11-04 candidates: (1) CSAF VEX product_tree/product_status -> purl join [cluster]; (2) CVE JSON 5.2 packageURL [spec]; (3) Linux kernel CVE-2026-46300 [timely] (dropped: timely posts get 0 clicks; spec piece preferred; timely cap left unused).
- Source check: oasis-tcs/csaf (raw + partial clone) 200; cve-schema schema + rfds/0002 200; purl-spec 200; cvelistV5 release bundle 200 (652 MB, 24 s).

## Article A: csaf-vex-product-tree-product-status-purl-sbom-matching (John Marshall, security-operations)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| CSAF 2.0 OASIS Standard 18 Nov 2022 | csaf_2.0/prose/csaf-v2-editor-draft.md header "## OASIS Standard / ## 18 November 2022" | 2022-11-18 | QUALIFIED (TC repo copy) | CSAF 2.0 |
| VEX profile reqs: product_tree "which lists all products referenced later on...", notes, cve or ids, one of 4 statuses, impact statement for known_not_affected ("as machine readable flag ... or as human readable justification in /vulnerabilities[]/threats"), action statement for known_affected, category csaf_vex | prose s4.5 | 2022 | VERIFIED | |
| 8 product_status lists, definitions ("may not be the recommended fixed versions") | prose s3.2.3.9 | | VERIFIED | |
| Contradiction groups, "MUST be pairwise disjoint"; recommended "from any group - also from the affected group" | prose s6.1.6 | | VERIFIED | |
| Flag labels (5), remediation categories (5), vendor_fix exclusive with none_available/no_fix_planned | prose s3.2.3.5, 3.2.3.12.1 | | VERIFIED | |
| Relationship 4 required fields, 5 categories, "vulnerable only when installed together with another" | prose s3.2.2.4 | | VERIFIED | |
| purl helper pattern; "does not completely evaluate whether a PURL is valid" | prose s3.1.3.3.4 | | VERIFIED | |
| vendor->product_name->product_version recommended "whenever possible to support the identification and matching"; product_version_range; enumerate preferred | prose lines 684, 726, 767 | | VERIFIED | |
| Example doc schema-valid | csaf_json_schema.json + jsonschema Draft2020-12, 0 errors | 2026-11-05 | VERIFIED (our test) | schema only, not mandatory tests |
| Script outputs (3 SBOM tests) | ran python3 -I csaf_vex_join.py | 2026-11-05 | VERIFIED | |
| Red Hat VEX: per CVE; product_tree lists "products, their components, and the relationships between them"; GA "extended the scope of the purl identifiers to unfixed components as well" rpm/oci/rpmmod | redhat.com/de/blog/red-hat-vex-files-cves-are-now-generally-available (10 Jul 2024) | 2024-07-10 | QUALIFIED (vendor; localized copy) | |
| Beta: "Only components that have fixed versions ... include a purl identifier" | redhat.com/en/blog/vulnerability-exploitability-exchange-vex-beta-files-now-available | 2023-10-16 | VERIFIED | |
| Trivy CSAF: status map known_not_affected + fixed only; purl required; 3 relationship categories; others skipped; subProduct nil -> no relationship match | trivy v0.76.1 pkg/vex/csaf.go (identical to main e8a68c1) | 2026-11-05 | VERIFIED | v0.76.1 |
| Trivy docs: targets table; "relationship category is not taken into account" / "depends_on"; purl matching rules "not formally defined within the current official PURL specification" | trivy v0.76.1 docs/guide/supply-chain/vex/file.md | | VERIFIED | |
| CSAF 2.1 still draft | csaf_2.1/prose/edit/src frontmatter "Committee Specification Draft 04 / 21 October 2026" | 2026-10-21 | VERIFIED (stated as "still a draft") | |
Removed: none. Not verified: none in post.

## Article B: cve-packageurl-purl-cve-json-5-2-affected-sbom-matching (Craig Leslie, appsec)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| packageURL def "MUST NOT include a version"; uriType; examples | cve-schema main CVE_Record_Format.json (default dataVersion 5.2.0) | 2026-11-05 | VERIFIED | |
| product allOf: vendor+product or collectionURL+packageName; versions or defaultStatus | same | | VERIFIED | |
| RFD quotes ("of limited value for automated applicability matching", "better suited than CPEs...", "further constrained by CVE Services", "would be excessive and difficult to maintain", "All version information should only be included...") | rfds/0002-supporting-package-urls.md | | VERIFIED | |
| v5.2.0 tag commit 2025-09-03 | git log v5.2.0 (5533f60) | 2025-09-03 | QUALIFIED (commit date) | |
| 400,445 published / 18,890 rejected; dataVersion 5.2 144,619 / 5.1 255,826 | cvelistV5 release cve_2026-11-05_0400Z, purl_scan.py | 2026-11-05 | VERIFIED | |
| 6,284 records (1.57%), 7,324 entries, 12 CNAs, CNA table, ADP 0, version-in-purl 0, qualifiers 76, missing identifier pair 0, cpes+purl 863 | same | | VERIFIED | |
| Types counts; github by CNA VulnCheck 1,917 / EEF 413 | same | | VERIFIED | |
| Monthly counts; Oct 2026 2,000/17,058 = 11.7% (by original datePublished) | same | | VERIFIED | |
| github uppercase 756/2,371 = 31.9%; pypi uppercase 9; underscore 24; GitPython 28 lowercase / 6 GitPython | purl3.py + recount | | VERIFIED | |
| software-id decision "status: proposed", 2026-10-21 | purl-spec docs/decisions/001 | 2026-10-21 | VERIFIED | |
| purl type rules (github/pypi lowercase, pypi _ -> -, npm case-sensitive) | purl-spec types/*-definition.json | | VERIFIED | |
| Join test results (17/10/7, 34/6/28, 23/0/23) | ran build_index.py + join_sbom.py, packaging 26.3 | 2026-11-05 | VERIFIED | |
| CVE-2026-110180 fragment | cvelistV5 record (raw 200) | | VERIFIED | |
Removed: none.

## QC
- Titles 56 / 55 chars; descriptions 159 / 159. hugo --minify: 0 errors; dead internal link check over all built posts: 0 dead.
- Internal links A: vex-explained, cyclonedx-vex, hub, sbom-minimum-elements. B: cve-affected-versions, cve-cpeapplicability, hub, csaf-vex (today).
- Live check: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED (not retried); status = pushed, live not confirmed. Cover commit 8a64a1c landed; both cover.jpg checked, imageAlt matches.
- Covers: sUzKJEfi-dg (branches, BehindTheTmuna), Ul7DGBXznD8 (mailboxes, Andretti Brown); both previewed, no brands. Rejected: zlMHJOdGCdE (Hapag-Lloyd logos), e_QqMu91zEM (franchise crest + child), DD8aCH-MnK4 and Y1mmxrjrZQc (Unsplash+), CpIWRMy0jkg (no photo id).

## Next-session candidates
1. [cluster] OpenVEX statements: products, subcomponents and status_notes, and how scanners match them to purls | guide | OpenVEX is what Trivy/Grype/vexctl emit; engineers write it by hand | openvex/spec main (OPENVEX-SPEC.md, JSON schema) raw; trivy v0.76.1 docs file.md (OpenVEX section); vexctl README | must not repeat vex-explained, cyclonedx-vex, csaf-vex-product-tree (link all + hub)
2. [spec] CVE JSON 5 versions[].changes: how "changes" arrays express backports and what they mean for scanners | guide | Linux and distro CNAs use changes; most parsers ignore it | cve-schema (versions/changes definition), cvelistV5 bundle count (reuse /tmp approach: release zip 652 MB, 30 s scan) | must not repeat cve-affected-versions (link + hub)
3. [cluster] EPSS model version changes: reading model_version and score_date headers and handling score jumps | guide | EPSS v4 transition causes score swings in pipelines | empiricalsec/epss_scores partial clone (daily file headers), FIRST EPSS model page via WebSearch | must not repeat epss-data-feed-columns, cvss-vs-epss-vs-kev (link both + hub)
