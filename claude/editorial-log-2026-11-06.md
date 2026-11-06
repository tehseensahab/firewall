# Editorial log 2026-11-06

Run: scheduled, unattended. GSC quick fixes already done (log 2026-11-02), skipped. Guard: what-is-workload-identity... carries date 2026-11-06T09:00Z but is a pre-scheduled post committed 2026-10-25 (3291171), not a run output; proceeded. Hub exists; both posts link to it.

## Topic selection
- Shortlist from 11-05 candidates: (1) OpenVEX products/subcomponents matching [cluster]; (3) EPSS model version changes [cluster]; (2) CVE versions[].changes [spec] kept for tomorrow. No timely item chosen (cluster focus; 1 timely post already this week, WordPress 11-04).
- Source check: openvex/spec raw (spec + schema) 200; trivy v0.76.2 raw 200; go-vex v0.2.9 raw 200; empiricalsec/epss_scores partial clone OK (headers for every month 2021-2026 + beta_scores).
- Candidate 3 re-scoped after the data showed the v4->v5 switch on 2026-06-15: "EPSS v5 score shift" (measured diff) instead of a generic model_version explainer, to avoid overlap with epss-data-feed-columns (which already lists the 5 versions).

## Article A: openvex-products-subcomponents-purl-matching-trivy (Craig Leslie, appsec)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Product "a logical unit representing a piece of software"; "anything that can be described in a Software Bill of Materials (SBOM)" | OPENVEX-SPEC.md v0.2.0 Definitions | spec main, read 2026-11-06 | VERIFIED | v0.2.0 |
| Subcomponent "any components possibly included in the product where the vulnerability originates"; "SHOULD also list software identifiers ... SHOULD also be listed in the product SBOM" | same | | VERIFIED | |
| Component fields @id / identifiers / hashes; subcomponents on product only; identifier labels purl, cpe22, cpe23 | spec Component Fields + Appendix B | | VERIFIED | |
| "MUST identify a product"; "as many software identifiers as possible to help VEX processors" | spec Product Data Structure | | VERIFIED | |
| Inheritance: statement ts overrides doc overrides encapsulating; product ID in statement overrides encapsulating; update example keeps original ts | spec Inheritance Flow / Updating Statements | | VERIFIED | |
| Trivy v0.76.2 pins go-vex v0.2.9 | trivy v0.76.2 go.mod | tag v0.76.2 | VERIFIED | |
| Trivy: returns nil if product purl nil; takes stmts[len-1]; suppresses only not_affected/fixed | trivy pkg/vex/openvex.go | v0.76.2 | VERIFIED | |
| Trivy: leaf checked with nil sub, then DFS over parents with leaf as sub; root reached = affected | trivy pkg/vex/vex.go filterVulnerabilities/reachRoot | v0.76.2 | VERIFIED | |
| Trivy docs: blanket image statement "would suppress all instances"; subcomponents "reducing the risk of incorrect filtering"; Module B/C/D multi-path example; purl rules "not formally defined within the current official PURL specification" | trivy docs/guide/supply-chain/vex/file.md | v0.76.2 | VERIFIED | |
| go-vex: Vulnerability.Matches (@id, name, aliases); Component.Matches (@id exact/purl, identifiers, hashes); Product.Matches (no subs or no sub -> true); PurlMatches rules; "Purl version ranges are not supported yet"; SortStatements by ts with doc ts fallback | go-vex v0.2.9 pkg/vex/{vulnerability,component,product,statement,vex}.go | v0.2.9 | VERIFIED | |
| Example doc schema-valid | openvex_json_schema.json + jsonschema (venv), "schema valid" | 2026-11-06 | VERIFIED (tested) | schema only |
| 8 match results in table | Python port /tmp/work/vex_match.py run with venv python -I | 2026-11-06 | QUALIFIED (port; Go build blocked, see below) | |
| Purl rule table rows 2,3 (version mismatch, versioned VEX vs versionless scan) | read directly from PurlMatches source (not in test run) | | VERIFIED (source) | |

