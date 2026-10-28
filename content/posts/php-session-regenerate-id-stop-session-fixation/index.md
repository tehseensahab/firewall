+++
title = "PHP session_regenerate_id: Stop Session Fixation Right"
date = 2026-10-28T04:45:00Z
tags = ["php", "session security", "authentication", "appsec"]
categories = ["appsec"]
summary = "Calling session_regenerate_id() at login is the start of PHP session security, not the whole of it. This guide shows the fixation attack strict mode does not stop, a tested helper for timestamp-based rotation, idle and absolute timeouts, and the grace-period shortcut that quietly undoes the fix."
description = "PHP session_regenerate_id done right: rotate before setting auth, keep old IDs on a timer, enforce idle and absolute timeouts. Tested code for PHP 8.3."
author = "Craig Leslie"
imageAlt = "Two antique brass skeleton keys on a white background, one pointing up and one down, each tied with a thin pale pink ribbon"
imageCredit = "Photo by [Dragonfly Ave](https://unsplash.com/photos/pTZJTasRzY0) on Unsplash"
takeaways = [
  "session.use_strict_mode only rejects session IDs PHP never issued. An attacker who visits your site gets a real ID and can plant it on a victim. In our test the victim logged in, and the attacker's copy of that ID showed the victim's account.",
  "Regenerate the session ID on every privilege change, before you write the authenticated user into $_SESSION. In our test, rotating at login left the attacker's ID anonymous.",
  "Don't delete the old session immediately. PHP's manual says to timestamp it and refuse it after a short grace period, so concurrent requests and dropped cookies don't log users out.",
  "Don't forward an old ID to the new one after login. The manual's lost-cookie workaround does that, and in our test it gave the attacker the authenticated session again. Keep forwarding for periodic rotation only.",
  "session.gc_maxlifetime is garbage collection, not a timeout. Enforce idle and absolute timeouts yourself, with timestamps in $_SESSION."
]

[[faq]]
q = "Should I call session_regenerate_id(true) to delete the old session?"
a = "PHP's manual says not to delete active session data straight away, because concurrent requests or a lost Set-Cookie response can leave a legitimate user on the old ID. Mark the old session with a timestamp and refuse it after a short grace period instead. Garbage collection removes it later."
[[faq]]
q = "Isn't session.use_strict_mode enough to stop session fixation?"
a = "No. Strict mode rejects IDs PHP has never issued, which stops an attacker inventing one. It does not stop an attacker who gets a real, server-issued ID by visiting your site and plants it on a victim. Regenerating the ID at login is what breaks that attack."
[[faq]]
q = "How often should PHP regenerate the session ID?"
a = "Always on login and any privilege change. PHP's manual also suggests periodic rotation, giving 'every 15 minutes for security sensitive content' as an example. Periodic rotation limits how long a stolen ID stays useful, but it does not replace rotating on login."
[[faq]]
q = "Does session.gc_maxlifetime log users out after 24 minutes?"
a = "Not reliably. It marks data as garbage after that many seconds (1440 by default), and cleanup only runs when garbage collection happens to run. PHP's manual says developers must not rely on it for session expiry. Store your own timestamps and enforce idle and absolute timeouts in code."
+++

To stop session fixation in PHP, call `session_regenerate_id()`, or the timestamp-based rotation shown below, whenever a user's privilege changes. Do it before you store the authenticated user in `$_SESSION`. Don't destroy the old session on the spot. Mark it with a timestamp and refuse it after a short grace period, and enforce your own idle and absolute timeouts, because PHP's garbage collector is not a timeout. That is what PHP's own manual asks for. Below is a helper that follows it, tested against a fixation attack, plus the one shortcut in the manual's example that brings the attack back if you use it at login.

Every behaviour here was run on PHP 8.3.6 CLI with the built-in web server (`php -S`) and curl, using the default `files` save handler. The cookie flags and `php.ini` settings that go with this code are covered in our [php.ini security hardening guide](/posts/php-ini-security-hardening-production-settings/). This article is about the session lifecycle in your application code.

