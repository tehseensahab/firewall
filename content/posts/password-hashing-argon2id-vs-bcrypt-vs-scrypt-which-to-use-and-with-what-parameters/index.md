+++
title = "Password Hashing: Argon2id vs bcrypt vs scrypt, and the Parameters to Use"
date = 2026-10-04T06:35:00Z
tags = ["authentication", "appsec"]
categories = ["appsec"]
summary = "Use Argon2id for new systems, keep bcrypt if you already have it and handle its 72-byte limit, and use PBKDF2 only when FIPS requires it. The harder part is choosing parameters your login servers can afford."
description = "Argon2id vs bcrypt vs scrypt vs PBKDF2 for password storage: OWASP and RFC 9106 parameters, measured timings, the bcrypt 72-byte limit and hash migration."
author = "FirewallSync Editorial"
imageAlt = "Heavy steel bank vault door with a large circular locking wheel"
imageCredit = "Photo by [Jason Dent](https://unsplash.com/photos/3wPJxh-piRw) on Unsplash"
takeaways = [
  "For a new system, OWASP's first choice is Argon2id with at least 19 MiB of memory, 2 iterations and 1 degree of parallelism.",
  "bcrypt is still acceptable for existing systems at a work factor of 10 or more, but most implementations only use the first 72 bytes of the password.",
  "OWASP's numbers are minimums. RFC 9106 recommends more: 64 MiB with 3 iterations, or 2 GiB with 1 iteration, both with 4 lanes.",
  "Memory cost is paid per login in progress. Multiply it by your peak concurrent logins before you raise it.",
  "You can change algorithm or parameters without a password reset by rehashing each password the next time its owner logs in."
]

[[faq]]
q = "Is bcrypt still safe to use in 2026?"
a = "OWASP's Password Storage Cheat Sheet still lists bcrypt for legacy systems, with a work factor of 10 or more and a password limit of 72 bytes. It is not OWASP's first choice for new systems, which is Argon2id. An existing bcrypt deployment with a reasonable work factor does not need an emergency migration."

[[faq]]
q = "What Argon2id parameters should I use?"
a = "OWASP's minimum is 19 MiB of memory, 2 iterations and 1 degree of parallelism, and it lists four other combinations it considers equivalent. RFC 9106 recommends higher settings: 64 MiB with 3 iterations and 4 lanes, or 2 GiB with 1 iteration and 4 lanes. Pick the highest setting your login servers can sustain at peak load."

[[faq]]
q = "Why not just use SHA-256 with a salt?"
a = "SHA-256 is designed to be fast, which is the wrong property for password storage. A salt stops an attacker from reusing one guess across many accounts, but each guess is still cheap. Password hashing functions such as Argon2id, scrypt and bcrypt are deliberately slow and let you raise the cost over time."

[[faq]]
q = "Do I need to store the salt separately?"
a = "No. Argon2id, bcrypt and scrypt libraries generate a random salt for each password and store it inside the encoded hash string alongside the parameters. A pepper is different: it is a secret key shared across all passwords and must be stored separately from the database."

[[faq]]
q = "How do I move from bcrypt to Argon2id without resetting passwords?"
a = "Verify the password against the old hash at login, and if it matches, hash the plaintext you now hold with Argon2id and replace the stored value. Accounts that never log in keep the old hash, so decide whether to expire those or wrap the old hashes inside the new algorithm."
+++

For a new application, hash passwords with Argon2id. If your platform has no good Argon2id library, use scrypt. If you already use bcrypt with a work factor of 10 or more, you can keep it, provided you deal with its 72-byte input limit. Use PBKDF2 only when you need FIPS-validated cryptography. That ordering is from the OWASP [Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html), and the rest of this article is about the parameters, because choosing the algorithm is the easy part.

## What a password hash has to do

A password hashing function turns a password into a value you can store and later compare against, without storing the password. OWASP's reasoning for hashing rather than encrypting is that hashing is "a one-way function", so there is no key that turns the database back into passwords. (For where encryption is the right tool, see [symmetric vs asymmetric encryption](/posts/symmetric-vs-asymmetric-encryption-when-to-use-each/).)

