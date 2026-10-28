# Editorial log 2026-10-28

## Published (pushed to main)
1. brotli-cve-2026-111497-find-and-patch-every-copy | security-operations | John Marshall | timely (KEV 2026-10-27)
2. php-session-regenerate-id-stop-session-fixation | appsec | Craig Leslie | guide

## Topic selection
- Considered: Ivanti ICS CVE-2026-104935 (KEV 2026-10-13, 15 days old, outside the 14-day window; held), Siemens Software Center CVE-2026-110936 (narrow audience), Adobe Commerce CVE-2026-48356 (KEV 2026-10-27; CVE published July; good candidate for tomorrow), Brotli CVE-2026-111497 (KEV 2026-10-27; chosen: broad developer exposure, primary records reachable).
- PHP session guide differentiated from php-ini-security-hardening (ini settings) by focusing on application-code lifecycle (rotation, timestamps, timeouts).

## Fact-check: Brotli CVE-2026-111497
| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| Affected 1.0.3-1.2.0; fixed 1.0.10/1.1.1/1.2.1 ("Users need to update any Brotli libraries or binaries between 1.0.3 through 1.2.0 to ... 1.0.10 or 1.1.1 or 1.2.1") | cvelistV5 CVE-2026-111497.json | published 2026-10-22 | VERIFIED | upstream lib |
| CVSS 4.0 9.2 CRITICAL; CWE-787, CWE-252; finder OpenAI Codex Security - Khai Tran and Sylvie Mayer | same record | 2026-10-22 | VERIFIED | |
| KEV dateAdded 2026-10-27, dueDate 2026-11-10, forensicTriage No, knownRansomware Unknown | kev-data JSON (dateReleased 2026-10-27T19:00Z) | 2026-10-27 | VERIFIED | |
| SSVC Exploitation: active | CISA ADP in CVE record, timestamp 2026-10-23 | 2026-10-23 | VERIFIED | |
| 1.2.1 released 2026-10-21 "CVE-2026-111497: out-of-bounds write permits remote code execution" | google/brotli v1.2.1 CHANGELOG.md | 2026-10-21 | VERIFIED | |
| Fix: DecodeBlockTypeAndLength returns BrotliDecoderErrorCode, BROTLI_DECODER_ERROR_FORMAT_BLOCK_SWITCH, BROTLI_SAFE_WITH_STATUS; old callers void | diff decode.c v1.2.0..v1.2.1 | 2026-10-21 | VERIFIED | |
| Node fixed 22.23.4, 24.22.1, 26.12.1; root-cause quote "An invalid block switch was reported as a temporary need for more input..." ; EOL quote | nodejs.org October 2026 security releases (WebFetch) | 2026-10-21 | VERIFIED | |
| Patched Node reports old brotli version: node v22.23.4 -> process.versions.brotli 1.1.0; version.h 1.1.0 at v22.23.3/4, 1.2.0 at v24.22.1/v26.12.1; BROTLI_SAFE_WITH_STATUS count 0 at v22.23.3, 4 at v22.23.4/v24.22.1/v26.12.1 | sandbox + raw nodejs/node | 2026-10-28 | VERIFIED (our test) | |
| Go andybalholm v1.2.7 adds decoderErrorFormatBlockSwitch; decodeBlockTypeAndLength bool -> int | raw decode.go v1.2.6/v1.2.7; CVE reference | 2026-10-28 | VERIFIED | |
| Python Brotli 1.2.1, brotlicffi 1.2.1.0 fixed; PyPI uploads 2026-10-22 | Aikido blog (updated 2026-10-27) + pypi.org JSON | 2026-10-22 | VERIFIED | |
| urllib3 appends ",br" when brotlicffi/brotli importable; requests default_headers -> "gzip, deflate, br" with Brotli installed | urllib3 main util/request.py; sandbox test | 2026-10-28 | VERIFIED | |
| Node fetch sends "gzip, deflate" yet decodes a br response | sandbox test, node v22.23.4 | 2026-10-28 | VERIFIED (our test) | |
| Envoy/Istio/Bun ranges | Wiz blog 2026-10-25 | 2026-10-25 | QUALIFIED (secondary; attributed) | |
| Envoy v1.39.2 pins brotli 1.2.0; v1.39.3 pins commit 42a2ed43 containing fix | raw envoyproxy/envoy repository_locations.bzl + raw google/brotli commit decode.c | 2026-10-28 | VERIFIED | |
| Envoy and other consumers affected; patchtheplanet lists Node, Bun, Envoy, Istio | oss-security 2026/10/23/25, 2026/10/24/6 | 2026-10-23/24 | VERIFIED | |
| "Researchers have demonstrated successful exploitation against unpatched Node.js"; review logs for suspicious Brotli traffic | Wiz | 2026-10-25 | QUALIFIED (attributed) | |
| fixcheck script classified 12 sources correctly | sandbox run | 2026-10-28 | VERIFIED (our test) | |
| Ubuntu sandbox libbrotli1 1.1.0-2ubuntu0.1 | dpkg | 2026-10-28 | VERIFIED; patched status NOT VERIFIED -> article says check distro tracker | |
- Removed/not used: press "Node2Shell/HTTP2Shell" naming, curl/Git for Windows claims (secondary only), "10 CVEs" counts.

