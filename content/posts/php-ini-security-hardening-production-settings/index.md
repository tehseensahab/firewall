+++
title = "php.ini Security Hardening: Production Settings That Matter"
date = 2026-10-27T04:55:00Z
tags = ["php", "hardening", "session security", "configuration"]
categories = ["appsec"]
summary = "PHP's own php.ini-production template still leaves several security settings at permissive defaults, including strict session mode, cookie flags and the X-Powered-By header. This guide lists the settings worth changing, shows what each one does with tested examples, explains where to set them so applications can't undo them, and is honest about the two directives that are not security boundaries."
description = "php.ini hardening: the settings PHP's production template leaves open, tested examples, where to set them so apps can't override them, and what not to rely on."
author = "Craig Leslie"
imageAlt = "Hero image for the php.ini hardening guide"
imageCredit = "Photo by [Dan Meyers](https://unsplash.com/photos/F_DSvG5Fb0A) on Unsplash"
takeaways = [
  "PHP's shipped php.ini-production is safer than no php.ini, but it is not hardened. Checked against a 13-setting baseline, the PHP 8.4.27 template still differed on 6: expose_php, allow_url_fopen, session.use_strict_mode, session.cookie_httponly, session.cookie_secure and session.cookie_samesite.",
  "Turn on session.use_strict_mode. PHP's manual calls it 'mandatory for general session security', yet it defaults to 0. In our test, PHP accepted an attacker-chosen session ID with it off and replaced it with a fresh one with it on.",
  "Set security settings where applications cannot undo them: php.ini or php_admin_value / php_admin_flag in the PHP-FPM pool. Values set with php_value, .user.ini or ini_set() can be changed by the application.",
  "disable_functions and open_basedir are useful friction, not sandboxes. PHP's manual says disable_functions 'can be circumvented and should not be considered a sufficient security measure for shared hosting environments'. Isolate untrusted code with separate users, pools or containers.",
  "Hardening does not replace patching. October's PHP2Shell flaws (CVE-2026-109618 and CVE-2026-109619) gave remote code execution on default configurations; some settings here narrow those paths, only updating closes them."
]

[[faq]]
q = "Is php.ini-production secure enough to use as-is?"
a = "It is a sensible base: errors are logged instead of displayed and remote includes are off. But it leaves expose_php on, strict session mode off and the session cookie's HttpOnly, Secure and SameSite flags unset. Change those for any internet-facing application."
[[faq]]
q = "Should I set session.cookie_samesite to Lax or Strict?"
a = "Lax is the usual choice for a session cookie because the cookie is still sent when a user follows a link to your site from elsewhere. Strict breaks that flow: users arriving from an external link appear logged out. Neither replaces CSRF tokens for state-changing requests."
[[faq]]
q = "Does disable_functions stop a webshell?"
a = "It makes the obvious commands fail. Our test with system disabled raised 'Call to undefined function system()'. But PHP's manual says the directive can be circumvented, and attackers who can run PHP code have other routes. Treat it as a speed bump and rely on OS-level isolation."
[[faq]]
q = "Can an application override settings in php.ini?"
a = "Many settings, yes, through ini_set() or .user.ini, depending on each directive's changeable mode. Settings applied with php_admin_value or php_admin_flag in a PHP-FPM pool cannot be overridden with ini_set, and INI_SYSTEM settings such as disable_functions cannot be changed at runtime at all."
+++

To harden PHP for production, start from `php.ini-production`, then change six settings it leaves permissive: turn off `expose_php`, turn on `session.use_strict_mode`, set the session cookie's `HttpOnly`, `Secure` and `SameSite` flags, and turn off `allow_url_fopen` if your code never reads URLs as files. Apply them in `php.ini` or with `php_admin_value` in the PHP-FPM pool so applications cannot undo them, and do not treat `disable_functions` or `open_basedir` as a sandbox.

Everything below was checked against PHP 8.4.27's `php.ini-production` and the PHP manual, and every behaviour we describe was run on PHP 8.3 CLI (Ubuntu 24.04 package). Where a setting behaves differently under PHP-FPM or Apache, we say so.

## The baseline

