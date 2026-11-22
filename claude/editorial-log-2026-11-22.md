# Editorial log 2026-11-22

Guard: no run-authored post dated today; the only other 2026-11-22 post (how-to-detect-stolen-session-cookies-in-your-environment, 09:00Z, "FirewallSync Editorial") is pre-scheduled from 2026-11-06, so the run proceeded (same as 11-21). GSC quick fixes already done (11-02 log). Hub exists (vulnerability-prioritization-workflow-cve-record-to-patch-ticket); Article A links it.

News trial: last run of the 2026-11-08 to 2026-11-22 trial. Story: USDA cyber incident taking FSA/NRCS loan and payment systems offline (week of Nov 16). Why: US federal agency, real-world effect on farmer payments, on-record official confirmation, credential-reset lesson for engineers. Primary sources: Under Secretary Richard Fordyce on the record via DTN; FPAC internal email via Nextgov/FCW; ABC News; NBC via KOMO (anonymous, labelled unconfirmed).

## Article A: csaf-2-1-vs-2-0-what-changes-for-vex-consumers (Craig Leslie, appsec)
Primary: oasis-tcs/csaf @ e8fdccc7 (2026-11-18): csaf_2.1/prose/share/csaf-v2.1-draft.md (CS01 header, 09 Nov 2026), edit/src converter clause 18, transition section, profiles, vulnerabilities props, test 6.1.36; csaf_2.0 + csaf_2.1 JSON schemas; gocsaf tags v3.7.1 and v5.0.0-pre.1+20261105; trivy v0.76.2 go.mod.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 2.1 prose is CS01 dated 09 November 2026 | share/csaf-v2.1-draft.md header | 2026-11-09 | VERIFIED (repo) / QUALIFIED (OASIS page not checked; web search showed only CSD notices) | |
| Field diff (scores→metrics, relationships→product_paths, cwe→cwes, release_date→disclosure_date, involvements→document.involvement, unknown status, fix_planned/optional_patch, legacy→platform, WHITE→CLEAR/AMBER+STRICT, contact_details→contact, $schema required) | our schema-walk diff of csaf_json_schema.json vs csaf.json | 2026-11-18 commit | VERIFIED (code) | names/enums only |
| 2.0 product_status has 8 groups, remediations 5 | 2.0 schema | | VERIFIED | |
| optional_patch "application is not necessary, but might be desired by the user, e.g. to calm a security scanner" | CS01 vulnerabilities property | | VERIFIED verbatim | |
| fix_planned "there is a fix for the vulnerability planned but not yet ready" | same | | VERIFIED verbatim | |
| Status/remediation prohibited table; test 6.1.36 | CS01 table + tests-01-mndtr-36 | | VERIFIED | |
| Converter: vendor_fix→optional_patch for Not Affected/Fixed; none_available→fix_planned rule; deprecated category if invalid; product_reference→beginning_product_reference; default TLP:CLEAR | conformance clause 18 | | VERIFIED verbatim (grep in CS01 render) | |
| Deprecated profile "matches ... Security Advisory in CSAF 2.0" | profiles.md | | VERIFIED verbatim | |
| Transition paths v2.0/v2.1, "Redirects SHALL NOT be used", archive names, aggregator SHALL only sync 2.1 | distributing-04-transition-20-21 | | VERIFIED verbatim | |
| maintained_from / maintained_until in 2.1 provider.json | csaf_2.1/json_schema/provider.json | | VERIFIED | |
| 20 examples (6 advisories, 14 VEX) validate vs CS01 schema, 0 errors | our run (jsonschema 4.26 + referencing registry with referenced_schema) | 2026-11-22 | VERIFIED (code) | |
| 3 deprecated RHSA examples fail our 6.1.36 port with 6/1/15 hits; 14 VEX pass | our run | 2026-11-22 | VERIFIED (code) | port of one test |
| gocsaf v5.0.0-pre.1 supports 2.1 (README quotes, --csaf_version, maintained_until 90-day notice, remote validation 2.0 only) | gocsaf README + docs/csaf_downloader.md at tag | 2026-11-05 | VERIFIED (source read, not run) | |
| gocsaf v3.7.1 only CSAFVersion20 | raw csaf/advisory.go @v3.7.1 | | VERIFIED | |
| Trivy v0.76.2 uses gocsaf v3.7.0 | trivy go.mod | | VERIFIED | |
Removed/rewritten: "$schema optional in 2.0" (2.0 has no $schema property) corrected before publish.

