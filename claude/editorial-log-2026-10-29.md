# Editorial log 2026-10-29

## Published (pushed)
1. magento-cve-2026-48356-polyshell-patch-and-hunt | security-operations | Craig Leslie | primary kw: magento cve-2026-48356
2. nodejs-decompression-bomb-zlib-limits | appsec | John Marshall | primary kw: node.js decompression bomb

Candidates dropped at source check: none. Ivanti CVE-2026-104935 carried forward (not researched today).

## Fact-check: Magento CVE-2026-48356
| Claim | Primary source | Source date / effective | Status | Scope |
|---|---|---|---|---|
| KEV dateAdded 2026-10-27, dueDate 2026-11-10, knownRansomwareCampaignUse "Unknown", cwes CWE-434, forensicTriage "No" | kev-data JSON fields (catalogVersion 2026.10.28) | 2026-10-28 | VERIFIED | federal deadline |
| Affected lists (Commerce <=2.4.9, 2.4.8-p5, 2.4.7-p10, 2.4.6-p15, 2.4.5-p17, 2.4.4-p18; OS <=2.4.9..2.4.6-p15; B2B; Events <=1.20.0) and unaffected 2026-jul / 1.21.0 | cvelistV5 CVE-2026-48356 affected[] | updated 2026-10-28 | VERIFIED | |
| CVSS 3.1 9.3 CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:H/I:H/A:N; "requires user interaction in that a victim must visit a maliciously crafted URL..." | CVE record cna.metrics / descriptions | 2026-08-27 (CNA) | VERIFIED | |
| CISA ADP SSVC Exploitation "active", refs Sansec | CVE record adp | 2026-10-28 | VERIFIED | |
| Bulletin published July 14 2026, "Last updated on 14 July 2026", priority 2, 9.6 A:L, impact "Privilege escalation", "Adobe is not aware of any exploits in the wild" | helpx.adobe.com/au/... APSB26-73 (regional copy) | 2026-07-14 | QUALIFIED (regional copy; adobe.com/trust URL hit PROVENANCE_REQUIRED, not retried) | |
| Guest-cart REST routes; uploads to pub/media/custom_options/quote/; GraphQL not vulnerable; RCE conditions; 2.4.9 fix May 12; July 14 backport via APSB26-73 | sansec.io/research/magento-polyshell | 2026-03-17 + updates | QUALIFIED (researcher) | |
| 471 stores in one hour March 30 2026; accesson.php; lanhd6549tdhse[.]top | sansec.io/research/polyshell-mass-attack-wave | 2026-03-30 | QUALIFIED | |
| 953 stores since July 2025; 471 via CVE-2026-48356; ~102 via PolyShell or CVE-2025-54236; 2.4.7-p10 rogue admin; PNG webshells in custom_options/quote; loader domains | thehackernews.com 2026-10-26 citing Sansec | 2026-10-26 | QUALIFIED (press) | |
| Stock nginx.conf.sample denies /media/custom_options/, PHP only for named entry points, banned .php regex; custom_options/.htaccess Require all denied | magento/magento2 2.4-develop raw | 2026-10-29 | VERIFIED | 2.4-develop branch |
| cms_block / cms_page / admin_user columns | Magento Cms + User db_schema.xml raw | 2026-10-29 | VERIFIED | |
| find/grep commands and SQL run | mock tree + SQLite | 2026-10-29 | VERIFIED (tested, mock) | |
Removed/rewritten: claim that OS 2.4.4/2.4.5 "have no fixed build" rewritten (record lists neither affected nor fixed for those OS lines). Discrepancy noted in post: CVE record lists 2.4.9 as affected vs Sansec "2.4.9 contains the fix".

