+++
title = "EPSS Data Feed: What the Columns Mean, Probability vs Percentile, and How to Join It to a Scanner Export"
date = 2026-10-16T06:11:00Z
tags = ["vulnerability management", "tools"]
categories = ["security-operations"]
summary = "FIRST publishes EPSS scores as a free daily CSV with three columns. Here is what epss and percentile each promise, how the October 15, 2026 file is distributed, how it lines up with CISA's KEV catalog, and a tested Python script that adds both columns to a scanner export."
description = "EPSS data feed explained: the daily CSV and API, the cve, epss and percentile columns, model-version breaks, how the October 15, 2026 scores are distributed, and a tested Python script that joins EPSS to a scanner CSV."
author = "FirewallSync Editorial"
imageAlt = "Four aces (diamonds, spades, hearts, clubs) fanned out face up on a pale surface beside one face-down card with a red patterned back"
imageCredit = "Photo by [Daniel Dan](https://unsplash.com/photos/qxuA9-FxnSs) on Unsplash"
takeaways = [
  "The EPSS (Exploit Prediction Scoring System) daily file has three columns: cve, epss (a probability from 0 to 1 that exploitation activity will be observed in the next 30 days) and percentile (the share of scored CVEs with the same score or lower). The file we downloaded was scored 2026-10-15T12:03:56Z by model v2026.06.15 and held 389,824 CVEs.",
  "Scores are heavily skewed toward zero. In that file the median score was 0.00649 (0.65%) and only 4.44% of CVEs scored 0.1 or higher, so a score that looks small can still be high relative to other CVEs. FIRST says 0.10 sits around the 95th percentile; the file we downloaded puts it at about the 95.6th.",
  "All 1,746 entries in CISA's KEV catalog (version 2026.10.15) had an EPSS score, but not all scored high: 1,470 (84.2%) were at or above the 90th percentile and 61 (3.5%) scored below 0.01. EPSS and KEV answer different questions, so neither replaces the other.",
  "Use the daily CSV for bulk joins and the API for single-CVE lookups. FIRST says each model version changes the score scale, so a time series that crosses a version date (the latest is 2026-06-15) reflects a methodology change, not necessarily a change in the vulnerability.",
  "Rejected CVE IDs are not in the file. A join must treat a missing score as 'no score', not as zero risk."
]

[[faq]]
q = "Where do I download EPSS scores?"
a = "FIRST's Get the Data page lists a daily CSV at https://epss.empiricalsecurity.com/epss_scores-current.csv.gz (gzip-compressed, and the URL redirects, so curl needs -L), an API at https://api.first.org/data/v1/epss, and a historical archive at github.com/empiricalsec/epss_scores. No registration is required. We downloaded the CSV on October 16, 2026; it held the scores dated October 15, 2026."
[[faq]]
q = "Should I filter on the epss column or the percentile column?"
a = "FIRST calls the probability the model's direct output and the percentile a relative ranking of the same value. Use the probability for calculations such as expected counts, and the percentile when you want to compare a CVE with the rest of the scored population. Because scores cluster near zero, the percentile is the easier number to sanity-check a threshold against."
[[faq]]
q = "Does an EPSS score of 0.05 mean a CVE is unlikely to be attacked?"
a = "Not necessarily. FIRST's FAQ states that 0.05 means an estimated 5% probability of observed exploitation activity in the next 30 days, that the base rate is around 2 to 3%, and that 5% ranks in roughly the top 10% of published vulnerabilities. In the October 15, 2026 file, 7.89% of CVEs scored 0.05 or higher."
[[faq]]
q = "Why is a CVE missing from the EPSS file?"
a = "The file lists scored CVEs. In our test, two CVE IDs that were rejected in the CVE List (CVE-2024-1992 and CVE-2019-1508) were absent. A CVE that was published after the file was generated, or one the scorer does not cover, would also be missing; we did not test those cases."
+++

