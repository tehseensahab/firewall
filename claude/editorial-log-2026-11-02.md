# Editorial log 2026-11-02

Run: scheduled, unattended. Guard note: content/posts/github-actions-oidc-stop-storing-cloud-credentials-in-cicd is dated 2026-11-02T09:00Z, but it is a pre-scheduled post committed 2026-10-17 (3db3406), not an earlier run today, so the run continued.

## GSC quick fixes done
GSC quick fixes done (commit ad84082 "SEO: title/description + internal link fixes"):
1. Titles cut to <=60 chars, keyword first: KEV JSON feed, FortiMail CVE-2026-104286 (dropped the stale "No Patch Yet"), EPSS data feed columns, CISA Vulnrichment SSVC, Argon2id vs bcrypt vs scrypt, SBOM Minimum Elements 2026.
2. Descriptions rewritten to 140-160 chars, answer-first, using only claims already in each post's takeaways (FortiMail: affected branches 7.2/7.4/7.6/8.0 rather than a range that would wrongly include fixed builds).
3. Internal links added: KEV->EPSS; EPSS->Vulnrichment; Vulnrichment->KEV, EPSS; cvss-vs-epss-vs-kev->KEV, EPSS; cve-record-states->KEV; VEX->KEV, Vulnrichment (new "exploitation signals" bullet); SBOM->VEX; MutatingAdmissionPolicy->Sigstore policy-controller guide.
4. Password-hashing post: no relevant cluster target, so no link added (only front matter changed).
5. hugo --minify clean (387 pages), dead internal link check over all posts: 0 dead.

## Articles
A. vulnerability-prioritization-workflow-cve-record-to-patch-ticket | security-operations | John Marshall | [hub] (SEO FOCUS rule 4 satisfied: future cluster posts link here)
B. cve-affected-versions-lessthan-defaultstatus-versiontype | appsec | Craig Leslie | [spec]

## Fact-check A (hub)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| CVE states PUBLISHED/REJECTED | cve-schema CVE_Record_Format.json 5.2.0 | main @ce5f5c8 | VERIFIED | schema |
| CVE-2026-23915 REJECTED 2026-01-20, assigner fortinet, reason "Not used" | cvelistV5 451e97a | 2026-11-02 | VERIFIED | record |
| Vulnrichment "assessing new and recent CVEs"; "At no point will CISA overwrite the originating CNA's data" | cisagov/vulnrichment README | read 2026-11-02 | VERIFIED | |
| KEV 2026.10.30, released 2026-10-30T17:02:45Z, 1,766 entries | kev-data raw | 2026-11-02 | VERIFIED | |
| KEV rows: 104286 added 10-01 due 10-04 Unknown fT Yes; 46300 added 10-28 due 10-31 Unknown fT Yes; 44228 added 2021-12-10 due 12-24 Known | kev-data raw | 2026-11-02 | VERIFIED | |
| EPSS file model v2026.06.15, score_date 2026-11-01T12:00:16Z, 398,784 CVEs; scores 104286 0.04573/0.91621, 46300 0.1613/0.96927, 100419 0.00222/0.1287, 44228 0.99999/1.0 | empiricalsec/epss_scores 2026/epss_scores-2026-11-01.csv.gz (git clone) | 2026-11-01 | VERIFIED (code) | |
| EPSS README "probability [0-1] of exploitation in the wild in the next 30 days"; percentile definition | epss_scores README | read 2026-11-02 | VERIFIED | |
| Deployer: 4 inputs, values, 72 rows; defer 7 / scheduled 42 / out-of-cycle 20 / immediate 3; Immediate only active+open; active scheduled in 6 rows all low/medium HI; active never Defer | CERTCC/SSVC data/csv/ssvc/deployer_patch_application_priority_1_0_0.csv + docs/howto/deployer_tree.md | repo 2026-10-22 | VERIFIED (code) | |
| Outcome definitions (quoted) | deployer_tree.md lines 63-66 | | VERIFIED | |
| Exploitation "present state of exploitation"; PoC (v1) vs Public PoC definitions | SSVC exploitation.md + src exploitation.py | | VERIFIED | |
| CISA ADP uses "poc", deployer table "public poc" | CVE records vs CSV header values | | VERIFIED | mapping is our choice, stated |
| OpenVEX 4 statuses; not_affected needs justification or impact_statement | openvex/spec OPENVEX-SPEC.md | | VERIFIED | |
| Script output table | run Python 3.13; post code diffed identical to run code | 2026-11-02 | VERIFIED | invented assets/VEX labelled |
| KEV updated on weekdays | prior KEV post (kev-data README) | 2026-10-15 | QUALIFIED (relied on earlier verified post) | |