| Setting | Recommended | Built-in default | php.ini-production | Why |
|---|---|---|---|---|
| `expose_php` | `Off` | On | **On** | Removes the `X-Powered-By: PHP/x.y.z` header |
| `display_errors` | `Off` | On | Off | Errors can leak paths, queries and credentials |
| `display_startup_errors` | `Off` | On | Off | Same, for startup |
| `log_errors` | `On` | Off | On | You still need the errors, in a log |
| `allow_url_include` | `Off` | Off | Off | Stops `include 'http://...'`; deprecated since 7.4 |
| `allow_url_fopen` | `Off` if unused | On | **On** | Limits URL reads via file functions |
| `enable_dl` | `Off` | On | Off | Stops runtime extension loading |
| `session.use_strict_mode` | `1` | 0 | **0** | Rejects attacker-chosen session IDs |
| `session.use_only_cookies` | `1` | 1 | 1 | No session IDs in URLs |
| `session.cookie_httponly` | `1` | 0 | **unset** | Keeps the session cookie away from JavaScript |
| `session.cookie_secure` | `1` | 0 | **unset** | Session cookie only over HTTPS |
| `session.cookie_samesite` | `Lax` | unset | **unset** | Cookie not sent on most cross-site requests |
| `session.use_trans_sid` | `0` | 0 | 0 | No transparent session IDs in links |

"Built-in default" is what PHP uses with no `php.ini` at all (`php -n`). Bold marks the six settings where the production template differs from the hardened value. We measured both columns with the audit script at the end of this article.

## Where to set them so they stick

PHP settings come from several layers, and the later ones can override the earlier ones for directives that allow it: `php.ini` and its scan directory, web server or FPM pool configuration, `.user.ini` files in the document root, and `ini_set()` in code. Each directive has a changeable mode. `INI_SYSTEM` settings such as `disable_functions`, `allow_url_fopen` and `allow_url_include` can only be set in `php.ini` or server configuration.

For PHP-FPM, use `php_admin_value` and `php_admin_flag` for anything security-relevant. The PHP-FPM documentation says: "Settings defined with php_admin_value and php_admin_flag cannot be overridden with ini_set." Plain `php_value` and `php_flag` can be.

```ini
; /etc/php/8.3/fpm/pool.d/app.conf (path varies by distribution)
[app]
user = app
group = app
listen = /run/php/app.sock

php_admin_flag[expose_php] = off
php_admin_flag[display_errors] = off
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /var/log/php/app-error.log
php_admin_flag[allow_url_fopen] = off
php_admin_value[session.use_strict_mode] = 1
php_admin_value[session.cookie_httponly] = 1
php_admin_value[session.cookie_secure] = 1
php_admin_value[session.cookie_samesite] = Lax

; Only execute .php files (the default also allows .phar)
security.limit_extensions = .php
```

This is illustrative: we validated the directive names and values against the PHP-FPM documentation and our CLI tests, but did not run this pool file. Restart the pool after editing. For Apache with mod_php, the equivalent is `php_admin_value` and `php_admin_flag` in the virtual host.

You can see runtime locking in action. With `disable_functions` set in configuration, `ini_set('disable_functions', '')` returns `false` and changes nothing. With `open_basedir` set, an attempt to widen it to `/` also returns `false`.

## Stop advertising your PHP version

`php.ini-production` ships with `expose_php = On`. Its comment says the header "is no security threat in any way", and that is fair: hiding the version does not fix anything. But the header tells every scanner which PHP release you run, which turns mass scanning for a new CVE into a simple header match. We ran PHP's built-in server with each value:

```console
$ curl -sI http://127.0.0.1:8099/index.php | grep -i x-powered   # expose_php=1
X-Powered-By: PHP/8.3.6
$ curl -sI http://127.0.0.1:8099/index.php | grep -i x-powered   # expose_php=0
$
```

Frameworks and reverse proxies can add their own version headers, so check the response at the edge too. Our guide to [HTTP security headers](/posts/http-security-headers-hsts-nosniff-referrer-policy-and-permissions-policy-explained/) covers the headers you do want to send.

## Log errors, never display them

The production template sets `display_errors = Off` and `log_errors = On`, and its comment explains why: displayed errors could leak "sensitive information ... such as database usernames and passwords or worse." The built-in defaults are the opposite, so a server that runs PHP without loading a `php.ini` (a misconfigured container is the usual case) will print errors to users. Point `error_log` at a file or `stderr` that your logging pipeline collects.

## Turn off URL includes and, if you can, URL file reads

`allow_url_include` lets `include` and `require` load code from a URL. It is off by default and the PHP manual marks it "Deprecated as of PHP 7.4.0"; enabling it now prints a deprecation notice at startup. Keep it off.

`allow_url_fopen` is broader: it lets `file_get_contents()`, `fopen()` and similar functions open `http://` and `ftp://` URLs. If your application only makes HTTP requests through cURL or an HTTP client library, turning it off removes one way for user input passed to a file function to become an outbound request. It does not stop server-side request forgery through your HTTP client; see our [SSRF guide](/posts/ssrf-explained-how-server-side-request-forgery-works-and-how-to-prevent-it/) for that. Test before you change it: some libraries and package managers rely on it.

