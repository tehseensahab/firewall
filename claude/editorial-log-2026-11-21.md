# Editorial log 2026-11-21

GSC quick fixes: already done (2026-11-02), skipped.
News trial: European Commission AI cyber campaign | why: EU executive, AI-tool angle, confirmed on record Nov 19 | primary: Commission spokesperson Thomas Regnier at midday briefing (audiovisual.ec.europa.eu video I-298222), as reported verbatim by Help Net Security and SecurityWeek (two independent outlets).

## Article A: csaf-vex-remediations-threats-category-product-ids-trivy (appsec, Craig Leslie)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Remediation required category+details; product_ids or group_ids MUST; 6.1.29 | csaf_2.0 prose 3.2.3.12, 6.1.29 ("At least one of the optional elements Group IDs ... MUST be present") | OASIS Standard 2022-11-18 (repo HEAD e8fdccc7, 2026-11-18) | VERIFIED | CSAF 2.0 |
| 5 remediation categories + verbatim meanings; vendor_fix contradicts none_available/no_fix_planned | prose 3.2.3.12.1 | same | VERIFIED | |
| date/url/entitlements/details definitions | prose 3.2.3.12.2-8 | same | VERIFIED | |
| restart_required 9 values; machine/system quotes | prose 3.2.3.12.7 | same | VERIFIED | |
| Threat categories, date meaning | prose 3.2.3.14 | same | VERIFIED | |
| VEX profile impact/action statement rules incl. group-ID MUST sentence | prose 4.5 | same | VERIFIED | |
| Example validates (0 errors) against csaf_json_schema.json | python jsonschema 2020-12 + referenced_schema/first cvss | run 2026-11-21 | VERIFIED | |
| Trivy acts on known_not_affected+fixed; statement() = first impact threat; decodeCSAF json.Decoder; NewDocument/VEX error wrapping | raw trivy v0.76.2 pkg/vex/{csaf,document,vex}.go | v0.76.2 = latest tag 2026-11-21 | VERIFIED | source read, binary not run |
| Trivy go.mod pins gocsaf v3.7.0 (also on main) | raw trivy v0.76.2/main go.mod | 2026-11-21 | VERIFIED | |
| gocsaf ProductGroups is a struct; schema says array; decode error text | gocsaf v3.7.0 advisory.go:355/400; compiled package files unmodified with Go 1.24.7, json.Decoder | run 2026-11-21 | VERIFIED | |
| Unchanged in v3.7.1 and main | git diff v3.7.0..v3.7.1 advisory.go (empty); raw main advisory.go | 2026-11-21 | VERIFIED | |
| statement port output picks worker text for api | Go port of statement() over gocsaf types | run | VERIFIED (labelled port) | |
| 2.1 decode errors "2.1 not in [2.0]", "fix_planned not in [...]" | same gocsaf build | run | VERIFIED | |
| CSAF 2.1 CS01 dated 09 November 2026; fix_planned/optional_patch text; 7 categories | csaf_2.1/prose/share/csaf-v2.1-draft.md + csaf_2.1/json_schema/csaf.json | repo 2026-11-18 | QUALIFIED (CS not OS; no OASIS announcement found by WebSearch) | |
Removed in edit: "Cisco, Siemens" as CSAF VEX publishers (not sourced today); "most engineers" claim about Trivy; "scan reports every finding" (code shows error is returned, not silently ignored).

## Article B: european-commission-ai-cyberattack-what-we-know (ai-security, John Marshall) [news]
| Claim | Source | Status |
|---|---|---|
| "AI generated cyber campaign", "misuse of an AI tool", "publicly available" | HNS 2026-11-20 08:52Z quoting Regnier | VERIFIED (on-record via 2 outlets) |
| Detected Oct 22, confirmed Oct 26 | HNS + SecurityWeek | VERIFIED |
| Apps taken down, most restored; no staff data breach evidence; contained; not aware of ransom; no attribution; CERT-EU + EDPS | HNS + SecurityWeek quotes | VERIFIED |
| Briefing Thursday Nov 19 | HNS "Thursday's midday press briefing" + pub date Nov 20 (Thursday computed) | VERIFIED (inferred date) |
| ARTEX, Sysper/MyPMO/translation, large data, >10 days | Politico via HNS/SecurityWeek | NOT CONFIRMED -> placed in not-confirmed table |
| CERT-EU quote on ARTEX adoption | SecurityWeek | QUALIFIED (CERT-EU page not read) |
| ARTEX description, July publication, repo deleted end Oct | Dark Reading | QUALIFIED (attributed) |
| ARTEX agentic platform, forks, defensive guidance quotes, CERT-EU "highly likely" | SentinelOne 2026-11-13 | QUALIFIED (attributed; fetch truncated at 39,890 chars) |

## Live QA
Both pages 200 at ?v=44151af (curl): h1, opening paragraph, cover_hu image 200 image/jpeg. Covers fetched locally with scripts/fetch-covers.sh and committed in the publish commit; imageAlt rewritten after viewing.

## Next-session candidates
1. [cluster] KEV catalog vs CISA-ADP kev block: which CVEs are in one and not the other today (lag/mismatch check) | guide | engineers using cvelistV5 instead of the KEV feed want to know if they miss entries | cisagov/kev-data raw, cvelistV5 raw records, cve-schema ADP docs | must not repeat kev-in-cve-records (full audit 11-17) — angle: live mismatch monitor, not field audit; consider dropping if too close
2. [spec] CSAF 2.1 what changed from 2.0 for VEX consumers (csaf_version, new remediation categories, new flags/fields) | guide | CS01 dated 2026-11-09; tooling (gocsaf v3.7.x) rejects 2.1 | oasis-tcs/csaf csaf_2.1 prose + schema diff vs csaf_2.0, gocsaf tags | must not repeat today's remediations post (link it) or csaf-vex-product-tree
3. [cluster] SSVC Exploitation poc to active lag before KEV, from vulnrichment history | guide | follows poc post | cisagov/vulnrichment git log, kev-data | must not repeat public-poc-cves, kev-time-to-listing
News trial: last run is 2026-11-22; after that the next run notes the trial ended and the owner should review GSC for [news] rows. EC follow-up only if Commission/CERT-EU publishes new facts.
