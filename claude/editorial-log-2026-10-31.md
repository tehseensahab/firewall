# Editorial log 2026-10-31

Run: scheduled, unattended. Guard note: content/posts/dependency-confusion-how-package-managers-can-become-an-attack-path is dated 2026-10-31T09:00Z, but it is a pre-scheduled post committed 2026-10-16 (7edc33e), not an earlier run today, so the run continued.

## Published (pushed 04bccb1)

1. ivanti-connect-secure-cve-2026-111357-cve-2026-118527-kev | Ivanti CVE-2026-111357 and CVE-2026-118527: What to Do | security-operations | John Marshall | timely
2. user-supplied-regex-redos-safe-engines | User-Supplied Regex: How to Run It Without ReDoS | appsec | Craig Leslie | guide

Candidates considered: Cisco ASA CVE-2026-76418 (KEV 10-29, deferred), Linux CVE-2026-46300 (deferred), Ivanti KEV additions of 2026-10-30 (picked: newest), untrusted regex guide (picked).

## Fact-check: Ivanti

| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| CVE-2026-111357 and -118527 added to KEV 2026-10-30; due 11-02 / 11-13; triage Yes / No; CWEs 306,862,345 / 340 | kev-data JSON (dateReleased 2026-10-30T17:02Z), script output | 2026-10-30 | VERIFIED | KEV |
| 118527: "remote authenticated attacker to upload files with attacker-controlled content to a known location on disk"; "can be chained with CVE-2026-104935 and CVE-2026-111357" | KEV shortDescription | 2026-10-30 | VERIFIED | |
| 111357: "local authenticated attacker to escalate their privileges"; chained with 104935, 118527 | KEV shortDescription | 2026-10-30 | VERIFIED | |
| 104935 KEV 10-13, due 10-16, CWE-290, triage Yes | KEV | 2026-10-13 | VERIFIED | |
| Required action incl. "discontinue use of the product if mitigations are unavailable"; vendor ref = 104935 advisory | KEV requiredAction / notes | 2026-10-30 | VERIFIED | |
| 104935: "Authentication bypass by spoofing in ICS before version 25.1.3.0 ... does not impact ICS version 22.7R2.14 or prior"; unaffected 25.1.3.0, 25.1.3.1, 22.8R2.5, 22.7R2.14; CVSS 8.6; CNA Ivanti | cvelistV5 CVE-2026-104935 | pub 2026-10-13 | VERIFIED | |
| 111357: "22.8R2.4 mishandles the manner in which the dsinvoked broker trusts DSCache configuration data, leading to privilege escalation to root, as exploited in the wild in October 2026"; CVSS 7.0; CNA mitre; CWE-829 | cvelistV5 CVE-2026-111357 | updated 2026-10-31T03:56Z | VERIFIED | |
| 118527 no CVE record | cvelistV5 path 118xxx -> 404 | 2026-10-31 | VERIFIED (absence) | |
| Per-branch fixes incl. 25.1.1.2; Ivanti "reliable indicators of compromise are not available" | Rapid7 ETR (updated 2026-10-13) | 2026-10-13 | QUALIFIED (secondary) | 25.1.1.2 not in CVE record |
| Two of three flaws fixed at disclosure; third (privesc) unfixed; "in the coming weeks"; 22.8R2.4 fully patched; UTA0576; began Oct 3; LDAP creds, AD password search, spraying; low-confidence criminal; IOCs welcome.cgi, X-DSCGI-PATH, /data/.icscap/ (not used), 108.165.147[.]64; ICT misses chain | The Hacker News 2026-10-13 citing Volexity | 2026-10-13 | QUALIFIED (press) | |
| No malware or web shells; Ivanti quote "limited number of customers" (not used) | The Register 2026-10-14 | 2026-10-14 | QUALIFIED (press) | |
| Cyber Centre Update 1: "Open-source reporting indicates that CVE-2026-111357 is being exploited in the wild" | cyber.gc.ca AV26-1035 (updated 2026-10-16) | 2026-10-16 | VERIFIED | |
| CSA SG: only 104935 named; "update to the latest versions" | csa.gov.sg AL-2026-147 (updated 2026-10-30) | 2026-10-30 | VERIFIED | |
| No public fix for 111357/118527 | absence across above | 2026-10-31 | QUALIFIED | flagged in article |
| Removed: cyber.gc.ca "25.2.2 and prior" (conflicts with other sources), Register "July 25.1.3.0 patched a portion" | | | REMOVED | |

