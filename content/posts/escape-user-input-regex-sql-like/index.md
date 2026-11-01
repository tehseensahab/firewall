+++
title = "Escape User Input in Regex and SQL LIKE: Tested Fixes"
date = 2026-11-01T04:40:00Z
tags = ["regex", "input validation", "sql", "like", "javascript", "python", "go", "appsec"]
categories = ["appsec"]
summary = "A search box that drops user text into new RegExp() or a LIKE pattern is a small injection bug: a dot matches anything, .* matches everything, and a % turns a filtered search into a full table scan that returns every row. Parameterised queries do not fix it. This guide shows the correct escaping function in Python, JavaScript and Go, the LIKE ESCAPE rules for PostgreSQL and SQLite, and the replacement-string trap that catches people after they have escaped the pattern."
description = "Escape user text before it enters a regex or LIKE pattern: re.escape, RegExp.escape, regexp.QuoteMeta, and LIKE with an ESCAPE clause. Tested code inside."
author = "Craig Leslie"
imageAlt = "Dozens of wooden letterpress type blocks, letters and numerals in warm brown tones, scattered on a wooden surface"
imageCredit = "Photo by [Mr Cup / Fabien Barral](https://unsplash.com/photos/tilt-shift-lens-photography-close-shot-of-brown-letter-and-number-blocks-xzNXkB8oJRU) on Unsplash"
takeaways = [
  "If user text is meant to be matched literally, escape it before it becomes part of a pattern. In our tests an unescaped search for al.ce also matched alice, and .* matched every line.",
  "Use the platform function: Python re.escape, JavaScript RegExp.escape (Node.js 24 has it; Node.js 22 does not), Go regexp.QuoteMeta.",
  "The common hand-rolled JavaScript escaper misses cases. Placed after a backreference or inside a character class, it changed what the pattern matched in our Node.js 24 test; RegExp.escape did not.",
  "Bind parameters stop SQL injection but not LIKE wildcards. A bound value of % still matched every row in SQLite and PostgreSQL. Escape \\, % and _ in the value and state ESCAPE explicitly.",
  "Escaping the pattern is half the job. User text used as a replacement string is interpreted too: $& in JavaScript and backslash sequences in Python's re.sub. Pass a function instead."
]

[[faq]]
q = "How do I escape user input for a regular expression?"
a = "Use your language's built-in escaper and build the pattern from its output: re.escape in Python, RegExp.escape in JavaScript (Node.js 24 and current browsers), and regexp.QuoteMeta in Go. Do this whenever the user's text should match literally. If users are meant to type real patterns, escaping is the wrong tool; use a linear-time engine and limits instead."
[[faq]]
q = "Do parameterized queries escape LIKE wildcards?"
a = "No. A bind parameter makes the value data rather than SQL, so it prevents SQL injection, but LIKE still interprets % and _ inside that value. In our tests a bound value of % matched every row in both SQLite 3.53.1 and PostgreSQL 16.15. Escape the escape character, % and _ in the value, then add an ESCAPE clause."
[[faq]]
q = "Is RegExp.escape available in Node.js?"
a = "It is available in Node.js 24 (V8 13.6), where we tested it, and MDN marks it Baseline 2025 for current browsers. It is not available in Node.js 22, where typeof RegExp.escape is 'undefined'. Check for it at runtime and use a fallback on older runtimes, keeping the fallback's limits in mind."
[[faq]]
q = "Does escaping user input prevent ReDoS?"
a = "Escaping makes user text match literally, so the user can no longer add quantifiers or groups to your pattern. It does not fix a vulnerable pattern you wrote yourself, and it is not an option when the product is meant to accept user-written patterns. For that case, see our guide to running user-supplied regex safely."
+++

Search features have a habit of taking a user's text and dropping it straight into a pattern: `new RegExp(query)`, `re.search(term, line)`, `WHERE name LIKE '%' || $1 || '%'`. The user meant "find this text". The engine reads "match this pattern". A dot becomes "any character", `.*` becomes "everything", and `%` in a LIKE search returns every row you were filtering.

**The short answer:** when user text should match literally, escape it with the platform function (`re.escape`, `RegExp.escape`, `regexp.QuoteMeta`) before building the pattern. For SQL `LIKE`, bind the value as a parameter **and** escape `\`, `%` and `_` in it, with an explicit `ESCAPE '\'`. If the text is also used as a replacement string, pass a function, not a string.

This article is about user text that should be treated as literal. If your product lets users write real regular expressions, escaping is the wrong tool; see [User-Supplied Regex: How to Run It Without ReDoS](/posts/user-supplied-regex-redos-safe-engines/).

## What goes wrong without escaping

