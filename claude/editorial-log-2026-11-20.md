# Editorial log 2026-11-20

Quick fixes: already done (2026-11-02 log). DAILY.md hacking-news trial active (run 13 of 15). Hub exists (vulnerability-prioritization-workflow-cve-record-to-patch-ticket); Article A links it.
Tooling note: no WebFetch tool was exposed to this run; page fetches went through the web-fetch helper agent on WebSearch-returned URLs only.

## Article A: OpenVEX Statement Fields: What Trivy and go-vex Ignore
Slug: openvex-statement-fields-status-notes-action-statement-version-trivy | appsec | John Marshall | [spec]
Sources: openvex/spec main OPENVEX-SPEC.md (v0.2.0) + openvex_json_schema.json; go-vex v0.2.9 (tag commit 2026-09-08) pkg/vex/statement.go, vex.go, functions_files.go; go-vex main 42a83ee (2026-11-19) pkg/validate/schema.go; trivy v0.76.2 pkg/vex/openvex.go, document.go, pkg/types/finding.go, report.go, go.mod; vexctl v0.4.4 + main internal/cmd/options.go, validate.go, go.mod.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 13 statement fields; version "Defaults to zero, required when incremented"; status_notes MAY; action_statement MUST for affected; timestamp inheritance; update example | OPENVEX-SPEC.md | main 2026-11-20 | VERIFIED | v0.2.0 |
| schema: statement required [vulnerability, status]; version integer minimum 1; affected -> required action_statement; not_affected anyOf justification/impact_statement | openvex_json_schema.json ($id ..._0.2.0.json) | main | VERIFIED | |
| go-vex Statement struct has no version/supplier field | statement.go v0.2.9 lines 17-64 | v0.2.9 | VERIFIED | |
| SortStatements compares Timestamp (doc fallback) only; SliceStable | statement.go v0.2.9 l.142-172 | v0.2.9 | VERIFIED | |
| Validate(): affected requires action_statement | statement.go v0.2.9 l.103 | | VERIFIED | |
| Parse = json.Unmarshal only; trivy decodeOpenVEX = json Decode + @context check, no Validate | functions_files.go; trivy document.go l.77-92 | | VERIFIED | |
| Trivy takes stmts[len-1]; suppresses not_affected/fixed; passes Justification as Statement; ExperimentalModifiedFindings | trivy openvex.go, finding.go l.45, report.go l.174 | v0.76.2 | VERIFIED | |
| Trivy pins go-vex v0.2.9 | trivy go.mod | v0.76.2 | VERIFIED | |
| vexctl --action-statement default NoActionStatementMsg = "No action statement provided" | vexctl v0.4.4 options.go l.189; go-vex vex.go l.48 | | VERIFIED | |
| Unreleased validator note "go-vex does not decode it; it is dropped when the document is rewritten"; vexctl main validate cmd; v0.4.4 latest tag | go-vex main schema.go l.91; vexctl main go.mod pseudo-version; git ls-remote | 2026-11-19/20 | QUALIFIED (unreleased) | |
| version + supplier dropped on round trip | Go 1.24.7 stdlib test with copied struct (scratch demo/main.go) | 2026-11-20 | VERIFIED (reproduction) | |
| Lint script output | python3 run on sample.json | 2026-11-20 | VERIFIED | |
Removed/changed: "eleven" fields corrected to 13 (spec table) before publish. Not claimed: behaviour of Grype/Docker Scout.

## Article B: Chase, Visa, Mastercard Vendor Breach: What We Know [news]
Slug: chase-visa-mastercard-third-party-vendor-breach-what-we-know | security-operations | Craig Leslie
News trial: JPMorgan Chase, Visa, Mastercard third-party vendor incidents (statements Nov 19). Chosen: three household brands, US-first, mainstream curiosity, engineer lesson on marketing-vendor data. Primary: company statements as quoted by three independent outlets (The Register, ABC News, Yahoo Finance); Chase X post cited by The Register (not fetched).

| Claim | Source | Status |
|---|---|---|
| Chase: third parties targeted; "believe the attackers accessed certain marketing data ... may include some customer names and email addresses" | Register, ABC, Yahoo (identical wording) | VERIFIED (statement) |
| Chase: contact affected customers, complimentary credit monitoring | ABC | VERIFIED (single outlet quote) |
| Mastercard (Seth Eisen per Register): limited email addresses, small subset, specific benefit program; no network impact; contained | Register, ABC, Yahoo (minor wording variants) | VERIFIED |
| Visa: provider in Asia Pacific; systems not impacted; no card numbers; unrelated to week's disruptions | Register, ABC | VERIFIED |
| Chase: no connection to earlier service disruption | Register, ABC | VERIFIED |
| n0n posted all three to leak site Monday; "believed to be based in Russia" | Register | QUALIFIED (attributed claim) |
| SOCRadar: sample data shared; not independently verified; Seker phishing quote; WSJ first reported link | Yahoo | QUALIFIED (attributed) |
| Vendor names, dates, counts, attack method | none disclosed | stated as not confirmed |
Discrepancy noted: ABC says Visa spoke "earlier this week"; Register/Yahoo say Thursday. Post says statements reported Nov 19 and avoids the timing claim.

## Covers
A: Unsplash ilSnKT1IMxE (Mari Helin, free licence) reading glasses on document. B: XBi0c3PBR14 (SumUp, free licence) blank blue card at reader; checked: no logos visible. Rejected: Hapag-Lloyd/Maersk/ONE container photos (brand names visible), several Unsplash+ premium results, playing-cards photo (off-topic).

## Next-session candidates
1. [spec] CSAF 2.0 VEX remediations and threats: category, product_ids, date fields scanners read | guide | engineers consuming Red Hat/Cisco CSAF VEX need the remediation fields | oasis-tcs/csaf csaf_2.0 schema + prose, trivy pkg/vex/csaf.go at v0.76.2 | must not repeat csaf-vex-product-tree, cyclonedx-vex, today's openvex-statement-fields
2. [cluster] KEV dueDate change alerts: diff kev-data versions for dueDate/forensicTriage edits | guide | teams tracking BOD deadlines need to catch edits | cisagov/kev-data git history, schema | must not repeat kev-duedate, cve-exploitation-alerts
3. [cluster] SSVC Exploitation poc to active: lag before KEV, from vulnrichment history | guide | follows poc post | cisagov/vulnrichment git log, kev-data | must not repeat public-poc-cves, kev-time-to-listing
News (Article B, trial ends 2026-11-22): fresh 72h story; Chase/Visa/Mastercard follow-up only if a vendor is named or a filing/regulator notice appears.

## Live QA
Both pages 200 at ?v=9b461c6 (curl): h1, opening paragraph and cover_hu image (200 image/jpeg) present. Covers committed in the publish commit (fetch-covers.sh run locally); imageAlt written from the viewed images.