One-way is not enough. If your user table leaks, an attacker guesses candidate passwords, hashes each guess and compares. The defense is to make every guess expensive. Three properties do that:

- **A unique salt per password.** A salt is a random value mixed into each hash, so identical passwords produce different hashes and each account has to be attacked separately.
- **A tunable work factor.** A setting that makes each hash slower, which you raise as hardware improves.
- **Memory hardness.** A requirement that each hash uses a set amount of RAM. This matters because graphics cards and custom chips run enormous numbers of cheap computations in parallel, and memory is the resource that is hard to multiply.

General-purpose hashes such as SHA-256 have none of the last two. On the machine we used for the timings below, plain Python computed 1,000,000 SHA-256 hashes in about 0.43 seconds on one core. A single Argon2id hash at OWASP's minimum setting took about 25 milliseconds on the same machine. That gap is the point of the exercise.

## The four options compared

| | Argon2id | scrypt | bcrypt | PBKDF2 |
|---|---|---|---|---|
| Specified in | RFC 9106 (September 2021) | RFC 7914 (August 2016) | Provos and Mazières, USENIX 1999 | NIST SP 800-132 |
| Tunable time cost | Yes (`t`, iterations) | Yes (`N`) | Yes (work factor) | Yes (iterations) |
| Tunable memory cost | Yes (`m`), independent of time | Yes, but tied to `N` and `r` | No memory setting | No memory setting |
| Input length limit | No practical limit | No practical limit | 72 bytes in most implementations | No practical limit |
| OWASP position | First choice | Use when Argon2id is not available | Legacy systems | When FIPS compliance is required |
| OWASP minimum | 19 MiB, 2 iterations, parallelism 1 | N=2^17, r=8, p=1 | Work factor 10 | 600,000 iterations with HMAC-SHA-256 |

Argon2 won the Password Hashing Competition, an open contest that ran from 2012 and announced its winner in July 2015. It has three variants. RFC 9106 states that "Argon2id MUST be supported by any implementation", and OWASP recommends that variant because "it provides a balanced approach to resisting both side-channel and GPU-based attacks." Unless you have a specific reason, do not choose Argon2i or Argon2d.

## Parameters: the numbers and where they come from

### Argon2id

Argon2id has three settings: memory `m` (in kibibytes), iterations `t`, and parallelism `p` (the number of lanes, which maps to threads).

OWASP lists five combinations that it says give an equal level of defense, trading memory for CPU time:

| Memory `m` | Iterations `t` | Parallelism `p` |
|---|---|---|
| 47104 KiB (46 MiB) | 1 | 1 |
| 19456 KiB (19 MiB) | 2 | 1 |
| 12288 KiB (12 MiB) | 3 | 1 |
| 9216 KiB (9 MiB) | 4 | 1 |
| 7168 KiB (7 MiB) | 5 | 1 |

RFC 9106 recommends considerably more:

| RFC 9106 option | Memory | Iterations | Lanes | Salt | Output |
|---|---|---|---|---|---|
| First recommended | 2 GiB | 1 | 4 | 128 bits | 256 bits |
| Second recommended | 64 MiB | 3 | 4 | 128 bits | 256 bits |

These two sources are not in conflict. OWASP states a minimum. The RFC states what its authors recommend when memory is available. A reasonable reading: treat the OWASP row as the floor you must not go below, and the RFC's second option as the target if your servers can carry it.

Your library has an opinion too. The Python library `argon2-cffi` (version 25.1.0) defaults to 64 MiB, 3 iterations and parallelism 4, which its documentation identifies as the RFC 9106 low-memory profile. Other libraries default to other values, so read the defaults rather than assuming them.

### scrypt

scrypt has a CPU and memory cost `N`, a block size `r` and a parallelization setting `p`. Memory and time are both driven by `N`, so you cannot raise one without the other. OWASP's equivalent options:

| `N` | Memory (per OWASP) | `r` | `p` |
|---|---|---|---|
| 2^17 | 128 MiB | 8 | 1 |
| 2^16 | 64 MiB | 8 | 2 |
| 2^15 | 32 MiB | 8 | 3 |
| 2^14 | 16 MiB | 8 | 5 |
| 2^13 | 8 MiB | 8 | 10 |

