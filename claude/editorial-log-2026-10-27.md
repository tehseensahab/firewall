# Editorial log 2026-10-27

## Topic selection
- Source check: KEV raw showed CVE-2026-109618 / CVE-2026-109619 (PHP) added 2026-10-26, due 2026-10-29 — bigger audience than the carried-over candidates, so taken as the timely item.
- Evergreen pick: php.ini security hardening (appsec), tested locally on PHP 8.3 CLI; links to the timely post without repeating it.
- Carried-over candidates not used today: Ivanti ICS CVE-2026-104935, Siemens Software Center CVE-2026-110936, management-plane hardening checklist (all still valid; see below).

## Article 1: php2shell-cve-2026-109618-cve-2026-109619-patch-and-hunt (John Marshall, security-operations)

| Claim | Primary source | Source date / effective date | Status | Scope |
|---|---|---|---|---|
| Affected 8.2<8.2.35, 8.3<8.3.36, 8.4<8.4.27, 8.5<8.5.12 (affected[].versions lessThan) | cvelistV5 CVE-2026-109618/109619 JSON | published 2026-10-21, updated 2026-10-27 | VERIFIED | upstream php-src |
| OOM longjmp mechanism; stale global state mechanism (descriptions quoted) | same records | 2026-10-21 | VERIFIED | |
| CVSS v4.0 9.2, vector AV:N/AC:H/AT:P/PR:N/UI:N/VC:H/VI:H/VA:H | same records, metrics | 2026-10-21 | VERIFIED | |
| Credits Wiz, Ryan at Calif.io, OpenAI | same records, credits | 2026-10-21 | VERIFIED | |
| SSVC Exploitation: none (timestamp 2026-10-21) | same records, CISA ADP | 2026-10-21 | VERIFIED | superseded by KEV |
| "all PHP installations serving web requests, including PHP-FPM, Apache with mod_php, php-cgi, FrankenPHP and LiteSpeed"; mod_php highest risk, demonstrated exploit | php.net/archive/2026.php advisory | 2026-10-21 | VERIFIED | |
| 8.1 and older "no longer receive updates"; source backports for 7.4/8.0/8.1; distros got patches in advance | same | 2026-10-21 | VERIFIED | |
| Stopgaps (memory_limit=-1 via php_admin_value, post_max_size 8M/32M, no RLIMIT_AS/DATA, session.upload_progress.enabled=0, no ini_set/.user.ini, fatal_error_backtraces=0 on 8.5, hiding diagnostics doesn't help) | same | 2026-10-21 | VERIFIED | quoted |
| PHP 8.2 EOL 31 Dec 2026; 8.6.0 RC4 contains the fixes | php.net news page (verbatim quotes) | 2026 | VERIFIED | |
| NEWS: "Avoid state corruption via bailout", dated 22 Oct 2026 in all four tags | raw php-src NEWS at php-8.2.35/8.3.36/8.4.27/8.5.12 | 2026-10-22 | VERIFIED | |
| "a complete FPM exploit has not been demonstrated" | openwall oss-security 2026/10/21/6 | 2026-10-21 | VERIFIED | |
| KEV added 2026-10-26, due 2026-10-29, forensicTriage Yes | kev-data raw | catalog 2026.10.26 | VERIFIED | |
| Ubuntu 8.3.6-0ubuntu0.24.04.13 carries CVE-2026-109618_109619.patch | dpkg + changelog.Debian.gz on sandbox host | 2026-10-19 changelog, inspected 2026-10-27 | VERIFIED | one package |
| php_admin_value can't be overridden with ini_set | doc-en install/fpm/configuration.xml | current | VERIFIED | |
| Amazon: attempt "dating October 17" on MadPot | Infosecurity Magazine 2026-10-22 | 2026-10-22 | QUALIFIED | secondary; BleepingComputer fetch failed |
| VulnCheck UAs, request pattern, session-file webshell attempt, "PWNED::" | vulncheck.com blog | 2026-10-21 | QUALIFIED | one vendor's honeypots |
| No confirmed successful RCE (honeypot operators) | securityaffairs.com | 2026-10-23 | QUALIFIED | secondary |
| FBI: updates "should be applied immediately" | ic3.gov PSA261023 | 2026-10-23 | VERIFIED | |
| Exposure counts (VulnCheck 2.6M hosts, Censys 34.4M services) | vendor/press | 2026-10-21/23 | REMOVED | inconsistent; not published |
| Cloudflare "millions" of attempts | securityaffairs (secondary of secondary) | 2026-10-23 | REMOVED | not needed |
- Code: php2shell-check.php run on PHP 8.3 CLI with 12 versions; hunt greps run against sample log/session files.

## Article 2: php-ini-security-hardening-production-settings (Craig Leslie, appsec)

| Claim | Primary source | Source date / effective date | Status | Scope |
|---|---|---|---|---|
| php.ini-production values: expose_php On, use_strict_mode 0, cookie_httponly/samesite empty, cookie_secure commented, display_errors Off, log_errors On, allow_url_fopen On, allow_url_include Off, upload_progress default On | raw php-src php-8.4.27/php.ini-production | 2026-10-22 | VERIFIED | |
| Built-in defaults (php -n) for 13 settings + post/upload/memory/max_input_vars | php -n on 8.3.6 | 2026-10-27 | VERIFIED (tested) | CLI SAPI |
| Audit: production template differs on 6/13; no ini 10/13; hardened 0/13 | ini-audit.php runs | 2026-10-27 | VERIFIED (tested) | |
| use_strict_mode "mandatory for general session security" | doc-en reference/session/ini.xml | current | VERIFIED | |
| Strict mode rejects attacker-chosen ID (test output) | strict2.php run | 2026-10-27 | VERIFIED (tested) | CLI simulation via $_COOKIE |
| disable_functions "can be circumvented ..."; PHP 8 redefinition | doc-en appendices/ini.core.xml | current | VERIFIED | |
| disable_functions → "Call to undefined function system()"; ini_set returns false | test | 2026-10-27 | VERIFIED (tested) | |
| open_basedir symlinks resolved; "With dynamic loading, it's possible to ignore all open_basedir restrictions"; realpath cache disabled; ini_set can't widen | doc-en + test | current | VERIFIED | |
| allow_url_include "Deprecated as of PHP 7.4.0"; deprecation notice on startup | doc-en reference/filesystem/ini.xml + test | current | VERIFIED | |
| php_admin_value not overridable; security.limit_extensions default ".php .phar" | doc-en install/fpm/configuration.xml | current | VERIFIED | |
| X-Powered-By: PHP/8.3.6 with expose_php=1, absent with 0 | php -S test | 2026-10-27 | VERIFIED (tested) | built-in server |
| cookie_secure: "sessions only work with HTTPS connections"; httponly quote | doc-en session ini | current | VERIFIED | |
| FPM pool file example | — | — | QUALIFIED | labelled illustrative, not run |

## Hero images
- php2shell first pick (9z958EEwNaI, fire alarm box) dropped after viewing: maker name embossed on the box. Replaced with N6oKiPTrk88.
- php2shell: Unsplash D7Fjd1-Jkbc (Compagnons), photo-1726453004705-fa6341ceb095 (second pick N6oKiPTrk88 dropped after viewing: event branding in background)
- php.ini: Unsplash F_DSvG5Fb0A (Dan Meyers), photo-1567664883526-8f401f277a27

## Skipped / blocked
- GitHub Security Advisories GHSA-w8hw-w9fx-j79w / GHSA-6wmf-4rv5-p3rp: api.github.com 403 (repo not in session scope); php.net advisory used instead.
- bleepingcomputer.com Amazon article: WebFetch SERVER_ERROR; used Infosecurity Magazine.

## Next-session candidates
1. Ivanti Connect Secure CVE-2026-104935: auth bypass by spoofing, fixed in 25.1.3.0 | timely (KEV 2026-10-13) | admins search "is my ICS affected / fixed version" | cvelistV5 cves/2026/104xxx/CVE-2026-104935.json; KEV raw; Ivanti advisory via WebSearch | must not repeat: citrix/netscaler and pan-os patch-and-hunt posts
2. PHP session security beyond php.ini: session_regenerate_id, fixation, storage and upload-progress files | guide (appsec) | follows PHP2Shell; developers search "php session security best practices" | doc-en reference/session (ini.xml, security pages: session.security.ini, features.session.security.management via WebSearch); php.ini-production raw | must not repeat: php-ini-security-hardening-production-settings, php2shell post, csrf-protection post
3. Siemens Software Center CVE-2026-110936 (uncontrolled search path) | timely (KEV 2026-10-20, due 2026-11-03) | OT/engineering IT patching | cvelistV5 cves/2026/110xxx/CVE-2026-110936.json; KEV raw; Siemens ProductCERT advisory via WebSearch | must not repeat: none

## Publication status
(see below)