The Exploit Prediction Scoring System (EPSS) is a model that estimates how likely it is that exploitation activity for a given CVE will be observed in the next 30 days. FIRST, the Forum of Incident Response and Security Teams, publishes the scores for every scored CVE once a day, free of charge. This guide covers the data file itself: its columns, what each promises, where it breaks, how today's numbers are distributed, and a script that adds EPSS to a vulnerability scanner export.

**Scope.** This is research-based analysis plus one script we ran. On October 16, 2026 we read FIRST's EPSS pages (Get the Data, FAQ, Using EPSS, How EPSS Works) and the API documentation, downloaded the current CSV, called the API, and downloaded CISA's KEV JSON and the CVE Services records mentioned below. All counts are from the file scored 2026-10-15T12:03:56Z and change daily. We did not evaluate the model's accuracy; that is covered by the research FIRST links from its site. For how EPSS compares with CVSS and KEV as a decision signal, read [CVSS vs EPSS vs KEV](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/); for the KEV file, see [the KEV JSON feed guide](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/).

## What the score is, and what it is not

FIRST's FAQ defines EPSS as a data-driven model that estimates the probability a vulnerability will be exploited in the wild within the next 30 days, producing a score between 0 and 1 for every publicly disclosed CVE, updated daily. The scores are generated by Empirical Security and published through FIRST's EPSS Special Interest Group.

FIRST is explicit about the limits. The FAQ says EPSS does not measure how much damage successful exploitation would cause, whether the CVE affects your environment, or any compensating controls. Its measurement is also narrower than "exploited": the score estimates the likelihood that one of EPSS's data partners will detect, record and share evidence of exploitation *activity*. FIRST's How EPSS Works page adds that these sources record exploitation activity, not necessarily successful exploitation; honeypots are designed to be attacked, and intrusion prevention systems block what they see.

## Three ways to get the data

FIRST's [Get the Data](https://www.first.org/epss/data) page lists three routes.

| Route | Use it for | Notes from FIRST's page |
|---|---|---|
| Daily CSV, `https://epss.empiricalsecurity.com/epss_scores-current.csv.gz` | Bulk work: databases, joins against an asset inventory, dashboards | Gzip-compressed; the URL is stable but redirects, so curl needs `-L`; contains every scored CVE |
| API, `https://api.first.org/data/v1/epss` | Looking up one CVE or a small batch | Not for bulk download or keeping a local copy in sync. Maintained by FIRST. The API documentation labels the endpoint BETA |
| GitHub archive, `empiricalsec/epss_scores` | Historical analysis | One file per day, from 2021-04-14 |

The API documentation lists these query parameters: `cve` (comma-separated, up to 2,000 characters including commas), `date` (YYYY-MM-DD, since April 14, 2021), `epss-gt` / `epss-lt`, `percentile-gt` / `percentile-lt`, `days`, `q` (partial CVE ID search) and `scope=time-series` for the last 30 days. We tested two of these on October 16, 2026:

- A lookup for CVE-2021-44228 (Log4Shell) returned epss 0.99999 and percentile 1.0 for 2026-10-15.
- The same CVE with `date=2022-02-28` returned epss 0.94402, percentile 0.99944. That value comes from a different model version than today's, which matters for the next section.

## The three columns

The current file begins with a comment line, then a header, then one row per CVE. Ours began:

```
#model_version:v2026.06.15,score_date:2026-10-15T12:03:56Z
cve,epss,percentile
CVE-1999-0001,0.04753,0.91753
```

| Column | Type | Meaning (FIRST) | Watch for |
|---|---|---|---|
| `cve` | CVE ID | The CVE identifier | Normalize case and whitespace before joining |
| `epss` | Decimal, 0 to 1 | Probability of observed exploitation activity in the next 30 days | A probability, not a severity; 0.05 means 5% |
| `percentile` | Decimal, 0 to 1 | The proportion of all scored vulnerabilities with the same score or lower | A ranking of the `epss` value, so it depends on the whole population that day |

