# Editorial log 2026-10-30

## Published (pushed f9388a6)
1. gitlab-cve-2026-97229-ci-regex-rce-patch-and-hunt | security-operations | John Marshall | timely (KEV 2026-10-29)
2. secure-file-upload-nodejs-express-multer | appsec | Craig Leslie | guide (from candidate 3 of 2026-10-29)

## Topic selection
- Source check: KEV raw (catalog 2026.10.29) showed new 10-29 additions GitLab CVE-2026-97229 and Cisco ASA/FTD CVE-2026-76418. GitLab chosen (unauth RCE, CVSS 10, dev/DevSecOps audience, primary sources reachable: CVE records, GitLab release posts, Ruby advisory raw on GitHub).
- Not chosen today (kept as candidates): Linux CVE-2026-46300, Cisco ASA CVE-2026-76418, VMware ESX CVE-2026-41709.

## Fact-check: Article 1 (GitLab)
Claim | Primary source | Source date | Status | Scope
---|---|---|---|---
KEV added 2026-10-29, due 2026-11-01, cwes [CWE-190], forensicTriage Yes, ransomware Unknown | kev-data JSON fields | catalog 2026.10.29 | VERIFIED | federal deadline
"could have allowed an unauthenticated user to execute arbitrary code ... via a specially crafted regular expression in a CI/CD configuration, due to insufficient regular expression validation" | GitLab 19.4.2 release post (WebFetch) + CVE record description | 2026-10-12 | VERIFIED | CE/EE self-managed
CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H = 10 | CVE record metrics | dateUpdated 2026-10-30 | VERIFIED |
Affected 19.2<19.2.8, 19.3<19.3.5, 19.4<19.4.2 | CVE record affected[] | 2026-10-30 | VERIFIED | (release post title says 19.3.4 in search snippet; body says "versions 19.4.2, 19.3.5, 19.2.8" -> used record + body)
"GitLab.com is already running the patched version"; Dedicated patched before release | 19.4.2 release post | 2026-10-12 | VERIFIED |
Six detections (names + file names under gitlab-security-oss/tldr) | 19.4.2 release post | 2026-10-12 | VERIFIED | not reproduced by us
CVE-2026-110264 affected 7.0<18.11.13 ... 19.5<19.5.1, unauth, 10.0 | CVE record + 19.5.1 post ("On October 21, 2026, we released versions 19.5.1, 19.4.3, 19.3.6, 19.2.9, 19.1.9, 19.0.10, 18.11.13") | 2026-10-21 | VERIFIED |
19.5.1 detections "Onigmo native worker crash", "Org mode render error burst"; no workaround | 19.5.1 post | 2026-10-21 | VERIFIED |
CVE-2026-89078 / -93577 authenticated, 9.9, ranges <19.2.7/<19.3.3/<19.4.1 | CVE records | 2026-09-23 | VERIFIED |
SSVC Exploitation active (97229), none (others) | CISA ADP in records | 2026-10-13 / 09-24 / 10-21 | VERIFIED | as of CISA timestamps
Ruby quotes ("GitLab compiles regular expressions supplied by its users...", "These bugs are reached only when...", "Regexp.timeout does not protect...", "Limiting the length...") ; fix PR #19020; Ruby 4.0.9/3.4.12/3.3.13; no Ruby CVEs requested | raw ruby/www.ruby-lang.org en/news/_posts/2026-10-23-regexp-fixes-for-gitlab-cves.md | 2026-10-23 | VERIFIED |
Version API GET /api/v4/version with PRIVATE-TOKEN | docs.gitlab.com/ee/api/version (WebFetch) | current | VERIFIED |
CI Lint as unauth path | inferred from detection names | - | QUALIFIED (labelled as our interpretation) |
Exploitation details / exposed-instance counts | none found (it-connect.tech had none; bleepingcomputer fetch failed) | - | NOT VERIFIED -> not claimed |
Version-check script output | run with python3.13 -I on the exact code block | 2026-10-30 | VERIFIED |
grep for Regexp.new/union/compile and /#{...}/ | run on sample .rb file (3 of 3 dynamic patterns matched, static /abc/ not) | 2026-10-30 | VERIFIED | illustrative

## Fact-check: Article 2 (file uploads)
Claim | Primary source | Source date | Status | Scope
---|---|---|---|---
"There is no silver bullet in validating user content"; Content-Type "trivial to spoof"; extension bypass list; storage order; AllowOverride None; image re-encode + "itself handles untrusted input" | raw OWASP CheatSheetSeries File_Upload_Cheat_Sheet.md | master 2026-10-30 | VERIFIED |
Multer limits defaults Infinity (fileSize, files, parts, fields); "Limits apply to the whole request; there is no per-file limit"; "Never add multer as a global middleware" | node_modules/multer/README.md v2.5.0 | npm 2026-10-30 | VERIFIED |
file-type: "best-effort hint ... does not guarantee"; "not text-based formats like .txt, .csv, .svg"; worker thread with timeout | node_modules/file-type/readme.md v22.3.0 | npm 2026-10-30 | VERIFIED |
sharp strips metadata by default; limitInputPixels default 268402689 | sharp 0.35.5 lib/index.d.ts | npm 2026-10-30 | VERIFIED |
24 KEV entries with CWE-434, 8 added 2026 | kev-data catalog 2026.10.29, python count | 2026-10-29 | VERIFIED | floor (cwes not always set)
10 curl tests (201/415/415/201 polyglot/413/400/401/200+headers/404/404), files mode 0600 | our run: node 22.23.4, express 5.3.0, multer 2.5.0, file-type 22.3.0 | 2026-10-30 | VERIFIED | code in post = tested server.js (diff: comment line only)
sharp re-encode: 97-byte polyglot with <?php -> 90-byte output without it | our run | 2026-10-30 | VERIFIED |

## Skipped / issues
- bleepingcomputer.com article fetch: client_error (site), not retried.
- No approval prompts hit.
- Live check: WebFetch firewallsync.com -> PROVENANCE_REQUIRED (not retried). Status: pushed (f9388a6, covers e98f8d7); live not confirmed. Build passed locally (hugo 0.152.2, zero errors, no dead internal links).
- Covers: fetch-covers workflow committed both cover.jpg (e98f8d7); alt text written from preview of the same Unsplash images.

## Next-session candidates
1. Cisco ASA/FTD CVE-2026-76418 tunnel DoS (KEV 2026-10-29, due 2026-11-01) | timely | firewall admins search "CVE-2026-76418 fixed release" | KEV raw; cvelistV5 cves/2026/76xxx/CVE-2026-76418.json; Cisco advisory cisco-sa-asaftd-tunnel-dos-s6mgkb75 via WebSearch | must not repeat: cisco-catalyst-sd-wan-manager-cve-2026-76504 (link it)
2. Linux kernel CVE-2026-46300 ESP shared-fragment decrypt (KEV 2026-10-28, chained with PHP2Shell) | timely | "CVE-2026-46300 fixed kernel version" | KEV raw (notes: git.kernel.org stable commit); cvelistV5 cves/2026/46xxx/CVE-2026-46300.json; distro trackers via WebSearch | must not repeat: php2shell-cve-2026-109618 (link it)
3. Untrusted regular expressions: ReDoS vs engine bugs, safe user-pattern features (RE2, timeouts, Ruby/Node/Python) | guide (appsec) | devs search "regex from user input safe" | Ruby advisory raw (ruby/www.ruby-lang.org); OWASP ReDoS page / cheat sheets raw; node doc api via raw nodejs/node tag | must not repeat: gitlab-cve-2026-97229 (link it)