## The attack strict mode doesn't stop

`session.use_strict_mode=1` makes PHP reject a session ID it never issued. That stops an attacker inventing an ID such as `PHPSESSID=123456`. But the [PHP manual](https://www.php.net/manual/en/features.session.security.management.php) is explicit about the gap: "an attacker can force users to use an initialized session ID which has been created by an attacker." The attacker visits your site, receives a real ID, and plants it in the victim's browser. The manual describes two routes: setting a cookie that the browser's precedence rules let override yours (for example from another subdomain), and JavaScript injection. If your login code keeps that ID, the attacker now holds an authenticated session.

We reproduced it with a minimal app whose login does only `$_SESSION['uid'] = 42;`, run with strict mode on:

```console
$ PHPFLAGS="-d session.use_strict_mode=1" ./test.sh naive 8090
attacker ID: pmq468mni64u18nhukmh7vqe1v
logged in
ID after login: unchanged
attacker replays old ID: account page for uid 42
```

The test script fetches `/` to get a real ID, sends `/login` with that ID as the victim, then replays the ID as the attacker.

## What PHP's manual requires

The session security chapter is unusually prescriptive. The rules that matter for application code:

- **Rotate on privilege change, before writing auth state.** "Session IDs must be regenerated when user privileges are elevated, such as after authenticating. session_regenerate_id must be called prior to setting the authentication information to $_SESSION." Rotate again on any later privilege change, such as entering an admin area or completing step-up authentication. The [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html) makes the same point: renew the ID "after any privilege level change".
- **Don't delete active sessions immediately.** "session_regenerate_id(true); and session_destroy must never be called together for an active session." Deleting right away loses sessions when requests overlap or the new cookie never arrives. It also removes your chance to notice that someone used an old ID.
- **Use timestamps instead.** Set "a short-term expiration time (timestamp) in $_SESSION" on the old session and refuse it later: "a few seconds later for stable networks... and a few minutes later for unstable networks such as cell phones or Wi-Fi."
- **Don't rely on `session.gc_maxlifetime` for expiry.** "Attackers may access a victim's session ID periodically to prevent its expiration and keep exploiting it." The setting only controls when data "will be seen as 'garbage' and potentially cleaned up" (default 1440 seconds).
- **Treat obsolete-ID access as a signal.** When an expired ID is used, the manual recommends removing "authenticated status from all of the user's sessions" and forcing re-authentication.

The [`session_regenerate_id()` page](https://www.php.net/manual/en/function.session-regenerate-id.php) has two example implementations. Both are labelled "not fully working code, but an example!"

## A tested rotation helper

`session_guard.php` follows the manual's pattern, with two corrections we found in testing (explained after the code). It targets PHP 8.1 or later (`session_create_id()` exists from 7.1, and the cookie-options array for `setcookie()` from 7.3).

```php
<?php
// session_guard.php: timestamp-based session ID rotation, adapted from the
// pattern in the PHP manual's session_regenerate_id() page.
declare(strict_types=1);

defined('SESSION_GRACE')    || define('SESSION_GRACE', 60);     // old ID usable after rotation (s)
defined('SESSION_IDLE')     || define('SESSION_IDLE', 1800);    // idle timeout (s)
defined('SESSION_ABSOLUTE') || define('SESSION_ABSOLUTE', 28800); // absolute timeout (s)
defined('SESSION_ROTATE')   || define('SESSION_ROTATE', 900);   // periodic rotation (s)

final class ObsoleteSessionAccess extends RuntimeException {}

function secure_session_start(): void
{
    ini_set('session.use_strict_mode', '1');
    session_start();
    $now = time();

    // 1. Old ID after rotation: allow a short grace period, then refuse.
    if (isset($_SESSION['destroyed'])) {
        if ($_SESSION['destroyed'] < $now - SESSION_GRACE) {
            throw new ObsoleteSessionAccess('obsolete session ID used');
        }
        if (isset($_SESSION['new_session_id'])) {
            // Cookie for the new ID was probably lost: move the client over.
            session_commit();
            session_id($_SESSION['new_session_id']);
            session_start();
            return;
        }
    }

    // 2. Idle and absolute timeouts, enforced in application code.
    if (isset($_SESSION['uid'])) {
        if ($now - ($_SESSION['last_seen'] ?? 0) > SESSION_IDLE
            || $now - ($_SESSION['created'] ?? 0) > SESSION_ABSOLUTE) {
            secure_logout();
            session_start();
            return;
        }
        $_SESSION['last_seen'] = $now;
        if ($now - ($_SESSION['rotated'] ?? 0) > SESSION_ROTATE) {
            secure_regenerate(true);
        }
    }
}

// $forward: let a client still holding the old ID be moved to the new one
// during the grace period (lost Set-Cookie on a flaky network). Never forward
// on a privilege change: whoever holds the old ID would be handed the new one.
function secure_regenerate(bool $forward): void
{
    $data = $_SESSION;                      // session_start() below loads an empty session
    $new = session_create_id();
    if ($forward) {
        $_SESSION['new_session_id'] = $new;
    }
    $_SESSION['destroyed'] = time();
    session_commit();                       // old session keeps the markers

    session_id($new);
    ini_set('session.use_strict_mode', '0'); // let session_start() accept $new
    session_start();
    ini_set('session.use_strict_mode', '1');
    $_SESSION = $data;
    $_SESSION['rotated'] = time();
}

function secure_login(int $uid): void
{
    secure_regenerate(false);               // rotate BEFORE marking authenticated
    $_SESSION['uid'] = $uid;
    $_SESSION['created'] = $_SESSION['last_seen'] = time();
}

function secure_logout(): void
{
    $_SESSION = [];
    $p = session_get_cookie_params();
    setcookie(session_name(), '', [
        'expires' => time() - 3600, 'path' => $p['path'], 'domain' => $p['domain'],
        'secure' => $p['secure'], 'httponly' => $p['httponly'], 'samesite' => $p['samesite'] ?: 'Lax',
    ]);
    session_destroy();
}
```

Wire it in by calling `secure_session_start()` instead of `session_start()`, `secure_login($userId)` after you have verified the password and any second factor, and `secure_logout()` from your logout handler. On `ObsoleteSessionAccess`, return 401 and log the event.

### What we tested

Against the same attack, with the helper in place:

```console
$ ./test.sh guard 8086
attacker ID: jt6upaht8b1i3hcuuk743hivm5
logged in
ID after login: 24qohqtgd4trsgfuov1tjn20nm
attacker replays old ID: anonymous
```

Periodic rotation, with rotation forced on every request and a 2-second grace period:

```console
$ ./test2.sh
account page for uid 42
login ID 10d0f50p49pto2ocoffotrbsv3 rotated to r4428iae8369vin9533ubpb292
old ID inside grace: account page for uid 42
old ID after grace:  401 obsolete session
logout with current ID: logged out
current ID after logout: anonymous
```

With a 1-second idle timeout, a request made 3 seconds after login came back anonymous with a new session cookie, and the logged-in session's file was gone from `session.save_path`. The pre-login session stayed on disk, marked as destroyed, until garbage collection, as the manual intends.

### Correction 1: never forward an old ID after login

The manual's second example deals with lost cookies: if the old ID comes back during the grace period, it switches the client to the new ID it stored in the old session. That is reasonable for periodic rotation, where the person holding the old ID is almost always the legitimate user. At login it is a hole. The attacker holds the old, pre-login ID, so forwarding hands them the new, authenticated one.

Our first draft forwarded in both cases, and the fixation test failed: the attacker's replay returned `account page for uid 42`. The manual hints at this in a comment ("Do not try to set session ID again if you would like to remove authentication flag"). The helper makes it explicit: `secure_regenerate(false)` at login, `secure_regenerate(true)` only for timed rotation. The trade-off is that a user whose login response is lost has to log in again.

### Correction 2: carry the session data across

In the manual's example, the new session is started with `session_id($new); session_start();`. In our test on PHP 8.3.6, that started an empty `$_SESSION`: the authenticated user vanished on the first periodic rotation. The helper copies the data before committing the old session and restores it after starting the new one. At login this also keeps pre-login state, such as a cart.

## Other session rules worth enforcing

- **Timeouts.** OWASP gives common idle timeouts of "2-5 minutes for high-value applications and 15-30 minutes for low risk applications". Every session should also have an absolute timeout "regardless of session activity". The helper's defaults (30 minutes idle, 8 hours absolute) are examples; set your own.
- **Locking.** PHP locks session data per request, which attackers can abuse to tie up workers. The manual suggests `session_start(['read_and_close' => true])` for requests that only read the session, and `session_commit()` as soon as you have finished writing.
- **Remember-me is not a long session.** The manual says not to "use long life session IDs for auto-login". Use a separate, single-use random token in its own cookie, and replace it each time it is used.
- **Track active sessions** if you need "log out everywhere" or the manual's response to obsolete-ID access. PHP doesn't do this for you. The manual suggests a user-ID-prefixed ID from `session_create_id()`, which "is vital" to pair with strict mode. Don't use a confidential value as the prefix.
- **Sessions don't stop CSRF.** "Sessions and authentication do not protect against CSRF attacks." See our [CSRF defences comparison](/posts/csrf-protection-samesite-cookies-tokens-and-fetch-metadata-compared/).
- **Session files are an attack surface.** October's PHP2Shell attempts tried to plant code through session files. See the [PHP2Shell patch-and-hunt guide](/posts/php2shell-cve-2026-109618-cve-2026-109619-patch-and-hunt/).

## Common mistakes

| Mistake | Why it fails |
|---|---|
| Setting `$_SESSION['uid']` before rotating | The pre-login ID, which an attacker may hold, briefly carries the authenticated state. The manual says to rotate first |
| `session_regenerate_id(true)` on every request | Concurrent requests lose their session, and you can no longer detect old-ID reuse |
| Relying on `gc_maxlifetime` for logout | Garbage collection is probabilistic, and activity on a stolen ID keeps it alive |
| Forwarding old IDs after login | Gives the attacker the new authenticated ID (our test) |
| Rotating only at login | A stolen post-login ID stays valid until logout or timeout. Add periodic rotation for sensitive apps |

## Limits of this article

The helper is a tested example, not a drop-in library. It assumes PHP's default `files` handler. A custom or Redis save handler must implement session ID validation for strict mode to work, as the manual notes for user-defined handlers. It does not implement the cross-session "remove authentication from all of the user's sessions" response, which needs an active-session registry. If you use a framework, prefer its session layer to this helper, and check that it rotates the ID at login and enforces timeouts. Our tests ran on a single PHP process. We did not load-test concurrent requests during rotation.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Strict mode does not stop initialized attacker IDs; rotate before setting auth; timestamps instead of immediate deletion; gc_maxlifetime not to be relied on; locking; auto-login; CSRF | [PHP manual: Session Management Basics](https://www.php.net/manual/en/features.session.security.management.php) (doc-en `reference/session/security.xml`) | Verified |
| Example rotation code, "not fully working code", lost-cookie forwarding | [PHP manual: session_regenerate_id](https://www.php.net/manual/en/function.session-regenerate-id.php) | Verified |
| gc_maxlifetime definition and 1440 default | [PHP manual: session runtime configuration](https://www.php.net/manual/en/session.configuration.php) | Verified |
| Renew on privilege change; idle and absolute timeout ranges | [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html) | Verified |
| Fixation succeeds without rotation (strict mode on); helper blocks it; forwarding at login reopens it; new session starts empty | Our tests, PHP 8.3.6 CLI, `php -S` | Verified (our test) |