### bcrypt

bcrypt has one setting, the work factor (also called cost or rounds). Each increase of one doubles the work. OWASP says the work factor "should be as large as verification server performance will allow, with a minimum of 10."

bcrypt has no memory setting. That is the main technical reason it is no longer the first choice: its cost can only be raised in time, not in RAM.

### PBKDF2

OWASP's iteration counts depend on the inner hash: 600,000 for PBKDF2-HMAC-SHA256, 220,000 for PBKDF2-HMAC-SHA512, and 1,400,000 for PBKDF2-HMAC-SHA1 (legacy only). Like bcrypt, PBKDF2 has no memory cost.

### What NIST requires

NIST SP 800-63B-4, the current US federal digital identity guideline, does not name an algorithm in its password verifier requirements. It says passwords "SHALL be salted and hashed using a suitable password hashing scheme", that the cost factor "SHOULD be as high as practical without negatively impacting verifier performance", and that the salt "SHALL be at least 32 bits in length". It points to NIST SP 800-132, the PBKDF2 specification, for approved schemes, which is why PBKDF2 is the answer when a contract requires FIPS-validated cryptography.

## What these settings cost: measured timings

We ran each configuration on one machine to show relative cost. This is a single measurement on a small cloud virtual machine with 2 virtual CPUs, using Python 3.13, `argon2-cffi` 25.1.0, `bcrypt` 5.0.0 and the standard library's `hashlib`. Each figure is the median of five or seven runs. Your hardware will give different absolute numbers; measure on your own login servers.

| Configuration | Time per hash (this machine) |
|---|---|
| Argon2id, 19 MiB, t=2, p=1 (OWASP minimum) | about 25 ms |
| Argon2id, 46 MiB, t=1, p=1 (OWASP alternative) | about 48 ms |
| Argon2id, 64 MiB, t=3, p=4 (RFC 9106 second option) | about 115 ms |
| bcrypt, work factor 10 | about 68 ms |
| bcrypt, work factor 12 | about 274 ms |
| bcrypt, work factor 14 | about 1,064 ms |
| scrypt, N=2^17, r=8, p=1 | about 404 ms |
| PBKDF2-HMAC-SHA256, 600,000 iterations | about 150 ms |

Three things to take from this:

- The OWASP "minimums" are not equal in server cost. On this machine the scrypt minimum took roughly 16 times as long as the Argon2id minimum. Do not read these timings as a ranking of attacker cost either: the algorithms differ in how well they resist specialized hardware, which is the reason memory-hard functions are preferred.
- bcrypt's doubling is visible. Two steps of work factor, from 10 to 12 and from 12 to 14, each multiplied the time by about four.
- OWASP's guidance is that "calculating a hash should take less than one second." bcrypt at work factor 14 exceeded that here.

### Size memory for concurrency, not for one login

Time is only half the budget. Argon2id and scrypt allocate their memory for every hash in progress, so the number that matters is memory multiplied by simultaneous logins.

A worked example, with assumed figures: if a login service peaks at 50 password verifications in progress at once, Argon2id at 19 MiB needs about 950 MiB for hashing at that moment, and at 64 MiB it needs 3,200 MiB (about 3.1 GiB). Neither figure includes the rest of the application.

This has a security side. An unauthenticated login endpoint that allocates 64 MiB per request is a way to exhaust a server. Cap concurrent hash operations with a queue or semaphore, and rate limit login attempts before they reach the hashing step. OWASP also warns that some PBKDF2 implementations make very long passwords much more expensive to hash, so set a maximum password length. NIST SP 800-63B-4 says verifiers should accept at least 64 characters, which makes 64 the floor for that maximum, not the ceiling.

## The bcrypt 72-byte limit

OWASP's wording: "bcrypt has a maximum length input length of 72 bytes for most implementations, so you should enforce a maximum password length of 72 bytes."

Two details make this more than trivia.

First, the limit is in bytes, not characters. A passphrase in a script that uses three bytes per character in UTF-8 reaches 72 bytes at 24 characters.