## Fact-check: PHP session_regenerate_id
| Claim | Primary source | Date | Status |
|---|---|---|---|
| "an attacker can force users to use an initialized session ID which has been created by an attacker" | doc-en reference/session/security.xml | master 2026-10-28 | VERIFIED |
| "Session IDs must be regenerated when user privileges are elevated..." / "must be called prior to setting the authentication information to $_SESSION" | same | | VERIFIED |
| "session_regenerate_id(true); and session_destroy must never be called together for an active session" | same | | VERIFIED |
| timestamp guidance; "a few seconds later ... a few minutes later" | same | | VERIFIED |
| "Attackers may access a victim's session ID periodically to prevent its expiration" | same | | VERIFIED |
| "every 15 minutes for security sensitive content" | same | | VERIFIED |
| read_and_close, session_commit; auto-login "long life session IDs"; CSRF quote; user-ID-prefix "vital" with strict mode | same | | VERIFIED |
| example labelled "not fully working code, but an example!"; forwarding comment "Do not try to set session ID again..." | doc-en session-regenerate-id.xml | | VERIFIED |
| gc_maxlifetime "will be seen as 'garbage' and potentially cleaned up", default 1440 | doc-en reference/session/ini.xml | | VERIFIED |
| session_create_id added 7.1.0; setcookie options array 7.3.0 | security.xml; setcookie.xml | | VERIFIED |
| OWASP "after any privilege level change"; "2-5 minutes ... 15-30 minutes"; absolute timeout "regardless of session activity" | OWASP CheatSheetSeries Session_Management_Cheat_Sheet.md (raw) | | VERIFIED |
| Fixation succeeds with strict mode on and no rotation; helper blocks; forwarding at login reopens (first draft); new session empty after session_id+session_start; grace/401; idle timeout new ID | sandbox PHP 8.3.6 CLI php -S + curl (/tmp/d/app test.sh, test2.sh) | 2026-10-28 | VERIFIED (our test) |
- Removed: claim that Laravel/Symfony have specific settings (not verified).

## Images
- Brotli: Unsplash knoPXXK07MQ (Haberdoedas), straw bales. PHP: Unsplash pTZJTasRzY0 (Dragonfly Ave), two brass keys. Previewed before commit.

## Skipped / issues
- Ivanti CVE-2026-104935 held (outside 14-day window today).
- php.net session-regenerate-id URL not individually confirmed by WebSearch (pattern matches confirmed session-gc page).

## Next-session candidates
1. Adobe Commerce/Magento CVE-2026-48356 (APSB26-73) unrestricted upload, KEV 2026-10-27, due 2026-11-10 | timely | merchants search "is my Magento patched / 2.4.x-2026-jul" | cvelistV5 cves/2026/48xxx/CVE-2026-48356.json (affected list incl. 2026-jul builds); KEV raw; helpx.adobe.com APSB26-73 via WebSearch | must not repeat: php2shell, php-ini posts
2. Node.js zlib decompression safety: maxOutputLength, streaming limits and decompression bombs (gzip/brotli/zstd) | guide (appsec) | follows Brotli CVE; devs search "node zlib decompression bomb maxOutputLength" | nodejs/node doc/api/zlib.md raw; Node.js Oct 2026 advisory; OWASP file upload cheat sheet raw | must not repeat: brotli-cve-2026-111497 post
3. Ivanti Connect Secure CVE-2026-104935 auth bypass, fixed 25.1.3.0 / 22.8R2.5 | timely-ish (KEV 2026-10-13, forensicTriage Yes) | ICS admins | cvelistV5 cves/2026/104xxx/CVE-2026-104935.json; KEV raw; hub.ivanti.com advisory via WebSearch | must not repeat: pan-os, citrix posts

## Publication status
Pushed to main: 142690b (posts, INDEX, covers.tsv), 06b1c6b (covers by workflow), 7e92eb4 (alt text + log). Local Hugo v0.152.2 build: 0 errors, both pages present, 0 dead /posts/ links. Covers checked visually. Live check NOT confirmed: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED (not retried). Owner should spot-check both URLs.
