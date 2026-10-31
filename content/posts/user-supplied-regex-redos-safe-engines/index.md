+++
title = "User-Supplied Regex: How to Run It Without ReDoS"
date = 2026-10-31T04:50:00Z
tags = ["redos", "regex", "denial of service", "input validation", "node.js", "python", "appsec"]
categories = ["appsec"]
summary = "Search filters, alert rules, routing configs and log tools all end up accepting regular expressions from users. In a backtracking engine that is a denial-of-service switch you hand to whoever can type a pattern. This guide shows which engines are built for untrusted patterns (RE2, Go, Rust), which ones say plainly that they are not (.NET), what timeouts and possessive quantifiers can and cannot do, and two tested patterns for Python and Node.js."
description = "To run user-supplied regex safely, use a linear-time engine such as RE2, cap pattern length, and isolate backtracking engines behind a timeout. Tested code."
author = "Craig Leslie"
imageAlt = "Regex engine safety"
imageCredit = "Photo by [CHUTTERSNAP](https://unsplash.com/photos/close-up-photo-of-intertwining-strings-W2f1VZ6KuoM) on Unsplash"
takeaways = [
  "A backtracking engine can take exponential time on a crafted input. In our Python 3.13 test, ^(a+)+$ took 0.009 s on 18 characters and 0.54 s on 24; each extra two characters roughly quadrupled the time.",
  "If users supply the pattern, the attacker controls both halves of the problem. .NET's documentation says its engine 'does not offer protection against untrusted patterns' and that timeouts and NonBacktracking 'are not intended as a security boundary against malicious patterns'.",
  "Use an engine designed for untrusted patterns: RE2 (and Go's regexp, which uses its syntax) guarantees time linear in the input; Rust's regex crate guarantees O(m * n) and limits compiled pattern size by default.",
  "Linear-time engines drop backreferences and look-around. Reject those patterns with a clear error rather than falling back to a backtracking engine.",
  "If you must use a backtracking engine, run the match where you can kill it: a worker thread or process with a hard deadline, a pattern length cap and a memory limit. Ruby 3.2+ and .NET have built-in timeouts; Python's re and JavaScript's RegExp do not."
]

[[faq]]
q = "What is ReDoS?"
a = "Regular expression denial of service. Backtracking regex engines can take exponential time when a pattern has a repeated group containing another repetition or overlapping alternatives, such as (a+)+ or (a|aa)+, and the input almost matches. OWASP's wiki lists these as 'evil' regexes and notes that if the regex itself comes from user input, 'the attacker can inject an Evil Regex'."
[[faq]]
q = "Is it safe to build a regex from user input?"
a = "Only with an engine designed for it, or with the user's text escaped so it is matched literally. With RE2, Go's regexp or Rust's regex crate, matching time stays linear in the input. With backtracking engines such as Python's re, JavaScript's RegExp and .NET, a user-supplied pattern can hang a thread, and .NET's own docs say its engine does not protect against hostile patterns."
[[faq]]
q = "Do regex timeouts prevent ReDoS?"
a = "They limit the damage from your own patterns, but a timeout is not a complete defence against hostile ones. Ruby's Regexp.timeout and .NET's matchTimeout stop runaway backtracking. Microsoft says these features 'are not intended as a security boundary against malicious patterns', because a pattern can also consume resources at compile time or regardless of the input."
[[faq]]
q = "Does Node.js have a safe regex engine?"
a = "Not by default. V8 has an experimental non-backtracking engine behind the --enable-experimental-regexp-engine flag, which adds a non-standard l (linear) flag, but V8 describes it as experimental and much slower than its default engine on common patterns. For untrusted patterns in Node.js, use an RE2 binding or isolate matching in a worker you can terminate."
+++

If your product lets users type a regular expression (a log search box, an alerting rule, a URL routing rule, a "block messages matching" filter), you have handed them a way to burn your CPU. In a backtracking engine, a short pattern and a short input can keep a thread busy for seconds or years. The fix is not a better regex review process, because you are not the one writing the patterns.

**The short answer:** run user-supplied patterns on an engine that guarantees linear-time matching (RE2, Go's `regexp`, Rust's `regex`), cap pattern length, and reject features those engines do not support instead of quietly falling back. If you are stuck with a backtracking engine, run the match somewhere you can kill it on a deadline.

## Why a backtracking engine is the problem

