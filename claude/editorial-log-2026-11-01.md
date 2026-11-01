# Editorial log 2026-11-01

## Published (pushed; live not confirmed: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED, not retried)
1. vmware-esx-cve-2026-41709-insufficient-logging-kev | security-operations | John Marshall | timely (KEV 2026-10-28)
2. escape-user-input-regex-sql-like | appsec | Craig Leslie | evergreen guide, tested code

## Topic selection
- Candidates from 10-31 log: Cisco ASA/FTD CVE-2026-76418, VMware ESX CVE-2026-41709, regex/LIKE escaping.
- DROPPED at source check: Cisco CVE-2026-76418. CVE record has no fixed-release list; Cisco advisory (cisco-sa-asaftd-tunnel-dos-s6mgkb75) not returned by WebSearch (two queries). Only securityonline.info (press) gave fixed releases (ASA 9.16.4.104, 9.18.4.96, 9.20.4.50, 9.22.3.200, 9.23.1.48, 9.24.1.27, 9.24.10.1; FTD 7.0.11, 7.2.13, 7.4.9, 7.6.7, 7.7.14, 10.0.3, 10.1.1) and mitigation (no secondary-authentication-server-group). Core claim of a "fixed releases" article not verifiable from primary -> held. KEV due date 2026-11-01 has now passed.

## Fact-check: Article 1 (CVE-2026-41709)
Claim | Primary source | Source date | Status | Scope
- "VMware ESX contains an insufficient logging vulnerability" / "A malicious administrator could exploit this issue to perform certain operations without them being logged." | Broadcom VMSA-2026-0006 sec 3e (support.broadcom.com .../38017) | updated 2026-08-19 | VERIFIED | quote
- CVSS 2.7 AV:N/AC:L/PR:H/UI:N/S:U/C:N/I:L/A:N Low | VMSA + cvelistV5 metrics.cvssV3_1 | 2026-10-29 | VERIFIED
- CWE-778 | cvelistV5 problemTypes | VERIFIED
- Fixed: ESXi80U3j-25429389; ESXi-9.0.2.0100-25595025; ESXi-9.1.0.0-25370933; VCF 5.x 5.2.4; TCP 5.0.x/5.1.x KB449886 | VMSA response matrix; cvelistV5 affected lessThan values | VERIFIED
- No ESX 7.0 entry for this CVE; 0006.2 added 7.0 guidance "for Critical severity issues" | cvelistV5 affected; VMSA change log | VERIFIED
- Workaround "None"; credit Ian Barton of CrowdStrike | VMSA | VERIFIED
- Published 2026-07-29 (VMSA), CVE datePublished 2026-07-30 | VMSA; cveMetadata | VERIFIED
- KEV dateAdded 2026-10-28, dueDate 2026-11-11, knownRansomwareCampaignUse Unknown, forensicTriage No | kev-data catalogVersion 2026.10.30 | VERIFIED
- 90 days fix-to-KEV | computed python (2026-07-30 -> 2026-10-28) | VERIFIED (summary uses "90 days after Broadcom fixed it"; strictly 91 from 07-29 advisory; CVE record date used) -> post now says "three months"
- SSVC Exploitation active / Automatable no / Technical Impact partial | cvelistV5 CISA ADP | VERIFIED
- CVE-2026-59310 (vCenter syslog dir traversal, same VMSA) KEV 2026-08-18 | kev-data; VMSA | VERIFIED
- Syslog commands + loghost formats + "by default ... local scratch volume or a ramdisk" | Broadcom KB 318939 | no updated date shown | VERIFIED (not run by us; stated in post)
- Log file descriptions (shell.log, auth.log, hostd.log, vpxa.log, syslog.log, vobd.log) | Broadcom KB 306962 | VERIFIED
- `esxcli system version get` prints version/build | not from a fetched source | QUALIFIED (standard esxcli command; owner may spot-check)
- Exploited to hide post-compromise activity | none | QUALIFIED, labelled editorial interpretation
- No public technical write-up / exploitation details | WebSearch 2026-11-01 found none | QUALIFIED ("we found no ... as of 1 November")
- REMOVED: unsourced claim that hypervisor-focused ransomware/espionage groups aim for ESX admin access; Summary-tab build location claim.

