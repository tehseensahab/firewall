# Editorial log 2026-11-12

GSC quick fixes: already done (2026-11-02 log), skipped.
News trial: run 5 of 15 (2026-11-08 to 11-22). Story: Maersk legacy-system data extraction (statement 11 Nov 2026). Why: globally known brand, NotPetya history, confirmed by company, clear engineering lesson (acquired systems). Primary: Maersk statement as reported by Reuters (via 102.7 WBOW syndication) and The Register; maersk.com notice not returned by WebSearch.

## Article A: vexctl: Create, Add, Merge and Attest OpenVEX Documents
Slug vexctl-create-add-merge-attest-openvex-documents | appsec | Craig Leslie | primary keyword: vexctl | [cluster][spec]
Sources: openvex/vexctl v0.4.4 (git clone --depth 1 --branch v0.4.4; README, internal/cmd/*.go, pkg/ctl/*.go, examples/openvex), raw openvex/go-vex v0.2.8 (pkg/vex/{vex,statement,component}.go, pkg/attestation/*), raw openvex/spec OPENVEX-SPEC.md.
Binary not run: download of the vexctl release binary was denied by the auto-mode classifier ("Code from External"). Commands labelled illustrative; merge demo is a Python port (/tmp script, product match simplified to exact string) run on examples/openvex/document{1,2}.vex.json.

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| v0.4.4 newest tag, commit 2026-06-16 | git ls-remote + git log | 2026-06-16 | VERIFIED | tags v0.4.0, v0.4.1, v0.4.4 |
| go.mod: go 1.26.4, go-vex v0.2.8, cosign/v2 v2.6.3 | go.mod lines 3, 8, 11 | v0.4.4 | VERIFIED | |
| Flag names/shorts/defaults table | options.go AddFlags ("vuln","v"; "product" via productLongFlag,"p"; "status","s"; "justification","j"; "action-statement","a", vex.NoActionStatementMsg; "impact-statement"; "status-note"; "aliases"; "subcomponents"; "id"; "author" vex.DefaultAuthor; "author-role"; "file") | v0.4.4 | VERIFIED | |
| DefaultAuthor = "Unknown Author"; NoActionStatementMsg = "No action statement provided" | go-vex vex.go L36, L48 | v0.2.8 | VERIFIED | |
| Validator: blank author only rejected; subcomponents w/ >1 product rejected; justification/impact only with not_affected; alias rules | options.go Validate | v0.4.4 | VERIFIED | |
| go-vex: not_affected needs justification or impact; affected needs action statement | statement.go Validate ("either justification or impact statement must be defined"; "action statement must be set") | v0.2.8 | VERIFIED | |
| Spec MUSTs (author individual/org; version increment; not_affected; affected action) | OPENVEX-SPEC.md L158, L162, L205, L207 | main | VERIFIED | |
| SOURCE_DATE_EPOCH, "UNIX time or RFC3339"; ID from canonicalization hash | create.go Long help; options.go ToStatement | v0.4.4 | VERIFIED | |
| Timestamps serialized in UTC | statement.go MarshalJSON .UTC() | v0.2.8 | VERIFIED | |
| add: -d/--document, -i/--in-place, --file; cascades timestamps; rejects older dates; sets last_updated; version++ | add.go L52-60, L87-112 | v0.4.4 | VERIFIED | |
| merge: filters, cascade, error text, keeps all, sort by vuln then time, merged-vex-sha256(sorted ids ":"), VEX-DOC-i, vex.New version 1 | implementation.go Merge L371-466; statement.go SortStatements; vex.go New (Version: 1) | v0.4.4 / v0.2.8 | VERIFIED | |
| merge has no --file; outputs stdout | merge.go (no outFileOption; newVex.ToJSON(os.Stdout)) | v0.4.4 | VERIFIED | |
| merge help shows --vulnerability but flag is --vuln | merge.go L58; options.go L28 vulnLongFlag = "vuln" | v0.4.4 | VERIFIED | not run; cobra would reject unknown flag (inference, not stated in post) |
| Product matching uses purl comparison | component.go Matches -> PurlMatches | v0.2.8 | VERIFIED | |
| EffectiveStatement returns last matching statement after sort | vex.go L163-180 | v0.2.8 | VERIFIED | |
| Port output: merged-vex-6b33f637...443f; under_investigation -> fixed; effective fixed; order-independent ID | python3 -I merge_port.py run twice | 2026-11-12 | VERIFIED (port) | |
| attest flags --attach/-a implies sign, --sign/-s, --refs/-r; oci purl conversion example; digest lookup; non-oci w/o hashes skipped/err | attest.go L25-150; ctl.go Attest | v0.4.4 | VERIFIED | |
| Predicate type https://openvex.dev/ns/v0.2.0 | go-vex pkg/attestation/predicate.go L16 | v0.2.8 | VERIFIED | |
| filter: SARIF only; generate default .openvex/templates | README; ctl.go DefaultTemplatesPath | v0.4.4 | VERIFIED | |

## Article B: Maersk Cyberattack: Data Stolen From Acquired Legacy System
Slug maersk-cyberattack-legacy-system-data-theft-what-we-know | security-operations | John Marshall | primary keyword: maersk cyberattack | [news]

| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Unauthorized access + data extraction, one local legacy system; isolated; no other systems; no operational impact; customers book as usual | Reuters (Louise Rasmussen) via 1027wbow.com | 2026-11-11 | VERIFIED (two outlets) | Maersk statement |
| "from a previous acquisition"; "Our findings so far strongly suggest no sensitive data has been disclosed"; "isolated to a local system"; APIs and EDI; caution on unexpected communications; published at maersk.com/news | The Register (Connor Jones) | 2026-11-11 | VERIFIED via press; notice not retrieved | |
| Detection date/method/data not disclosed | Register ("Not stated") | 2026-11-11 | VERIFIED (absence) | |
| WhiteArmor: ~100 GB from OCF/LF Logistics; nearly 30,000 driver records, plaintext passwords, 33 super admin accounts, 27,842 device logs; $5M BTC; 30 days; Maersk has not confirmed link | Security Affairs (Paganini) | 2026-11-11 | QUALIFIED (claims) | |
| 16,000+ plaintext driver passwords claim; spelling WhiteArmour; LF Logistics acquired 2022 | Cybernews | undated page | QUALIFIED | |
| NotPetya 2017, ~$300M expected bill | The Register | 2026-11-11 | QUALIFIED (press recap) | context |
Removed: Cybernews' "admin accounts could create/delete orders" (speculative); NotPetya Sandworm attribution (not needed).

## Hero images
- A: Wesley Tingey, stacks of paper documents and file folders (snNHKZ-mGfE / 1583521214690-73421a1829a9). Free Unsplash License; no logos. Page found via WebSearch (pt-br locale page).
- B: Alberto Rodríguez, warehouse interior (-aCrA9FmT8Y / 1684695749267-233af13276d0). Free Unsplash License; no logos (avoided container-ship photos because of carrier branding).
- imageAlt written from previews (images.unsplash.com w=800).

## Next-session candidates
1. [cluster][hub-linked] Alert when a CVE gains KEV or SSVC Exploitation: active by diffing CISA-ADP containers in cvelistV5 delta | guide | turns delta sync into exploitation alerts | cvelistV5 delta.json/deltaLog.json, cisagov/vulnrichment, CVE record ADP containers | must not repeat cvelistv5-delta, cisa-vulnrichment, cve-adp-containers, kev flips
2. [spec] OpenVEX spec v0.2.0 fields that tools ignore: status_notes, action_statement_timestamp, last_updated and statement version | guide | follows today's vexctl post; engineers producing VEX need field semantics | raw openvex/spec OPENVEX-SPEC.md, go-vex v0.2.8 statement.go, trivy v0.76.2 pkg/vex | must not repeat vex-explained, openvex-products-subcomponents, vexctl, cyclonedx-vex
3. [cluster] CVSS v4 in CNA records: Supplemental metrics and the scenarios/format fields in CVE JSON 5.x | guide | engineers parse CNA metrics, not NVD | CVEProject/cve-schema CVE_Record_Format.json, cvelistV5 release zip (count CNAs publishing cvssV4_0) | must not repeat how-to-read-a-cvss-v4-0-vector-string (Oct 17), cvss-vs-epss-vs-kev
News (Article B, trial): fresh 72h story at run time; Maersk follow-up only if Maersk confirms data types or the LF Logistics link (then add a dated Update line).

## Publication status
- Pushed 9f64e4d (posts, covers.tsv, INDEX); fetch-covers workflow committed both cover.jpg files (219adb5). Hugo build clean (581 pages), internal links all resolve.
- Live check: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED (not retried); shell curl blocked. Status: pushed; live not confirmed.