## Fact-check: regex

| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| ^(a+)+$ timings 0.0088/0.0429/0.1680/0.5356 s (n=18..24); possessive ~5 us; 40 chars ~9.75 h extrapolated | own test, Python 3.13.18 | 2026-10-31 | VERIFIED | sandbox |
| Node 22.23.4: 495 ms on 24 chars; l flag with --enable-experimental-regexp-engine ~2.6 ms on 50k | own test | 2026-10-31 | VERIFIED | |
| google-re2 1.1.20251105: 1M chars ~2 ms; backreference and look-ahead rejected with quoted errors; stderr logging | own test | 2026-10-31 | VERIFIED | |
| Worker: timeout at 103 ms; 25.4 ms/call over 20 | own test | 2026-10-31 | VERIFIED | |
| OWASP evil regex conditions/examples; "the attacker can inject an Evil Regex" | wiki.owasp.org (archived); owasp.org redirect to community.owasp.org hit PROVENANCE_REQUIRED | n/a | VERIFIED (archived) | |
| RE2 quotes (untrusted users, linear, budget, no backtracking-only constructs) | google/re2 README raw | main | VERIFIED | |
| Go "guaranteed to run in time linear in the size of the input" | golang/go src/regexp/regexp.go raw | master | VERIFIED | |
| Rust O(m * n); "to a certain extent, supports untrusted patterns"; size_limit | rust-lang/regex README + src/lib.rs raw | master | VERIFIED | |
| .NET "does not offer protection against untrusted patterns"; "not intended as a security boundary"; NonBacktracking .NET 7 | dotnet/docs best-practices-regex.md raw | main | VERIFIED | |
| Ruby 3.2 memoization ~90%, memory, Regexp.timeout, timeout keyword | ruby-lang news 2022-12-25 raw | 2022-12-25 | VERIFIED | |
| Python 3.11 possessive/atomic; no timeout in re docs (grep count 0) | cpython Doc/library/re.rst raw | main | VERIFIED | |
| V8 v8.8 experimental engine, flags, l flag, "orders of magnitude faster" | v8/v8.dev src/blog/non-backtracking-regexp.md raw | 2021-01-11 | VERIFIED | |
| Removed: Java/PCRE as backtracking (not sourced today); Ruby listed as backtracking | | | REMOVED | |

## Skipped / blocked
- community.owasp.org (redirect target of owasp.org ReDoS page): PROVENANCE_REQUIRED, not retried; used wiki.owasp.org.
- Ivanti advisory (hub.ivanti.com) and Volexity blog: not returned by WebSearch; not fetched.
- RE2 Options.max_mem test inconclusive (compiled at 64 KB); claim not used.

## Next-session candidates
1. Cisco ASA/FTD CVE-2026-76418 tunnel DoS: fixed releases and checks | timely | admins search "CVE-2026-76418 fixed release" (KEV 2026-10-29, due 11-01) | KEV raw; cvelistV5 cves/2026/76xxx/CVE-2026-76418.json; Cisco advisory cisco-sa-asaftd-tunnel-dos-s6mgkb75 via WebSearch | must not repeat cisco-catalyst-sd-wan-manager-cve-2026-76504 (link it)
2. VMware ESX CVE-2026-41709 insufficient logging (KEV 2026-10-28, due 11-11): what it hides and how to compensate | timely | "CVE-2026-41709 ESXi logging" | KEV raw; cvelistV5 cves/2026/41xxx/CVE-2026-41709.json; Broadcom VMSA via WebSearch | must not repeat logging-for-incidents-not-for-dashboards (link it)
3. Escaping user input in regex and search: re.escape, RegExp escaping, LIKE wildcards | guide (appsec) | devs search "escape user input regex" / "new RegExp user input" | cpython re.rst raw (re.escape); tc39 RegExp.escape proposal / MDN via WebSearch; node doc api raw | must not repeat user-supplied-regex-redos-safe-engines (link it)