The `#` comment line is part of the file in current versions. FIRST says files from the v2 model onward (published from 2022-02-04) include it, while v1 files have no comment. A parser that expects the first line to be the header will fail, so skip lines that start with `#`.

### Model versions break time series

FIRST lists five model versions and when each began publishing: v1 (2021-04-14), v2 (v2022.01.01, 2022-02-04), v3 (v2023.03.01, 2023-03-07), v4 (v2025.03.14, 2025-03-17) and v5 (v2026.06.15, 2026-06-15). It warns that each version produced a score shift on its start date, so a series that crosses one of them "reflects a change in methodology, not a change in the vulnerability itself." If you graph a CVE's score over months, mark those dates. Our own file reported `v2026.06.15`, matching the fifth entry.

FIRST also says that day-to-day changes inside a version are by design: scores move because new signals arrived (for example exploit code appearing or new analysis being published), not because the model changed.

## Probability vs percentile, with today's numbers

FIRST's FAQ says the probability is the model's primary output and the percentile is a transformation of it. Because most CVEs are never exploited, the distribution is skewed toward zero. We measured it on the October 15, 2026 file:

| Measure (389,824 scored CVEs) | Count | Share of file |
|---|---|---|
| Median `epss` | 0.00649 | n/a |
| Mean `epss` | 0.0267 | n/a |
| `epss` at least 0.01 | 147,786 | 37.9% |
| `epss` at least 0.04 | 37,460 | 9.6% |
| `epss` at least 0.05 | 30,749 | 7.9% |
| `epss` at least 0.10 | 17,309 | 4.4% |
| `epss` at least 0.50 | 4,332 | 1.1% |
| `epss` at least 0.90 | 801 | 0.2% |
| `percentile` at least 0.90 | 38,987 | 10.0% |
| `percentile` at least 0.99 | 3,903 | 1.0% |

Three readings follow. These are our interpretations of the table, not FIRST statements.

1. **A "failing grade" intuition misleads.** Only 0.2% of CVEs scored 0.9 or higher. A threshold of 0.5 ignores 98.9% of the file. FIRST makes the same point, saying a 50% threshold "deprioritizes the 98.8% of all published vulnerabilities" (its figure was computed on its own data and rounds slightly differently from ours).
2. **Small numbers can be high.** FIRST says 0.10 sits around the 95th percentile; in our file 4.4% of CVEs were at or above 0.1, so about the 95.6th. The 90th percentile in our file corresponds to a probability of about 0.0385, which is consistent with FIRST's statement that the 90th percentile is roughly 0.04.
3. **Our mean and median are close to FIRST's.** FIRST says the mean is around 2.8% and the median around 0.7%; ours are 2.7% and 0.65%. FIRST does not say which day its figures describe.

FIRST also offers a way to translate a CVSS-based policy. It says that over the previous 12 months about 61,000 CVEs were published and just over 10% were rated CVSS Critical, so acting on roughly the 90th EPSS percentile (a score of about 0.04 or more) yields a similar-sized workload as acting on CVSS Critical, and that acting on CVSS High and above corresponds to about 0.008. These are FIRST's rules of thumb for migrating a program, which it describes as a starting point rather than an endorsement of CVSS categories. We did not reproduce them.

### Combining probabilities

FIRST's Using EPSS page gives two formulas, both assuming exploitation events are approximately independent: the probability that at least one of *n* vulnerabilities is exploited is 1 minus the product of (1 − p), and the expected number exploited is the sum of the scores. FIRST's example is 100 vulnerabilities each scoring 0.05. We checked the arithmetic: 1 − 0.95^100 = 0.9941, or 99.4%, and the expected count is 5. FIRST notes that both estimates depend on calibration holding at portfolio level and should not be treated as precise forecasts. Real findings are rarely independent (many hosts share one CVE, and one campaign can use several), so use these for trend tracking, not as a promise.

## How EPSS lines up with CISA's KEV catalog