Second, implementations disagree on what happens past the limit. Some truncate silently, which means two long passwords that share their first 72 bytes are treated as the same password. The Python `bcrypt` library, in the 5.0.0 release we tested, refuses instead: hashing a 73-byte input raised `ValueError: password cannot be longer than 72 bytes, truncate manually if necessary`. Find out which behavior your library has before a long passphrase finds out for you.

The common workaround is to hash the password with a fast hash first and feed the result to bcrypt. OWASP describes this as dangerous if done naively, for two reasons: a raw hash can contain a NULL byte, which truncates the input in some bcrypt implementations, and an unkeyed pre-hash enables "password shucking", where an attacker tests hashes leaked from another site directly against yours. The construction OWASP gives avoids both by using a keyed hash and encoding the output:

```
bcrypt(base64(hmac-sha384(data: password, key: pepper)), salt, cost)
```

If you are writing new code, this is a good argument for Argon2id, which has no such limit.

## A working example

This is Python using `argon2-cffi` 25.1.0. We ran this code; it is a minimal illustration of the hash, verify and upgrade flow, not a complete authentication system.

```python
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, VerificationError, InvalidHashError

# OWASP minimum: m=19456 KiB (19 MiB), t=2, p=1. Raise these if your servers allow.
ph = PasswordHasher(time_cost=2, memory_cost=19456, parallelism=1)


def hash_password(password: str) -> str:
    return ph.hash(password)


def verify_password(stored_hash: str, password: str) -> tuple[bool, str | None]:
    """Return (ok, new_hash). new_hash is set when the stored hash should be replaced."""
    try:
        ph.verify(stored_hash, password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False, None
    if ph.check_needs_rehash(stored_hash):
        return True, ph.hash(password)
    return True, None
```

`hash_password` returns a string of this shape:

```
$argon2id$v=19$m=19456,t=2,p=1$vAqAbNgPClqje7Xsyzs9bA$K4vezmEN/bOYW9Jwno28K7vgP4vbehiavrZMUlDyZ5Y
```

Everything needed to verify the password later is in that one string: the variant, the version, the three parameters, the salt and the hash. That is why you do not need a separate salt column, and why you can change parameters later without breaking existing accounts.

Notes on the choices:

- `verify` raises an exception on a mismatch rather than returning `False`. The code catches the three documented exception types and treats all of them as a failed login.
- `check_needs_rehash` compares the parameters stored in the hash with the ones the `PasswordHasher` is configured with. When you raise the settings, every user is upgraded at their next successful login. In our test, a hash created with weaker settings verified successfully and came back with a replacement hash at the current settings.
- Do not compare hash strings yourself, and do not write your own salt generation. The library does both.

## Changing algorithm without a password reset

You cannot convert a bcrypt hash into an Argon2id hash, because you do not have the password. You do have it at one moment: during a successful login. OWASP describes this as the most common approach, "to wait until the user next authenticates, then re-hash their password."

The steps:

1. Store hashes in a format that identifies the algorithm. The `$argon2id$` and `$2b$` prefixes already do this.
2. At login, verify against whichever algorithm the stored hash uses.
3. On success, if the stored hash is not at the current algorithm and settings, hash the password again and overwrite the stored value.

The gap is accounts that never log in. They keep the old hash indefinitely. There are two ways to close it. One is to expire those hashes after a set period and require a reset. The other, which OWASP describes for upgrading legacy hashes, is to wrap them: run the old hash through the new algorithm now, so the database holds for example `argon2id(old_hash)`, and replace it with a direct hash at the next login. Wrapping protects every account immediately but means your verify code has to handle the layered form until each user returns.

## Should you add a pepper?

A pepper is a secret key applied to every password in addition to its salt. Unlike a salt, it is not stored with the hash. OWASP: "The pepper should not be public and should not be stored along with the generated hash."

NIST SP 800-63B-4 recommends the same idea in different words: verifiers "SHOULD perform an additional iteration of a keyed hashing or encryption operation using a secret key known only to the verifier", and that key "SHALL be stored separately from the hashed passwords", ideally in a hardware security module.