## Fact-check: Node.js decompression bombs
| Claim | Primary source | Source date / effective | Status | Scope |
|---|---|---|---|---|
| maxOutputLength "Limits output size when using [convenience methods]"; default buffer.kMaxLength (zlib, Brotli, Zstd options) | nodejs/node v22.23.4 doc/api/zlib.md | v22.23.4 | VERIFIED | |
| zstd added v22.15.0; ZstdOptions Stability 1 Experimental | same | v22.23.4 | VERIFIED | |
| 100 MiB zeros -> gzip 101,941 / zstd 3,219 / brotli 172 bytes; ratios 1029 / 32575 / 609637 | test bomb.js, node 22.23.4 | 2026-10-29 | VERIFIED (tested) | |
| *Sync and async gunzip throw RangeError ERR_BUFFER_TOO_LARGE "Cannot create a Buffer larger than 1048576 bytes" | bomb.js | 2026-10-29 | VERIFIED | |
| createGunzip({maxOutputLength:1MiB}) passed 104,857,600 bytes, no error | bomb.js | 2026-10-29 | VERIFIED | |
| byteLimit Transform stops at 1,048,576 bytes with ERR_DECOMPRESSED_TOO_LARGE | limit.js | 2026-10-29 | VERIFIED | |
| express.json() 413 for gzip 10,232 / br 41 / zstd 355 bytes; inflate:false 415 encoding.unsupported | express-test.js, express 5.3.0, body-parser 2.4.0, raw-body 3.0.2 | 2026-10-29 | VERIFIED | |
| body-parser decodes deflate/gzip/br/zstd (if supported); inflate default true; limit '100kb'; 5 MB README warning | node_modules/body-parser lib/read.js + README | 2.4.0 | VERIFIED | |
| fetch(): content-length 101941, arrayBuffer 104,857,600; readCapped throws | fetch-test.js | 2026-10-29 | VERIFIED | |
| Brotli CVE-2026-111497 fixed in Node 22.23.4 / 24.22.1 / 26.12.1 | 2026-10-28 log (Node advisory) | 2026-10-28 | VERIFIED (prior run) | |
| CWE-409 title | multiple CWE mirrors via WebSearch | 2026-10-29 | VERIFIED (title only) | |
Removed: none. rejectGarbageAfterEnd (v24.19/v26.5 per main docs) left out; untested.

## Images
- magento: Unsplash yZLtvPLNlw4 (photo-1717568511299-003b41c20816), ERIC ZHU, shopping carts; previewed, no logos visible.
- nodejs: Unsplash tA30zkMCx-g (photo-1741939401889-5dd17bfc64a8), Deniz Demirci, weir; previewed.
- Rejected: hot-air balloon 8ltubJ2NPy0 (dark, low detail); FkjdtBsNyeA (Unsplash+); ZswMkFdiXKo (hay, too close to 10-28 cover).

## QC
Local Hugo v0.152.2: 0 errors, 90 post pages, both new pages present, 0 dead /posts/ links. Titles 50/50 chars; descriptions 152/147.

## Publication status
Pushed 3c2427f (posts, INDEX, covers.tsv). Live status: see below.

## Next-session candidates
1. Linux kernel CVE-2026-46300 (ESP in-place decrypt of shared page-cache fragments; KEV 2026-10-28, chained with PHP2Shell) | timely | Linux admins search "CVE-2026-46300 fixed kernel" | KEV raw; cvelistV5 cves/2026/46xxx/CVE-2026-46300.json; kernel.org stable commits via CVE record refs; distro trackers via WebSearch | must not repeat: php2shell-cve-2026-109618 post (link to it)
2. VMware ESX CVE-2026-41709 insufficient logging (KEV 2026-10-28) | timely | vSphere admins: "which ESX operations aren't logged, what to monitor" | KEV raw; cvelistV5 cves/2026/41xxx/CVE-2026-41709.json; Broadcom VMSA via WebSearch | must not repeat: none (new vendor); link cvss-vs-epss-vs-kev
3. Secure file uploads: store outside the webroot, never execute, validate content (PHP + Node) | guide (appsec) | follows PolyShell; devs search "secure file upload best practices" | OWASP File Upload cheat sheet raw; magento nginx.conf.sample raw; php doc-en ini.core (file_uploads, upload_max_filesize) | must not repeat: magento-cve-2026-48356, php-ini-security-hardening posts
4. (carried) Ivanti Connect Secure CVE-2026-104935 | timely-ish | cvelistV5 cves/2026/104xxx; KEV raw; hub.ivanti.com via WebSearch
