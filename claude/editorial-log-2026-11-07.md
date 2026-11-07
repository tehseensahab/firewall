# Editorial log 2026-11-07

Run: scheduled, unattended. GSC quick fixes already done (log 2026-11-02), skipped. Guard: prompt-injection-explained... carries date 2026-11-07T09:00Z but is a pre-scheduled post committed 2026-10-26 (91081b9), not a run of today; proceeded.

## Topic selection
- 11-06 candidates: (1) CVE versions[].changes [spec] dropped: 0 of 7,987 2026 kernel records use changes and cve-affected-versions already covers it. (2) OpenVEX in OCI [cluster] deferred (3 VEX posts in 4 days). (3) KEV vs EPSS coverage audit [cluster] taken, extended with a day-by-day lag study.
- Article A re-scoped to Linux kernel CNA records (distinct intent: "is my kernel affected"; cve-affected-versions uses CVE-2026-100075 as one example of the generic algorithm, cpeApplicability post shows CPE over-match with one example). New: two-entry structure counts, 1,056-record git-entry semver trap, corpus-wide CPE over-match 97.4%.
- Timely: no (VMware 11-01 and WordPress 11-04 already make 2 timely posts this week).
- Source check: cvelistV5 release zip 200 (cve_2026-11-07_0400Z); kev-data raw 200; epss_scores partial clone 200; kernel Documentation/process/cve.rst raw 200; git.kernel.org 403 CONNECT.

## Article A: linux-kernel-cve-records-affected-versions-stable-branches (Craig Leslie, appsec)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 7,987 Linux CNA PUBLISHED CVE-2026-* records, datePublished 2026-01-21..2026-11-06; all have 2 affected entries, stable repo, programFiles, cpeApplicability; 3,154 CNA cvssV3_1 | cvelistV5 bulk export 2026-11-07 (kstats.py) | 2026-11-07 | VERIFIED (computed) | 2026 IDs only |
| 7,923 entry[0] defaultStatus unaffected + entry[1] affected; 64 both unaffected | same | | VERIFIED (computed) | |
| 7,911 version entries start with exact introducing release + 0..intro unaffected; 7,917 end with original_commit_for_fix ..* | same | | VERIFIED (computed) | |
| 1,084 records with semver ranges in entry[0]; 1,056 records / 3,136 ranges where entry[1] alone says unaffected | kcorpus.py | | VERIFIED (computed) | |
| 36,296 fixed stable releases in X.Y.* unaffected ranges; 35,340 (97.4%) matched by OR'd cpeApplicability; 7,917 records | kcorpus.py | | VERIFIED (computed) | |
| CVE-2026-99190 entries, refs, programFiles, published 2026-10-28; CVE-2026-100075 CPE ranges | cvelistV5 records | | VERIFIED | |
| Checker output for 7 versions | kernel_affected.py run, Python 3.12 | 2026-11-07 | VERIFIED (tested) | |
| Schema: first-match algorithm, defaultStatus default unknown, "*" = "arbitrarily large number", repo "to resolve git hash version ranges", versionType examples | cve-schema CVE_Record_Format.json main | read 2026-11-07 | VERIFIED | |
| Kernel CVE doc quotes (assignment after fix in stable, original fix commit, only supported branches, "overly cautious", applicability up to user, take all changes) | torvalds/linux Documentation/process/cve.rst (docs.kernel.org/process/cve.html) | master 2026-11-07 | VERIFIED | |
| Longterm branches 6.18/6.12/6.6/6.1/5.15/5.10; "anything at all after the dash" = distro kernel | kernel.org/releases.html (WebFetch) | 2026-11-07 | VERIFIED | |
| original_commit_for_fix meaning | no definition found (schema, kernel doc, circl.lu page) | | QUALIFIED (stated as our reading) | |
| d73d2a = stable backport explanation | inference from record | | QUALIFIED (stated as inference) | |
| Removed: "non-longterm branches stop receiving fixes so stay affected" (not sourced) | | | REMOVED | |

## Article B: epss-scores-for-kev-cves-low-after-listing-threshold-audit (John Marshall, security-operations)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| KEV 2026.11.06, 1,769 entries, released 2026-11-06T19:44:45Z | kev-data raw | 2026-11-07 | VERIFIED | |
| EPSS 2026-11-06 v2026.06.15, 400,985 rows; 1 KEV unscored (CVE-2026-19868) | epss_scores | | VERIFIED (computed) | |
| Below-cutoff counts 861/436/307/54; pct<0.9 248, <0.95 405; median 0.5356, pct 0.98998 | kev_epss.py / kev_epss2.py | | VERIFIED (computed) | |
| Age buckets 106/52, 207/57, 1455/327; medians 0.1037/0.4443/0.5832 | kev_epss_audit.py, kev_epss2.py | | VERIFIED (computed) | |
| Per-CVE scores WordPress/Ivanti/VMware | EPSS 2026-11-06 | | VERIFIED (computed) | |
| 113 entries 06-16..10-07; day -1 77/15, day 0 91/15, +7 113/38, +30 113/68; medians; 15 already; 64 crossed later median 14d, 23 <=7d; 34 never (36-115 days) | lag.py over 145 v5 files (header asserted v2026.06.15) | | VERIFIED (computed) | |
| KEV criterion quote | cisa.gov/known-exploited-vulnerabilities (WebFetch) | 2026-11-07 | VERIFIED | |
| EPSS column definition, 30 days | epss_scores README | | VERIFIED | |
| RBP guide quotes + FIRST FAQ "supersede" | riskbasedprioritization.github.io EPSS_and_CISA_KEV | | QUALIFIED (community guide; FIRST quote secondhand) | |

## Publication
- Pushed a8531c6 (posts, INDEX rows, covers.tsv); fetch-covers committed 7fa3180. Covers viewed: alts match (hourglass alt refined).
- Build: hugo --minify 0 errors, both posts present, 0 dead /posts/ links.
- Live check: WebFetch firewallsync.com/posts/linux-kernel-...?v=a8531c6 -> PROVENANCE_REQUIRED (not retried). Live not confirmed.

## Next-session candidates
1. [cluster] KEV time-to-listing: days from CVE datePublished to KEV dateAdded, by vendor and year, and what it means for SLA clocks | guide | teams set SLAs from disclosure, KEV clocks start at listing | cisagov/kev-data raw, cvelistV5 release zip (datePublished), empiricalsec/epss_scores | must not repeat cisa-kev-json-feed, cisa-bod-26-04, epss-scores-for-kev-cves (link all + hub)
2. [spec] cvelistV5 deltas: delta.json / deltaLog.json and hourly releases, how to sync CVE record changes incrementally | guide | anyone mirroring CVE data needs incremental updates | cvelistV5 README + cves/delta.json, deltaLog.json (raw), release tags | must not repeat cve-record-states, cve-adp-containers (link + hub)
3. [cluster] OpenVEX in OCI attestations: trivy --vex oci, cosign attest --type openvex | guide | VEX that travels with the image | trivy docs/guide/supply-chain/vex/oci.md (raw at tag), sigstore/cosign docs raw, openvex/spec | must not repeat openvex-products-subcomponents, cosign keyless (link both + hub)
