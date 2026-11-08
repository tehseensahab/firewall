# Editorial log 2026-11-08

Run: scheduled, unattended. First day of the DAILY.md hacking-news trial (Nov 8-22). GSC quick fixes already done (log 2026-11-02), skipped. Guard: how-to-defend-llm-applications-against-prompt-injection carries date 2026-11-08T09:00Z but is a pre-scheduled post (committed 2026-10-27), not a run of today; proceeded. Built with Hugo 0.139.4 extended (zero errors, 501 pages).

News trial: DigiCert data breach | why: well-known CA, fresh (Nov 5-6 coverage), clear engineering lessons (network move removing the only control, self-registration on internal app, authz gap) | primary source: DigiCert's Bugzilla report not retrievable (not returned by WebSearch); gate met via two established outlets (BleepingComputer, The Record) citing it.

## Article A: cvelistv5-delta-json-deltalog-incremental-cve-sync (John Marshall, security-operations) [cluster/spec]
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| deltaLog "normally retains a rolling 30 days"; 15 days during Feb 2026 normalization | cvelistV5 README (raw) | read 2026-11-08 | VERIFIED | |
| Baseline "issued at the end of each day at midnight"; hourly zip "only contains the deltas since the baseline zip file" | cvelistV5 README | 2026-11-08 | VERIFIED | |
| update.yml cron '*/5 * * * *', CVES_DEFAULT_DELTA_LOG_HISTORY_IN_DAYS: 30 | .github/workflows/update.yml (raw) | 2026-11-08 | VERIFIED | |
| new = git not_added / 'A'; updated = modified / 'M' | .github/workflows/dist/index.js calculateDelta | 2026-11-08 | VERIFIED | bundled source |
| delta.json == deltaLog[0]; 684 bytes, 2 changes | raw files, python compare | 2026-11-08 | VERIFIED | |
| 2,870 batches; 17,699 new; 105,062 updated; 0 error; 31,848 distinct; 21,774 repeat; max 118; gaps median 10.2/p90 28.9/max 228.8 min; largest batch 1,417 at 2026-10-13T21:42; numberOfChanges matches lists in all; no (cveId,dateUpdated) repeats; dateUpdated->fetchTime lag median 4.8, max ~102 min; 36.8 MB | deltaLog.json computed with python | 2026-11-08 | VERIFIED | Oct 9-Nov 8 2026 |
| 28/300 sampled new IDs REJECTED today | 300 random new-queue IDs from newest 600 batches, fetched | 2026-11-08 | QUALIFIED | sample, current state |
| 244/299 updated: dateUpdated within 2 min of CISA-ADP; 51 CNA; 4 CVE ADP | 300 random updated IDs, newest 300 batches | 2026-11-08 | QUALIFIED | sample |
| 421,074 CVE JSON files on main | git ls-tree of blob-less clone | 2026-11-08 | VERIFIED | |
| Hourly zip 0300Z: 194 files under deltaCves/, all in deltaLog 00:00-03:30; baseline asset name ends .zip.zip | release download + unzip -l | 2026-11-08 | VERIFIED | |
| Script test: 29 records refreshed from checkpoint 01:47:15.999Z; exits on missing checkpoint; article version re-run (4 records) | ran Python 3 in sandbox | 2026-11-08 | VERIFIED | |
Removed/changed during drafting: an "overlapping fetch windows cause duplicates" hypothesis (data showed no duplicate pairs); "several GB" clone size (unmeasured) replaced by file count.

## Article B: digicert-data-breach-self-registration-archived-customer-data (Craig Leslie, identity-access) [news]
| Claim | Source | Date | Status | Scope |
|---|---|---|---|---|
| "a February 2025 server migration mistakenly exposed an internal business system to the internet"; was VPN-only; self-registration; authz flaw -> read-only archived data; Jun 27-Jul 2 access; Oct 19 confirmation; remediation list | BleepingComputer (Abrams) | 2026-11-05 | VERIFIED (attributed to DigiCert report) | |
| Quotes "externally accessible when that was not intended", "treated as an infrastructure change rather than a security change", "insufficient alerting for new account creation..."; Jul 2 fix; "reportable event"; spokesperson "To our knowledge, there is no evidence of misuse..."; reported to law enforcement; declined to say if attackers made contact | The Record | 2026-11-06 | VERIFIED (attributed) | |
| CA services, CertCentral, DigiCert ONE unaffected; certs and logins secure | BleepingComputer + Cybersecurity News | 2026-11-05 | VERIFIED (DigiCert statement) | |
| Self-registered accounts not subject to staff MFA | Cybersecurity News only | 2026-11-05 | QUALIFIED (single outlet, in not-confirmed table) | |
| June discovery date (18 vs 21) | outlets disagree | | QUALIFIED -> month only | |
| Bugzilla 2084460 primary report | not returned by WebSearch (two queries) | | NOT RETRIEVED; said so in post | |
Removed: "one of the largest public CAs" (unsourced); earlier 2026 DigiCert support-portal incident (not verified this run, left out).

## Images
Both covers previewed (images.unsplash.com) before commit; ids not in covers.tsv. A: Jemima Whyles TfLwDQobhCA (greeting cards on shelves, no legible brand). B: Annie Spratt 5x1ojF3yM6g (open field gate). Alt text written from the previews.

## Next-session candidates
1. [cluster] KEV time-to-listing: days from CVE datePublished to KEV dateAdded, by vendor and year, and what it means for SLA clocks | guide | teams set SLAs from disclosure, KEV clocks start at listing | cisagov/kev-data raw, cvelistV5 release zip (datePublished), deltaLog.json for recent ADP KEV adds | must not repeat cisa-kev-json-feed, cisa-bod-26-04, epss-scores-for-kev-cves (link all + hub)
2. [cluster] Detect when a CVE gains KEV or SSVC Exploitation: active from the cvelistV5 delta: diff the CISA-ADP container between versions | guide | turns today's sync into an alert; 244/299 sampled updates were CISA-ADP | deltaLog.json, cisagov/vulnrichment README, CVE record ADP containers | must not repeat cvelistv5-delta (today), cisa-vulnrichment, cve-adp-containers (link + hub)
3. [cluster] OpenVEX in OCI attestations: trivy --vex oci, cosign attest --type openvex | guide | VEX that travels with the image | trivy docs/guide/supply-chain/vex (raw at tag), sigstore/cosign docs raw, openvex/spec | must not repeat openvex-products-subcomponents, cosign keyless (link both + hub)
News (Article B, trial): pick fresh 72h story at run time; leads seen today: Mercado Bitcoin exchange attack (Nov 2), Michigan State incident (Nov 2), Queens Public Library ransomware (Nov 5), Revolve card breach (Oct 30) via therecord.media.