What it buys you: an attacker who steals only the database, for example through SQL injection or a leaked backup, cannot test guesses at all without the key. What it costs: a key you must store, protect and plan to rotate. It does not help if the attacker compromises the application server that holds the key. Treat it as a second layer on top of a properly configured hash, not a replacement for one.

## Common mistakes

- **Using a fast hash with a salt.** Salted SHA-256 or MD5 is still fast to guess against. The salt only prevents reuse of work across accounts.
- **Leaving parameters at whatever a tutorial used.** Work factors that were reasonable years ago are low now. Review them on a schedule, and use rehash-on-login to roll changes out.
- **Raising memory without checking concurrency.** See the sizing example above.
- **Ignoring bcrypt truncation.** Enforce a 72-byte maximum or use the keyed pre-hash construction.
- **Encrypting passwords instead of hashing them.** Encryption is reversible by anyone with the key, including an attacker who obtains it.
- **Treating the hash as the whole defense.** A strong hash slows offline guessing after a breach. It does nothing about phishing or credential stuffing against the live login form. That is the job of multi-factor authentication, covered in [MFA fatigue attacks and what stops them](/posts/mfa-fatigue-attacks-what-actually-stops-them/).

## A short decision guide

| Your situation | What to do |
|---|---|
| New application, no compliance constraint | Argon2id. Start at the RFC 9106 second option (64 MiB, t=3, p=4) if capacity allows, and never below OWASP's 19 MiB, t=2, p=1 |
| No maintained Argon2id library for your platform | scrypt at N=2^17, r=8, p=1 or an OWASP equivalent |
| Existing bcrypt at work factor 10 or more | Keep it, enforce the 72-byte limit, raise the work factor as far as login latency allows, plan a rehash-on-login move to Argon2id |
| Existing bcrypt below work factor 10 | Raise the work factor now and rehash on login |
| FIPS-validated cryptography required | PBKDF2-HMAC-SHA256 at 600,000 iterations or more |
| Unsalted or fast hashes (MD5, SHA-1, SHA-256) | Wrap existing hashes in Argon2id immediately, then replace at next login |

## Sources and verification

Checked on October 4, 2026. Recommended parameters change as hardware improves, so confirm them against the linked sources before relying on this page later. The timings are our own measurements on one machine and are illustrative.

| Important claim | Source | Verification |
|---|---|---|
| Algorithm order: Argon2id, then scrypt, bcrypt for legacy systems, PBKDF2 for FIPS; all minimum parameters and equivalent configurations | [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html), as published October 4, 2026 | Verified |
| Argon2id must be supported; first and second recommended options; 128-bit salt | [RFC 9106](https://www.rfc-editor.org/rfc/rfc9106.html), September 2021 | Verified |
| scrypt parameters N, r and p | [RFC 7914](https://www.rfc-editor.org/rfc/rfc7914.html), August 2016 | Verified |
| bcrypt introduced with an adaptable cost | [Provos and Mazières, "A Future-Adaptable Password Scheme"](https://www.usenix.org/legacy/events/usenix99/provos.html), USENIX 1999 | Verified |
| Argon2 announced as Password Hashing Competition winner in July 2015 | [password-hashing.net](https://www.password-hashing.net/) | Verified |
| NIST requirements for salting, cost factor, salt length, keyed hash and password length | [NIST SP 800-63B-4](https://pages.nist.gov/800-63-4/sp800-63b.html), password verifier requirements | Verified |
| `argon2-cffi` defaults match the RFC 9106 low-memory profile | [argon2-cffi API reference](https://argon2-cffi.readthedocs.io/en/stable/api.html), version 25.1.0, and the installed library | Verified |
| bcrypt 72-byte limit; pre-hashing risks; recommended keyed construction | OWASP Password Storage Cheat Sheet | Verified |
| Python `bcrypt` 5.0.0 raises an error above 72 bytes | Run in our build environment | Verified for that version only |
| Timings table | Measured on a 2 vCPU virtual machine, Python 3.13 | Qualified: one machine, illustrative |
| Concurrency memory example | Arithmetic on assumed figures (50 concurrent logins) | Qualified: example, not a measurement |