## Session settings

PHP's session defaults favour compatibility. Four changes matter.

### Strict mode

The PHP manual is blunt: "Enabling session.use_strict_mode is mandatory for general session security. All sites are advised to enable this." Without it, PHP accepts any session ID the browser sends, even one the server never issued, which enables session fixation. We simulated a browser sending an attacker-chosen `PHPSESSID` cookie:

```php
<?php
// strict.php: run with `php -d session.use_strict_mode=0|1 strict.php`
ini_set('session.save_path', __DIR__);
$_COOKIE[session_name()] = 'attackerchosenid123456';
session_start();
printf("use_strict_mode=%s -> session_id=%s\n", ini_get('session.use_strict_mode'), session_id());
```

```console
$ php -d session.use_strict_mode=0 strict.php
use_strict_mode=0 -> session_id=attackerchosenid123456
$ php -d session.use_strict_mode=1 strict.php
use_strict_mode=1 -> session_id=3e4393b3059589b68078c6a9f5c4fe34
```

Strict mode does not replace calling `session_regenerate_id(true)` after login; do both.

### Cookie flags

- `session.cookie_httponly = 1` makes the cookie inaccessible to JavaScript. The manual says it "can effectively help to reduce identity theft through XSS attacks". It does not stop an XSS payload from making requests as the user.
- `session.cookie_secure = 1` sends the cookie only over HTTPS. The manual notes that with it on, "sessions only work with HTTPS connections". If TLS terminates at a load balancer, that means the browser's connection: the flag is a cookie attribute the browser enforces, so it works as long as users reach you over HTTPS.
- `session.cookie_samesite = Lax` stops the browser sending the session cookie on most cross-site subrequests and form posts. It reduces CSRF exposure but does not remove the need for tokens; we compare the options in [CSRF protection: SameSite, tokens and Fetch Metadata](/posts/csrf-protection-samesite-cookies-tokens-and-fetch-metadata-compared/).

These cookie protections address token theft through the browser. They do nothing about a cookie stolen from the endpoint itself, which our explainer on [token theft and MFA](/posts/what-is-token-theft-and-why-mfa-doesnt-always-stop-it/) covers.

## Request size and resource limits

`post_max_size` (8M in both defaults), `upload_max_filesize` (2M), `max_input_vars` (1000), `memory_limit` (128M) and `max_execution_time` (30 seconds) are mainly availability controls. Set them to what your application needs, not higher, and enforce body size limits at the web server or proxy as well, because those apply before PHP parses anything.

These limits briefly became security-critical in October 2026. PHP's stopgap advice for [PHP2Shell (CVE-2026-109618 and CVE-2026-109619)](/posts/php2shell-cve-2026-109618-cve-2026-109619-patch-and-hunt/) included a low `post_max_size`, `memory_limit=-1` set non-overridably and `session.upload_progress.enabled=0`. Those were emergency measures for unpatched servers and PHP said they "do not make an installation safe". Once patched, keep a finite `memory_limit` unless you have a container or cgroup limit doing that job. Note that `session.upload_progress.enabled` is on by default and in the production template; if your application does not show upload progress bars, turning it off removes a feature you do not use.

## What not to rely on

Two directives look like sandboxes and are not.

**`disable_functions`** removes named internal functions. With `system`, `exec` and `shell_exec` disabled, calling `system()` raises `Error: Call to undefined function system()`, which defeats the laziest webshells. But the PHP manual says plainly: "This directive can be circumvented and should not be considered a sufficient security measure for shared hosting environments." It only covers internal functions you thought to list, and in PHP 8 a disabled function's name can be redefined by userland code.

**`open_basedir`** limits which paths PHP's file functions can open, and the manual says symlinks are resolved so they cannot be used to escape it. It is still not an isolation boundary. The same manual notes that "With dynamic loading, it's possible to ignore all open_basedir restrictions", which is one reason to keep `enable_dl` off, and the restriction only applies to PHP's own file access, not to anything a spawned process does. It also disables PHP's realpath cache, which has a performance cost.

If you host more than one application, or code you do not fully trust, isolate them at the operating system level: a separate PHP-FPM pool per application running as its own Unix user, with file permissions that stop one user reading another's files, or separate containers. That is the boundary; the two directives above are defence in depth inside it.

## Audit what is actually running