We joined the file to CISA's KEV JSON, catalog version 2026.10.15 (released 2026-10-15T17:00:11Z, 1,746 entries). The EPSS file was scored about five hours earlier, so an entry added in between could have been missing; none was. All 1,746 KEV CVE IDs had an EPSS row.

| KEV entries (n = 1,746) | Count | Share |
|---|---|---|
| `percentile` at least 0.90 | 1,470 | 84.2% |
| `percentile` below 0.90 | 276 | 15.8% |
| `epss` at least 0.50 | 870 | 49.8% |
| `epss` below 0.01 | 61 | 3.5% |
| Median `epss` | 0.49166 | n/a |

KEV is about 0.45% of the scored file (1,746 of 389,824), which is in line with FIRST's statement that KEV lists roughly 0.5% of published CVEs. Two cautions on reading this table:

- **The two measure different things.** KEV records that CISA has evidence a CVE was exploited. EPSS estimates activity in the next 30 days from many signals. A KEV CVE with a low EPSS score is not a contradiction; the old attack may be quiet now, and per FIRST the score reflects current signals.
- **Overlap is not proof of accuracy.** FIRST lists VulnCheck's KEV among its data partners; its page does not say CISA's catalog is an input. We cannot tell from the public pages how much of the KEV overlap is built into the training data, so do not read the 84.2% as an independent validation.

The practical takeaway matches [our earlier ordering](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/): a KEV listing is evidence that exploitation has happened, and should not be downgraded because EPSS is low.

## A tested script to add EPSS to a scanner export

This script downloads the current file, normalizes the CVE ID in each scanner row, and appends `epss` and `epss_percentile`. It uses only the Python standard library.

```python
import csv, gzip, sys, urllib.request

EPSS_URL = "https://epss.empiricalsecurity.com/epss_scores-current.csv.gz"

def load_epss(url=EPSS_URL):
    raw = gzip.decompress(urllib.request.urlopen(url).read()).decode("utf-8")
    lines = raw.splitlines()
    header = lines[0] if lines[0].startswith("#") else ""
    body = lines[1:] if header else lines
    scores = {r["cve"].strip().upper(): (float(r["epss"]), float(r["percentile"]))
              for r in csv.DictReader(body)}
    return header, scores

def main(scanner_csv, out_csv):
    header, scores = load_epss()
    print("EPSS file header:", header or "(none)", "| CVEs scored:", len(scores))
    with open(scanner_csv, newline="") as f, open(out_csv, "w", newline="") as g:
        rd = csv.DictReader(f)
        wr = csv.DictWriter(g, fieldnames=rd.fieldnames + ["epss", "epss_percentile"])
        wr.writeheader()
        for row in rd:
            hit = scores.get(row["cve"].strip().upper())
            row["epss"], row["epss_percentile"] = hit if hit else ("", "")
            wr.writerow(row)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
```

We ran it on October 16, 2026 against a five-row CSV we wrote, with a `cve` column:

```
host,cve
web-1,CVE-2021-44228
web-2,cve-2023-4863 
db-1,CVE-2024-0001
bad-1,CVE-2099-0001
web-3,CVE-1999-0001
```

Output:

```
EPSS file header: #model_version:v2026.06.15,score_date:2026-10-15T12:03:56Z | CVEs scored: 389824
host,cve,epss,epss_percentile
web-1,CVE-2021-44228,0.99999,1.0
web-2,cve-2023-4863 ,0.99979,0.9998
db-1,CVE-2024-0001,0.00949,0.60451
bad-1,CVE-2099-0001,,
web-3,CVE-1999-0001,0.04753,0.91753
```

Row `web-2` shows the normalization working (lowercase with a trailing space still matched), and `bad-1`, a made-up ID, comes out blank. The script prints the model version and score date; store those with the output so you can later explain why a score differs.

### Pitfalls