## Fact-check B
| Claim | Primary source | Status |
|---|---|---|
| Field definitions quoted (version "0" convention, lessThan/lessThanOrEqual, changes re-sort, defaultStatus default unknown, * wildcard, packageURL no version, identification/versions requirements) | CVE_Record_Format.json 5.2.0 | VERIFIED |
| semver vs Maven cr1/m1 example; custom "algorithm cannot be executed" | schema/docs/versions.md | VERIFIED |
| Example records 100419, 0821, 100075, 103345, 23915 content | cvelistV5 451e97a | VERIFIED |
| Sample stats (1,000 seeded random of 83,665 2026 files; 16 rejected; 2,061 products; 4,555 versions; 2,831 ranges; all shares) | own code /tmp analysis | VERIFIED (code) |
| original_commit_for_fix not in schema examples | schema versionType examples | VERIFIED |
| Evaluator output | run; post code diffed identical | VERIFIED |
Removed/rewritten: none NOT VERIFIED. Note: the Linux "--numeric original_commit_for_fix" opt-in is labelled as our judgment.

Odd data noticed (not published): CVE-2026-46300 CNA title is "net: skbuff: preserve shared-frag marker during coalescing" while yesterday's candidate note described it as ESP in-place decrypt; its CISA SSVC timestamp is 2026-05-14 with Exploitation active. Re-check before any timely post on it.

## Sources issues today
- epss.empiricalsecurity.com from shell: proxy 403 CONNECT. Workaround: git clone --depth 1 --filter=blob:none --no-checkout github.com/empiricalsec/epss_scores, then git checkout HEAD -- 2026/epss_scores-YYYY-MM-DD.csv.gz.
- cvelistV5 bulk: partial clone gives the file list instantly; per-path git checkout of 1,000 blobs timed out (>2 min); parallel curl of raw paths pinned to a commit (xargs -P 24) fetched 1,000 records in seconds.
- No WebFetch approval prompts today. Live check of firewallsync.com: see below.

## Next-session candidates
1. [cluster] CVE record ADP containers: what CISA-ADP, vendor SADPs and the CVE Program container add, and which to trust | guide | engineers see several "adp" blocks in one record (46300 has redhat-SADP, siemens-SADP, CISA-ADP) and search "cve adp container" | cve-schema CVE_Record_Format.json (adpContainer), cvelistV5 records, vulnrichment README | must not repeat cisa-vulnrichment-how-to-read-ssvc..., cve-affected-versions... (link both + hub)
2. [spec] cpeApplicability in CVE JSON 5.2: how CPE match criteria in a CVE record work and how they differ from NVD configurations | guide | 29.5% of sampled 2026 records carry it; "cpeApplicability cve json" | cve-schema cpeApplicability definition, schema docs, cvelistV5 sample | must not repeat cve-affected-versions... (link it + hub)
3. [cluster] OpenVEX vs CSAF VEX vs CycloneDX VEX: field mapping for not_affected, with a tested converter | guide | teams receive VEX in different formats | openvex/spec, OASIS CSAF 2.0 spec (WebSearch), CycloneDX spec raw | must not repeat vex-explained... (link it + hub)

## Publication status
Pushed to main: ad84082 (quick fixes), 3f77628 (posts), 600db3e (covers, workflow), 6ea807d (alt text). hugo --minify clean; both posts in /tmp/pub/posts; dead-link check 0. Live check: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED (not retried), so live NOT confirmed; owner to spot-check.