The settings that matter are the ones the serving process loaded, which may not be the `php.ini` you edited. The CLI and FPM usually read different files (on Debian and Ubuntu, `/etc/php/<version>/cli/` and `/etc/php/<version>/fpm/`). This script prints the effective values against the baseline above. Run it under the SAPI you care about: from the command line for the CLI, or temporarily as a web request for FPM or mod_php (then delete it, since it reveals configuration).

```php
<?php
// ini-audit.php: compare effective settings with a hardened baseline.
$baseline = [
    'expose_php'               => '0',
    'display_errors'           => '0',
    'display_startup_errors'   => '0',
    'log_errors'               => '1',
    'allow_url_include'        => '0',
    'allow_url_fopen'          => '0',   // only if the app never opens URLs with file functions
    'enable_dl'                => '0',
    'session.use_strict_mode'  => '1',
    'session.use_only_cookies' => '1',
    'session.cookie_httponly'  => '1',
    'session.cookie_secure'    => '1',
    'session.cookie_samesite'  => 'Lax',
    'session.use_trans_sid'    => '0',
];
$norm = fn($v) => match (strtolower((string)$v)) {
    'on', 'true', 'yes' => '1', 'off', 'false', 'no', '' => '0', default => (string)$v };

$fail = 0;
foreach ($baseline as $key => $want) {
    $have = ini_get($key);
    $ok = ($key === 'session.cookie_samesite')
        ? in_array($have, ['Lax', 'Strict'], true)
        : $norm($have) === $want;
    $fail += $ok ? 0 : 1;
    printf("%-26s %-6s want %-5s %s\n", $key, var_export($have, true), $want, $ok ? 'ok' : 'CHECK');
}
printf("\n%d setting(s) differ from the baseline (SAPI: %s, ini: %s)\n",
    $fail, PHP_SAPI, php_ini_loaded_file() ?: 'none');
```

Run against PHP 8.4.27's `php.ini-production` with `php -c php.ini-production ini-audit.php` on PHP 8.3 CLI, it reported:

```console
expose_php                 '1'    want 0     CHECK
display_errors             ''     want 0     ok
display_startup_errors     ''     want 0     ok
log_errors                 '1'    want 1     ok
allow_url_include          ''     want 0     ok
allow_url_fopen            '1'    want 0     CHECK
enable_dl                  ''     want 0     ok
session.use_strict_mode    '0'    want 1     CHECK
session.use_only_cookies   '1'    want 1     ok
session.cookie_httponly    ''     want 1     CHECK
session.cookie_secure      '0'    want 1     CHECK
session.cookie_samesite    ''     want Lax   CHECK
session.use_trans_sid      '0'    want 0     ok

6 setting(s) differ from the baseline (SAPI: cli, ini: php.ini-production)
```

With no `php.ini` at all (`php -n`), 10 of the 13 differed. With the hardened values applied, none did.

## Limits of this article

This covers PHP's own configuration, not your web server, framework or application code. We tested behaviour on PHP 8.3 CLI and read defaults from PHP 8.4.27's template; check the manual for your version, since defaults and deprecations change between releases. The PHP-FPM pool example was not run. The baseline is a starting point for a typical web application: turning off `allow_url_fopen` in particular can break code that depends on it, so test in staging first.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| php.ini-production values (expose_php On, use_strict_mode 0, cookie flags unset, display_errors Off, log_errors On) and comments quoted | [php.ini-production at php-8.4.27](https://github.com/php/php-src/blob/php-8.4.27/php.ini-production) | Verified (and measured with the audit script) |
| Built-in defaults | `php -n` on PHP 8.3.6 (Ubuntu 24.04 package), October 27, 2026 | Verified (tested) |
| use_strict_mode is "mandatory for general session security"; cookie_httponly and cookie_secure behaviour | [PHP manual: session runtime configuration](https://www.php.net/manual/en/session.configuration.php) | Verified |
| disable_functions "can be circumvented"; PHP 8 redefinition; open_basedir symlink and dynamic-loading notes; realpath cache disabled | [PHP manual: core php.ini directives](https://www.php.net/manual/en/ini.core.php) | Verified |
| allow_url_include deprecated as of 7.4.0 | [PHP manual: filesystem runtime configuration](https://www.php.net/manual/en/filesystem.configuration.php) | Verified (and tested: deprecation notice) |
| php_admin_value cannot be overridden with ini_set; security.limit_extensions default .php .phar | [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php) | Verified |
| Strict mode rejects an attacker-chosen ID; disable_functions error; X-Powered-By header; ini_set refusing to loosen settings | Our tests on PHP 8.3 CLI and built-in server | Verified (tested) |
| PHP2Shell stopgaps and "do not make an installation safe" | [PHP security advisory, October 21, 2026](https://www.php.net/archive/2026.php) | Verified |