- **Blank is not zero.** A blank score means no EPSS row was found. Do not coerce it to 0 before sorting.
- **Rejected CVEs are not scored.** CVE-2024-1992 (rejected as a duplicate of CVE-2024-2306) and CVE-2019-1508 (rejected as an unused candidate number) were both absent from the file. If your scanner emits one, the right action is to look at the CVE record's state; see our companion article on [CVE record states](/posts/cve-record-states-published-rejected-and-disputed-what-each-means-for-vulnerability-triage/).
- **Disputed CVEs are scored.** CVE-2026-14683, which its CNA tagged as disputed, had epss 0.0016 and percentile 0.04694. A score does not tell you whether the dispute is valid.
- **Old scores in tickets age badly.** FIRST says scores are recomputed every day. Store the score date next to the value, or re-pull daily.
- **Use the API sparingly.** FIRST asks that bulk work use the CSV or the GitHub archive.

### Production suggestions

These are our suggestions and were not tested beyond the script above: download once a day and keep each day's file; fail the job if the header does not contain `cve,epss,percentile` or the row count drops sharply; store the `model_version` and `score_date` comment with each load; and treat EPSS as one column next to exposure, asset criticality and KEV status. FIRST's Using EPSS page recommends combining EPSS with environment-specific signals because the score has no knowledge of your assets.

## Limits of this article

We tested the script only on a five-row file, not a real scanner export. Counts are from one file scored on October 15, 2026, and one KEV version. We did not assess the model's accuracy or calibration, did not read the research papers FIRST links, and did not verify FIRST's own figures beyond the comparisons stated above. FIRST's Using EPSS page states some thresholds without a date, so treat them as of the page we read on October 16, 2026. We did not find a documented rate limit in the API page we read, so check the API documentation before building anything that makes many calls.

## Sources and verification

Checked on October 16, 2026.

| Important claim | Source | Verification |
|---|---|---|
| EPSS estimates the probability of exploitation in the next 30 days, a 0 to 1 score updated daily; not a complete risk score | [FIRST EPSS FAQ](https://www.first.org/epss/faq) | Verified |
| Three access routes; CSV URL; three columns; percentile definition; archive back to 2021-04-14; model version start dates and the score-shift warning | [FIRST, Get the Data](https://www.first.org/epss/data) | Verified |
| API endpoint, parameters, time-series scope, BETA status | [FIRST API documentation](https://api.first.org/epss/) | Verified |
| Sources record exploitation activity, not necessarily success; VulnCheck KEV listed as a data partner | [FIRST, How EPSS Works](https://www.first.org/epss/how-it-works) | Verified |
| Aggregation formulas; 100 vulnerabilities at 0.05 give about 99.4% and an expected count of 5; 90th percentile about 0.04; CVSS High about 0.008 | [FIRST, Using EPSS](https://www.first.org/epss/using-epss) and our arithmetic (1 − 0.95^100 = 0.9941) | Verified; FIRST's thresholds are its own rules of thumb |
| File header: model v2026.06.15, scored 2026-10-15T12:03:56Z, 389,824 CVEs; all distribution counts and medians | [EPSS daily CSV](https://epss.empiricalsecurity.com/epss_scores-current.csv.gz), downloaded October 16, 2026 (scores dated October 15, 2026) | Qualified: one day's snapshot, our calculations |
| KEV catalog version 2026.10.15, 1,746 entries, all scored; overlap counts | [CISA KEV JSON](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json) joined to the EPSS file by us | Qualified: snapshot; overlap is not evidence of accuracy |
| CVE-2021-44228 scores on 2026-10-15 and 2022-02-28 | [FIRST EPSS API](https://api.first.org/data/v1/epss?cve=CVE-2021-44228&date=2022-02-28) | Verified on October 16, 2026 |
| CVE-2024-1992 and CVE-2019-1508 are REJECTED and absent from the file; CVE-2026-14683 is tagged disputed and scored | [CVE Services records](https://cveawg.mitre.org/api/cve/CVE-2024-1992) and the EPSS CSV | Verified on October 16, 2026 |
| Script output | Run by us on October 16, 2026 against the five-row CSV shown | Verified |
| Production suggestions | Our analysis | Qualified: not tested |