## Fact-check: Article 2 (regex / LIKE escaping)
Tested: Python 3.13.18, Node 24.22.2 (V8 13.6, via npm package node@24) and 22.23.4, Go 1.24.7, SQLite 3.53.1, PostgreSQL 16.15 (local initdb). Scripts in session scratchpad (esc.py, esc.mjs, q.go, pg.sql).
- re.escape doc quotes incl. 3.7 change and sub() replacement warning | cpython main Doc/library/re.rst (raw) | VERIFIED
- QuoteMeta doc quote | golang/go master src/regexp/regexp.go L698-700 | VERIFIED
- RegExp.escape description, \x leading-char rule, "don't try to re-implement", Baseline 2025 | MDN page (WebFetch) | VERIFIED
- Node 24 has RegExp.escape, Node 22 does not | tested | VERIFIED
- Fallback escaper after \1: '(a)\11' test("aa1") false; RegExp.escape '(a)\1\x31' true | tested | VERIFIED
- Fallback inside [...]: "[a-z]" matches m; RegExp.escape "[\x61\x2dz]" matches -, not m | tested | VERIFIED
- JS replace "$&$&" -> 'Hello NAMENAME'; function -> 'Hello $&$&' | tested | VERIFIED
- Python re.sub(r"C:\new\1") -> re.error invalid group reference 1 at position 7; lambda returns literal | tested | VERIFIED
- LIKE table results (SQLite naive/escaped/escaped-without-ESCAPE; Postgres escaped default backslash) | tested | VERIFIED
- SQLite 'ALICE' LIKE 'alice' = 1; Postgres LIKE false / ILIKE true | tested | VERIFIED
- Postgres "default escape character is the backslash", ESCAPE '' disables, "Be wary of accepting regular-expression search patterns from hostile sources" | crunchydata mirror of PostgreSQL 17.1 docs (current postgresql.org page not returned by WebSearch) | QUALIFIED (mirror; text stable since 7.x per 7.3 page)
- REMOVED: "slow full scan" claim (a leading-% LIKE scans anyway); allowlist example that did not fit the user-text case.

## QC
- hugo --minify: 0 errors; both posts built; internal href check: 0 dead links. Internal links all to posts dated <= 2026-11-01.
- Titles 52 / 53 chars; descriptions 151 / 154.
- Cover: first ESX pick (rvVhr2LngP4) was already in covers.tsv (used by kubernetes-audit-policy...) and was removed before push; second pick (wV-rsscmADs) showed a historic religious manuscript, judged unsuitable and replaced with padlocks (h_YJOfuRyD0). Alt texts rewritten from the actual cover.jpg.
- Pre-existing duplicate photo ids in covers.tsv (not from today): 1594915440248-1e419eba6611, 1698668975271-2ba9a323be6b. Owner may want to swap one of each.

## Next-session candidates
1. Linux kernel CVE-2026-46300 (ESP in-place decrypt of shared skb fragments; KEV 2026-10-28, forensicTriage Yes): which kernels are fixed and how to check | timely | engineers search "CVE-2026-46300 kernel fix" | KEV raw (shortDescription, chain with CVE-2026-109618/109619); cvelistV5 cves/2026/46xxx/CVE-2026-46300.json; git.kernel.org stable commit (from KEV notes, reach via WebSearch); distro trackers via WebSearch | must not repeat php2shell-cve-2026-109618-cve-2026-109619-patch-and-hunt (link it)
2. Forwarding ESXi and vCenter logs to a SIEM over TLS: a tested-config checklist | guide (security-operations or cloud-security) | admins search "esxi syslog ssl" / "esxi remote syslog not working" | Broadcom KB 318939, KB 324268 (syslog over SSL), KB 306962 (log files), KB 421596 (8.0 log formats) via WebSearch | must not repeat vmware-esx-cve-2026-41709-insufficient-logging-kev, logging-for-incidents-not-for-dashboards (link both)
3. Cisco ASA/FTD CVE-2026-76418 SSL VPN DoS: retry only if the Cisco advisory page comes back in WebSearch | timely | "CVE-2026-76418 fixed release" | cvelistV5 cves/2026/76xxx/CVE-2026-76418.json (affected list, exploitation note); KEV raw; Cisco advisory via WebSearch | must not repeat cisco-catalyst-sd-wan-manager-cve-2026-76504