Python's `re`, JavaScript's `RegExp` (V8's Irregexp) and .NET's default engine are backtracking engines. When a match fails, they back up and try every other way the pattern could have split the input. For most patterns that is fast. For patterns with nested or overlapping repetition, the number of ways to split the input grows exponentially.

OWASP's wiki page on [ReDoS](https://wiki.owasp.org/index.php/Regular_expression_Denial_of_Service_-_ReDoS) describes an "evil" regex as one with grouping with repetition where the repeated group contains repetition or overlapping alternation. Its examples include `(a+)+`, `([a-zA-Z]+)*`, `(a|aa)+` and `(a|a?)+`.

We timed the first one in Python 3.13.18 against a string of `a` characters followed by `!`, so the match has to fail:

```python
import re, time

pat = re.compile(r'^(a+)+$')
pos = re.compile(r'^(?:a++)+$')   # possessive quantifier, Python 3.11+

for n in (18, 20, 22, 24):
    s = 'a' * n + '!'
    t = time.perf_counter(); pat.match(s); t1 = time.perf_counter() - t
    t = time.perf_counter(); pos.match(s); t2 = time.perf_counter() - t
    print(f"n={n:2d} backtracking={t1:8.4f}s possessive={t2:.6f}s")
```

```text
n=18 backtracking=  0.0088s possessive=0.000005s
n=20 backtracking=  0.0429s possessive=0.000005s
n=22 backtracking=  0.1680s possessive=0.000003s
n=24 backtracking=  0.5356s possessive=0.000005s
```

Each additional two characters roughly quadrupled the time. Extrapolate to a 40-character input and one request ties up a worker for hours. Node.js 22 behaves the same way: `/^(a+)+$/.test('a'.repeat(24) + '!')` took 495 ms in our sandbox.

The possessive rewrite fixes this pattern because `a++` refuses to give characters back. That is a valid fix when **you** write the pattern. It does nothing when a user writes it, because the user will not write the possessive version.

## Two different threats

It helps to separate the cases, because the defences differ.

| Situation | Who controls the pattern | Main fix |
|---|---|---|
| Your validator runs on user input | You | Review the pattern, use possessive quantifiers or atomic groups, limit input length |
| Users submit patterns (search, rules, filters) | The attacker | Use a linear-time engine, cap pattern size, isolate matching |
| User text is spliced into your pattern | Partly the attacker | Escape it (`re.escape`, or an escape helper in JavaScript) or use a plain substring search |

This article is about the second row. The third row is the most common way the second row happens by accident: someone builds `new RegExp(userInput)` to implement a "contains" search that never needed a regex.

## Engines that are built for untrusted patterns

**RE2.** Google's [RE2 README](https://github.com/google/re2) states the design goal directly: it was built "to handle regular expressions from untrusted users without risk", and "one of its primary guarantees is that the match time is linear in the length of the input string". It also says its parser, compiler and execution engines "limit their memory usage by working within a configurable budget". The price is features: RE2 "does not support constructs for which only backtracking solutions are known to exist". That means no backreferences and no look-around.

**Go's `regexp`.** The package uses RE2 syntax, and its source documents that the implementation "is guaranteed to run in time linear in the size of the input".

**Rust's `regex` crate.** Its [README](https://github.com/rust-lang/regex) says "all regex searches in this crate have worst case `O(m * n)` time complexity, where `m` is proportional to the size of the regex and `n` is proportional to the size of the string being searched". Its documentation says the crate "also, to a certain extent, supports untrusted patterns", mainly "by limiting their size by default", which you can tune with `RegexBuilder::size_limit`.

Note the `m` in that complexity. Linear in the input is not the same as free: a huge pattern still costs more to compile and run. That is why a pattern length cap belongs in front of every engine, safe or not.

## Engines that say they are not

**.NET.** Microsoft's [regex best-practices page](https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-regex) is unusually direct:

> The .NET regular expression engine does not offer protection against untrusted *patterns*, and applications should not create regular expression patterns from untrusted user-provided values.

It adds that time-out values and `RegexOptions.NonBacktracking` (introduced in .NET 7, which "guarantees linear-time processing in the length of the input") "help protect against accidental performance problems in developer-authored patterns. They are not intended as a security boundary against malicious patterns." Use them for your own patterns, and do not treat them as permission to accept user-written ones.

**Ruby.** Ruby 3.2 added two ReDoS mitigations, described in the [3.2.0 release notes](https://www.ruby-lang.org/en/news/2022/12/25/ruby-3-2-0-released/). A memoization-based matcher completes "most Regexp matching (about 90% in our experiments)" in linear time, at the cost of memory "proportional to the input length". Because that optimization "cannot be applied to some kind of regular expressions, such as those including advanced features (e.g., back-references or look-around)", Ruby also added `Regexp.timeout`, a global setting, and a per-regex `timeout:` keyword on `Regexp.new`. Both help. Neither turns Ruby's engine into one designed for hostile patterns.

**Python and JavaScript.** Python's `re` documentation describes no match timeout. Python 3.11 added possessive quantifiers and atomic groups `(?>...)`, which help you write safer patterns but do nothing about patterns you did not write. JavaScript's `RegExp` has no timeout either. V8 has shipped an [experimental non-backtracking engine](https://v8.dev/blog/non-backtracking-regexp) since V8 8.8, behind `--enable-experimental-regexp-engine`, which adds a non-standard `l` ("linear") flag. V8's own post calls it experimental "because Irregexp is orders of magnitude faster than the new engine on most common patterns". With the flag on, `/^(a+)+$/l` failed on a 50,000-character evil input in about 3 ms in our Node.js 22.23 test. Running production on an experimental V8 flag is a decision to make deliberately, not a default.

Accepting patterns also exposes you to bugs in the regex parser and compiler themselves, not just slow matching. Our write-up of [GitLab CVE-2026-97229](/posts/gitlab-cve-2026-97229-ci-regex-rce-patch-and-hunt/) covers a remote code execution flaw in how GitLab compiled regular expressions from CI/CD configuration. Using a small, heavily fuzzed engine reduces that risk too.

## Pattern 1: Python with RE2

This uses the `google-re2` package (we tested 1.1.20251105 with Python 3.13). It caps pattern length, compiles with RE2, and turns unsupported syntax into a clear error your API can return as a 400.

```python
import re2

MAX_PATTERN = 256

def compile_user_pattern(pattern: str):
    """Compile a user-supplied pattern with RE2 or raise ValueError."""
    if len(pattern) > MAX_PATTERN:
        raise ValueError("pattern too long")
    try:
        return re2.compile(pattern)
    except re2.error as e:
        raise ValueError(f"unsupported or invalid pattern: {e}") from None
```

What happened when we ran it:

| Input | Result |
|---|---|
| `^(a+)+$` searched against 1,000,000 `a` characters plus `!` | No match, returned in about 2 ms |
| `(\w+)\s\1` (backreference) | Rejected: `invalid escape sequence: \1` |
| `^(?=.*\d).+$` (look-ahead) | Rejected: `invalid perl operator: (?=` |
| 300-character pattern | Rejected by the length cap |

The same evil pattern that took half a second on 24 characters in `re` finished a million characters in milliseconds. Two practical notes from the test: RE2 logs parse errors to stderr through its own logging, so expect noise in your logs when users submit bad patterns. And do not catch the error and retry with `re`. That fallback reopens the exact hole you closed.

## Pattern 2: Node.js with a killable worker

If you cannot add a native RE2 binding, isolate the backtracking engine. A worker thread can be terminated mid-match, which a `setTimeout` on the main thread cannot do: a regex blocks the event loop until it returns. This is tested on Node.js 22.23.4:

```javascript
// safe_match.mjs: run an untrusted pattern in a worker and kill it after a deadline.
import { Worker } from 'node:worker_threads';

const WORKER_SRC = `
  const { parentPort, workerData } = require('node:worker_threads');
  const { pattern, flags, input } = workerData;
  try {
    parentPort.postMessage({ ok: true, match: new RegExp(pattern, flags).test(input) });
  } catch (e) {
    parentPort.postMessage({ ok: false, error: e.message });
  }
`;

export function safeTest(pattern, input, { flags = '', timeoutMs = 100, maxPattern = 256 } = {}) {
  if (pattern.length > maxPattern) return Promise.resolve({ ok: false, error: 'pattern too long' });
  if (!/^[gimsuy]*$/.test(flags)) return Promise.resolve({ ok: false, error: 'bad flags' });
  return new Promise((resolve) => {
    const w = new Worker(WORKER_SRC, {
      eval: true,
      workerData: { pattern, flags, input },
      resourceLimits: { maxOldGenerationSizeMb: 32 },
    });
    const timer = setTimeout(() => { w.terminate(); resolve({ ok: false, error: 'timeout' }); }, timeoutMs);
    w.once('message', (m) => { clearTimeout(timer); w.terminate(); resolve(m); });
    w.once('error', (e) => { clearTimeout(timer); resolve({ ok: false, error: e.message }); });
  });
}
```

Results:

- `safeTest('^(a+)+$', 'a'.repeat(40) + '!')` returned `{ ok: false, error: 'timeout' }` after 103 ms. On the main thread that match would not finish.
- `safeTest('^[a-z]+@example\\.com$', 'alice@example.com')` returned `{ ok: true, match: true }`.
- `safeTest('(unclosed', 'x')` returned the syntax error instead of throwing.

The cost: spawning a worker per call averaged 25.4 ms in our sandbox, over 20 calls. That is fine for saving a rule. It is too slow for matching every log line. For high-volume matching, keep a small pool of long-lived workers and replace any worker you have to terminate, or move to an RE2 binding. This is a containment pattern, not a fix: an attacker can still make every match hit the timeout, so rate-limit pattern submissions and count timeouts per user.

## A checklist for features that accept patterns

1. **Ask whether you need regex at all.** Substring, prefix or glob matching covers most "search" features and has no ReDoS surface.
2. **Pick a linear-time engine** (RE2 or a binding, Go `regexp`, Rust `regex`) for any pattern a user can write, including admins and API clients.
3. **Cap pattern length** and, if you can, the number of patterns per user or rule set.
4. **Reject unsupported features with a clear message.** Never fall back to a backtracking engine.
5. **Cap input length** for each match. Linear time on a 2 GB input is still a lot of time. Our post on [decompression bombs in Node.js](/posts/nodejs-decompression-bomb-zlib-limits/) covers the related problem of inputs that grow after you accept them.
6. **If you must backtrack, isolate it.** Use a worker or process you can kill, a hard deadline, and a memory limit. Ruby's `Regexp.timeout` and .NET's `matchTimeout` are useful extra layers.
7. **Watch for it.** Log match timeouts and compile failures by user, and alert on spikes.

## Limits of this article

- Timings are from a shared cloud sandbox and will differ on your hardware. The growth rate, not the absolute numbers, is the point.
- We did not test .NET or Ruby directly, and we do not cover Java, PCRE or other engines here. Statements about them come from their documentation, quoted above.
- We tested one Python RE2 binding (`google-re2`). Node.js RE2 bindings exist, but we did not test one for this article.
- A linear-time engine removes catastrophic backtracking. It does not remove the need for size limits, rate limits or patching the engine itself.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Backtracking times for `^(a+)+$` in Python 3.13.18 and Node.js 22.23.4; RE2 and worker results | Our tests, code above | Verified (our sandbox) |
| "Evil" regex conditions and examples; attacker can inject an evil regex | [OWASP wiki: ReDoS](https://wiki.owasp.org/index.php/Regular_expression_Denial_of_Service_-_ReDoS) | Verified (archived wiki page) |
| RE2: built for untrusted users, linear in input, memory budget, no backtracking-only constructs | [google/re2 README](https://github.com/google/re2) | Verified |
| Go regexp: linear in the size of the input | [Go source, regexp.go](https://github.com/golang/go/blob/master/src/regexp/regexp.go) | Verified |
| Rust regex: worst case O(m * n); untrusted patterns handled mainly by size limit | [rust-lang/regex README and docs](https://github.com/rust-lang/regex) | Verified |
| .NET: no protection against untrusted patterns; timeouts and NonBacktracking not a security boundary | [Microsoft Learn: regex best practices](https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-regex) | Verified (docs source on GitHub) |
| Ruby 3.2 memoization (about 90% linear) and Regexp.timeout | [Ruby 3.2.0 release notes](https://www.ruby-lang.org/en/news/2022/12/25/ruby-3-2-0-released/) | Verified |
| Python 3.11 possessive quantifiers and atomic groups; no timeout documented | [Python re documentation](https://docs.python.org/3/library/re.html) | Verified |
| V8 experimental non-backtracking engine, `l` flag, slower than Irregexp | [V8 blog](https://v8.dev/blog/non-backtracking-regexp) | Verified |