## Article B: usda-cyberattack-farm-payment-systems-what-we-know (John Marshall, security-operations) [news]
| Claim | Source | Date | Status |
|---|---|---|---|
| Fordyce: "cyberthreat", not "software update"; "no Personally Identifiable Information (PII)"; no data lost; "Most systems should be back online by close of business today" | DTN (Zajkowski) | Nov 19, upd. Nov 20 | VERIFIED (on-record official, reported) |
| Systems: FSA loan software, NRCS ProTracts, NRCS Service Desk | DTN | Nov 20 | QUALIFIED |
| Rottler email Monday: "uncovered a security incident"; "reset all database passwords in all environments, and this is requiring us to reset all applications causing outages"; "unclear if all employees received this notice"; bulletin "may continue to experience intermittent outages throughout the week"; "It's not clear who carried out the intrusion or if any data was exfiltrated" | Nextgov/FCW | Nov 19 | QUALIFIED (email viewed, not published); Monday = Nov 16 inferred from Thursday pub date |
| Tuesday email "have not yet been fully restored or verified for production use", proceed at own risk | DTN | | QUALIFIED |
| GIS mapping, payments and contracting shut down; Iowa Farmers Union (Marquardt) statement; "fifth day" | ABC News | Nov 20 | QUALIFIED (single anonymous source; union on record) |
| NBC: hackers breached farmer-payment system (two former officials) | KOMO relaying NBC | Nov 20 | NOT VERIFIED by USDA: placed in "not confirmed" |
| GAO-27-108656 published Thu Nov 19 | ABC, DTN | | QUALIFIED (context; GAO page not fetched) |
Left out: crop-insurance/disaster payment programs (unsourced in Alaska Story), DNI statement on coordinated attacks (single opinion outlet), Gujarat Samachar FBI NCIC claims (AI summary aggregator), GAO "5 of 16" vs "16" discrepancy.

## Skipped / notes
- WebFetch tool not exposed again; used web-fetch agent on WebSearch URLs. No approval prompts hit.
- NBC News original not fetched (URL only seen inside a fetched page; WebSearch didn't return it).
- Unsplash+ results skipped: jFG7C_K9NBg, UCCp5JyPf7A.

## Next-session candidates
News trial ended with this run (2026-11-22). Next run: Article B reverts to SEO FOCUS rule 2; report should tell the owner to review GSC for the [news] rows in INDEX.md.
1. [spec] CSAF 2.1 metrics[].content: reading vendor EPSS, SSVC and CVSS v4 inside a CSAF file vs the CVE record | guide | consumers will see two sources of EPSS/SSVC for one CVE and need a precedence rule | oasis-tcs/csaf csaf_2.1 schema (metrics, source), referenced_schema/certcc SelectionList_2_0_0, cvelistV5 ADP records, empiricalsec/epss_scores | must not repeat csaf-2-1-vs-2-0 (link it), cvss-vs-epss-vs-kev, cisa-vulnrichment
2. [cluster] KEV catalog vs CISA-ADP kev block: live mismatch monitor | guide | engineers using cvelistV5 instead of KEV feed | cisagov/kev-data, cvelistV5 raw | must not repeat kev-in-cve-records audit (11-17); drop if too close
3. [cluster] SSVC Exploitation poc→active lag before KEV listing, from vulnrichment git history | guide | follows public-poc post | cisagov/vulnrichment git log, kev-data history | must not repeat public-poc-cves, kev-duedate