We ran each example below and show the output. Test environment: Python 3.13.18, Node.js 24.22.2 (V8 13.6) and 22.23.4, Go 1.24.7, SQLite 3.53.1 (Python's `sqlite3` module) and PostgreSQL 16.15, all on Linux.

```python
# Python 3.13: search log lines for a user-supplied term
import re
logs = ["user=alice", "user=al.ce", "user=bob", "user=admin"]

q = "al.ce"
[l for l in logs if re.search(q, l)]             # ['user=alice', 'user=al.ce']
[l for l in logs if re.search(re.escape(q), l)]  # ['user=al.ce']

q = ".*"
all(re.search(q, l) for l in logs)               # True: matches every line
[l for l in logs if re.search(re.escape(q), l)]  # []
```

The consequences depend on where the pattern is used. In a search box it is a wrong result. In a filter that decides which records a user may see, a match against tenant or account names, or a log-redaction rule, a wildcard where you expected a literal is an authorisation or data-exposure bug. Unescaped input also lets the user add nested quantifiers to your pattern, which is a route to ReDoS in backtracking engines.

## Regex: use the platform escaper

### Python: `re.escape`

The [Python docs](https://docs.python.org/3/library/re.html#re.escape) describe `re.escape` as escaping "special characters in *pattern*", useful "if you want to match an arbitrary literal string that may have regular expression metacharacters in it." Since Python 3.7, "only characters that can have special meaning in a regular expression are escaped."

```python
re.escape("a.b*c(d)")   # 'a\\.b\\*c\\(d\\)'
pattern = re.compile(r"\b" + re.escape(user_term) + r"\b", re.IGNORECASE)
```

### Go: `regexp.QuoteMeta`

Go's [`QuoteMeta`](https://pkg.go.dev/regexp#QuoteMeta) "returns a string that escapes all regular expression metacharacters inside the argument text; the returned string is a regular expression matching the literal text."

```go
// Go 1.24.7
fmt.Println(regexp.QuoteMeta("al.ce*(x)"))                                  // al\.ce\*\(x\)
fmt.Println(regexp.MustCompile(regexp.QuoteMeta("al.ce")).MatchString("alice")) // false
```

### JavaScript: `RegExp.escape`, and why the old snippet is not enough

[MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp/escape) describes `RegExp.escape()` as returning "a new string that can be safely used as a literal pattern for the `RegExp()` constructor", and marks it Baseline 2025. It is present in Node.js 24 and absent in Node.js 22:

```text
node v24.22.2 RegExp.escape: function
node v22.23.4 RegExp.escape: undefined
```

The output looks odd at first: `RegExp.escape("foo.bar")` returns `\x66oo\.bar`. MDN explains that a leading digit or ASCII letter is written as a `\x` escape so that, if the result is "immediately preceded by `\1`, `\x0`, `\u000`, etc., the leading character doesn't get interpreted as part of the escape sequence." Other punctuators such as `-` are also written as `\x` escapes.

That is exactly where the widely copied replace-based escaper falls short. We compared the two in Node.js 24:

```js
// Node.js 24.22.2
const escapeRegExp = s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); // common fallback

// 1. User text placed right after a backreference
new RegExp("(a)\\1" + escapeRegExp("1")).source;   // '(a)\\11'  -> test("aa1") is false
new RegExp("(a)\\1" + RegExp.escape("1")).source;  // '(a)\\1\\x31' -> test("aa1") is true

// 2. User text placed inside a character class
new RegExp("[" + escapeRegExp("a-z") + "]").test("m");   // true: became the range a-z
new RegExp("[" + RegExp.escape("a-z") + "]").test("m");  // false: matches only a, -, z
```

In both cases the fallback produced a valid pattern that matched something different from what was intended. MDN's advice is direct: "don't try to re-implement its functionality," because `RegExp.escape()` "is designed to use escape sequences that work in many more edge cases/contexts than hand-crafted code is likely to achieve."

For code that must also run on older runtimes:

```js
// Prefer the built-in; the fallback is only safe when the escaped text
// is not placed inside [...] or directly after a backslash escape.
const escapeRegExp = typeof RegExp.escape === "function"
  ? RegExp.escape
  : s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
```

## Escaping does not cover the replacement string

Teams that escape the pattern often forget that the replacement argument has its own syntax.

**JavaScript.** In `String.prototype.replace`, a replacement *string* interprets `$&`, `$1`, `$<name>` and similar. A function's return value is used as is:

```js
// Node.js 24.22.2
const name = "$&$&";                               // user-controlled
"Hello NAME".replace("NAME", name);                // 'Hello NAMENAME'
"Hello NAME".replace("NAME", () => name);          // 'Hello $&$&'
```

**Python.** The `re.escape` docs say it "must not be used for the replacement string in `sub()` and `subn()`, only backslashes should be escaped." In practice, passing a function avoids the problem entirely:

```python
s = "name: NAME"
re.sub("NAME", r"C:\new\1", s)          # re.error: invalid group reference 1 at position 7
re.sub("NAME", lambda m: r"C:\new\1", s)  # 'name: C:\\new\\1'
```

A replacement string that happens to contain `\n` or `\1` either changes the output or raises, depending on the text. Either is a bug when the text comes from a user. The same caution applies to anything that renders model or user output into templates; see [treating LLM output as untrusted input](/posts/llm-improper-output-handling-treat-model-output-as-untrusted-input/).

## SQL LIKE: parameters are not enough

A bind parameter keeps the value out of the SQL grammar, so `'; DROP TABLE` is just text. But `LIKE` interprets `%` (any sequence) and `_` (any single character) inside the value, bound or not. The [PostgreSQL docs](https://www.postgresql.org/docs/current/functions-matching.html) state: "The default escape character is the backslash but a different one can be selected by using the ESCAPE clause." Writing `ESCAPE ''` "effectively disables the escape mechanism."

Escape the escape character first, then the wildcards:

```python
def like_escape(s: str, esc: str = "\\") -> str:
    return s.replace(esc, esc * 2).replace("%", esc + "%").replace("_", esc + "_")

# SQLite: no escape character unless you declare one
cur.execute(
    "SELECT name FROM u WHERE name LIKE ? ESCAPE '\\'",
    ("%" + like_escape(term) + "%",),
)
```

Test table: `alice`, `bob`, `50% off`, `a_b`, `axb`. Results with the search value bound as a parameter:

| Search term | SQLite, bound, not escaped | SQLite, escaped + `ESCAPE '\'` | SQLite, escaped, no `ESCAPE` | PostgreSQL, escaped (default `\`) |
|---|---|---|---|---|
| `%` | all 5 rows | `50% off` | none | `50% off` |
| `_` | all 5 rows | `a_b` | none | not run |
| `a_b` | `a_b`, `axb` | `a_b` | none | `a_b` |

Two things stand out. First, a bound `%` or `_` returns every row: that turns a filtered search into an export of the table. Second, the escaping and the `ESCAPE` clause must agree. SQLite has no default escape character, so escaped input without `ESCAPE '\'` matched nothing. PostgreSQL uses backslash by default, but stating `ESCAPE '\'` anyway makes the query portable and removes the dependency on the default.

Two more differences we observed: SQLite's `LIKE` was case-insensitive for ASCII (`'ALICE' LIKE 'alice'` returned 1), while PostgreSQL's was case-sensitive (`false`; use `ILIKE` there). If your ORM offers a "contains" or "starts with" helper, check whether it escapes wildcards for your database before relying on it.

The same applies to other pattern operators: PostgreSQL's docs warn, "Be wary of accepting regular-expression search patterns from hostile sources", for `SIMILAR TO` and POSIX regex operators.

## Checklist

- Decide whether the user is supplying **text** or a **pattern**. Text gets escaped; patterns need a safe engine and limits.
- Use `re.escape`, `RegExp.escape` or `regexp.QuoteMeta`. Feature-detect `RegExp.escape` on Node.js 22 and older browsers.
- Never put fallback-escaped text inside `[...]` or directly after a backslash escape.
- For `LIKE`: bind the value, escape `\`, `%`, `_` in that order, and always write `ESCAPE '\'`.
- Use a function, not a string, when user text is the replacement in `replace` or `re.sub`.
- Add a test with `.`, `.*`, `%`, `_`, `$&` and a backslash in the input. The bug is invisible with ordinary names.

## Limits of this article

We tested the runtimes and versions listed above; MySQL, SQL Server and Oracle have their own LIKE escape rules and were not tested. Other regex dialects (Java, .NET, PCRE) have their own quoting functions not covered here. The JavaScript fallback is shown to illustrate its limits, not as a recommendation.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| `re.escape` purpose, 3.7 change, replacement-string warning | [Python `re` docs](https://docs.python.org/3/library/re.html#re.escape) (cpython main, Doc/library/re.rst) | Verified |
| `QuoteMeta` behaviour | [Go `regexp` package](https://pkg.go.dev/regexp#QuoteMeta) (src/regexp/regexp.go) | Verified |
| `RegExp.escape` behaviour, leading-character rule, Baseline 2025, re-implementation warning | [MDN RegExp.escape()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp/escape) | Verified |
| PostgreSQL default escape character, `ESCAPE ''`, regex caution | [PostgreSQL pattern matching docs](https://www.postgresql.org/docs/current/functions-matching.html) (read from the 17.1 text) | Verified |
| Fallback escaper failing after `\1` and inside `[...]`; replacement-string behaviour; LIKE results; case sensitivity | Our tests on the versions listed | Verified (tested) |