## Article B: epss-v5-score-shift-model-version-v2026-06-15 (John Marshall, security-operations)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Last v4 file 2026-06-14 (#model_version:v2025.03.14, 12:55:00Z); first v5 2026-06-15 (v2026.06.15, 12:03:41Z); still v5 on 11-05 | epss_scores daily file headers | data | VERIFIED | |
| Beta files 2026-05-22..06-08, model v2026.05.12 | beta_scores/ headers (18 files) | data | VERIFIED | |
| README lists v2/v3/v4 dates, no v5 | epss_scores README.md (36 lines) | 2026-11-06 | VERIFIED | |
| score_date format changed at v4 (+0000 -> Z) | headers 2025-03-16 vs 2025-03-17 | data | VERIFIED | |
| Counts: 341,350/340,247 scored; common 340,204; 43 new, 1,146 missing (119 still absent 11-05); >=0.1 23,069->17,041 (-26.1%); >=0.5 7,193->4,249 (-40.9%); crossings 0.1 3,820 up/9,847 down; pct0.9 9,837 in/9,944 out; 2x moves 243,259 (71.5%); median ratio 2.888; top-1000 overlap 588; quantiles min/p50/p99 | /tmp/work/epss_shift.py + epss_extra.py | 2026-11-06 | VERIFIED (computed) | 06-14 vs 06-15 |
| Baseline 06-13->06-14: 9/11, 25/29, 313 2x moves, overlap 999 | same script | | VERIFIED (computed) | |
| KEV (dateAdded<=2026-06-14, 1,619): median 0.7038->0.5353; >=0.1 1,224->1,219; pct>=0.9 1,323->1,366 | kev-data catalog 2026.11.04 + EPSS files | | VERIFIED (computed) | |
| v5 announced May 13, 2026; "improved modeling techniques and optimization algorithms"; "calibration step has been refined"; exploit-code classifier; "addition of new data feeds"; 23% | EIN Presswire release (syndicated, lifestyle.kbew98country.com) | 2026-05-13 | VERIFIED (vendor claim) | |
| v4 0.514 / v5 0.633 on May 4 2026 data; random ~0.025 | research.empiricalsecurity.com/research/epss-v5-is-here | Jun 15 (year not shown) | QUALIFIED (metric not fully named) | |
| Guard script output | ran python3 epss_model_guard.py on 06-14/06-15 (exit 2) and 11-04/11-05 (exit 0) | 2026-11-06 | VERIFIED (tested) | |
| No FIRST v5 page found | WebSearch x2 returned none from first.org | 2026-11-06 | noted in Limits | |

## Skipped / blocked
- go-vex Go build: `go get` via GOPROXY=direct denied by the auto-mode classifier (external code); proxy.golang.org DNS fails. Used a Python port of the go-vex v0.2.9 rules instead, labelled in the post.
- Rejected covers: Unsplash M6xNMyYi4H8 (brand names on gauges), 98MbUldcDJY (brand on scale), AgxK4Ohn1Cw (already in covers.tsv).

## QC
- hugo --minify: 0 errors, 465 pages; both posts built; dead internal link check over all posts (minified unquoted hrefs): 0 dead.
- Titles 55 / 51 chars; descriptions 155 / 160.
- Internal links: A -> vex-explained, cyclonedx-vex, csaf-vex-product-tree, cve-packageurl, hub. B -> epss-data-feed-columns, cvss-vs-epss-vs-kev, hub.

## Next-session candidates
1. [spec] CVE JSON 5 versions[].changes: how "changes" arrays express backports and what they mean for scanners | guide | Linux kernel and distro CNAs use changes; most parsers ignore it | cve-schema CVE_Record_Format.json (versions/changes), cvelistV5 release bundle scan, kernel CNA records via raw cvelistV5 | must not repeat cve-affected-versions-lessthan-defaultstatus-versiontype (link it + hub)
2. [cluster] OpenVEX in OCI attestations: trivy --vex oci, cosign attest --type openvex and how scanners discover them | guide | teams want VEX to travel with the image | trivy v0.76.2 pkg/vex/oci + docs/guide/supply-chain/vex/oci.md (raw), sigstore/cosign docs raw, openvex/spec attestation section | must not repeat openvex-products-subcomponents, cosign keyless post (link both + hub)
3. [cluster] KEV vs EPSS coverage audit: how many KEV CVEs sit below common EPSS cutoffs today, and a script to check your own threshold | guide | sanity check for pipelines that rely on EPSS thresholds | cisagov/kev-data raw, empiricalsec/epss_scores latest file | must not repeat cvss-vs-epss-vs-kev, epss-v5-score-shift, epss-data-feed-columns (link all + hub)
