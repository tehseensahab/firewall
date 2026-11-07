+++
title = "EPSS Scores for KEV CVEs: Why New Entries Score Low"
date = 2026-11-07T04:50:00Z
tags = ["epss", "cisa kev", "vulnerability prioritization", "vulnerability management", "security operations"]
categories = ["security-operations"]
summary = "An EPSS cutoff of 0.1 misses a quarter of CISA's KEV catalog today, and half of the entries added in the last 90 days. We tracked 113 KEV additions through 145 daily EPSS v5 files: the median score on the day of listing was 0.0076, and entries that crossed 0.1 after listing took a median of 14 days. Data, a tested audit script and the rule it implies."
description = "EPSS for KEV CVEs starts low: 49% of entries added in the last 90 days sit below 0.1, and late risers took a median 14 days to cross it. Audit script inside."
author = "John Marshall"
imageAlt = "A wooden-framed hourglass with grey sand pooling in the lower bulb, photographed against a black background"
imageCredit = "Photo by [Pablo Añón](https://unsplash.com/photos/an-hourglass-with-sand-in-it-on-a-black-background-XMW-B70xZy4) on Unsplash"
takeaways = [
  "Joining CISA KEV catalog 2026.11.06 to the EPSS file of November 6, 2026: 436 of 1,768 scored KEV CVEs (24.7%) sit below 0.1, and 54 (3.1%) below 0.01.",
  "Recency is the driver. Of 106 KEV entries added in the last 90 days, 52 (49.1%) are below 0.1, against 22.5% for entries listed more than a year ago.",
  "For 113 KEV entries added June 16 to October 7, 2026, the median EPSS on the day of listing was 0.0076. Only 16.5% of those scored that day were at or above 0.1; 30 days later it was 60.2%.",
  "Of the 79 entries that reached 0.1 by November 6, 15 were already there the day before listing; the other 64 took a median of 14 days. 34 never reached it.",
  "The rule this supports: KEV membership must route a CVE on its own. A pipeline that folds KEV into an EPSS cutoff is slowest exactly when an exploited CVE is newest."
]

[[faq]]
q = "Why do some CISA KEV vulnerabilities have a low EPSS score?"
a = "EPSS estimates the probability of exploitation activity in the next 30 days from automated data, while KEV is a human-curated list of CVEs with reliable evidence of exploitation. In our data the gap is largest for new listings: on the day CISA added an entry, the median EPSS score was 0.0076, and half of the entries added in the last 90 days are still below 0.1."

[[faq]]
q = "What EPSS threshold catches all KEV vulnerabilities?"
a = "None that is useful. On November 6, 2026, 54 KEV CVEs scored below 0.01 and one KEV entry had no EPSS score at all. A cutoff low enough to catch every KEV entry would flag a large share of all CVEs. Check KEV membership separately, then use EPSS for the CVEs without exploitation evidence."

[[faq]]
q = "Does EPSS go up after CISA adds a CVE to KEV?"
a = "In our sample it usually did, with a lag. For 113 KEV entries added between June 16 and October 7, 2026, the share at or above 0.1 rose from 16.5% on the day of listing to 33.6% after 7 days and 60.2% after 30 days. We cannot tell from the score files which inputs moved each score, so this shows timing, not cause."

[[faq]]
q = "How do I check my own EPSS threshold against KEV?"
a = "Download the KEV JSON from cisagov/kev-data and a daily EPSS file from empiricalsec/epss_scores, then run the audit script in this article with your cutoff. It reports how many KEV CVEs fall below the cutoff, split by how recently they were listed."
+++

If your patch pipeline uses an EPSS cutoff to decide what is urgent, it will miss about a quarter of CISA's Known Exploited Vulnerabilities (KEV) catalog, and roughly **half of the entries CISA added in the last 90 days**. Joining KEV catalog 2026.11.06 to the EPSS file for November 6, 2026, 436 of 1,768 scored KEV CVEs sit below 0.1. Tracking recent additions day by day shows why: EPSS scores for newly listed CVEs typically start low and take about two weeks to cross 0.1, which is the window in which a KEV listing matters most.

We argued in our [CVSS vs EPSS vs KEV comparison](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/) that KEV should be checked before EPSS. This article measures what happens when it is not, and gives you a script to test your own cutoff.

## The snapshot: KEV CVEs below common EPSS cutoffs

Data: the [KEV JSON](https://github.com/cisagov/kev-data) (catalog version 2026.11.06, released 2026-11-06T19:44Z, 1,769 entries) and the [EPSS daily file](https://github.com/empiricalsec/epss_scores) for November 6, 2026 (`model_version:v2026.06.15`, 400,985 scored CVEs). One KEV entry, CVE-2026-19868, added that day, had no EPSS score yet.

| EPSS cutoff | KEV CVEs below it (of 1,768) | Share |
| --- | --- | --- |
| 0.5 | 861 | 48.7% |
| 0.1 | 436 | 24.7% |
| 0.05 | 307 | 17.4% |
| 0.01 | 54 | 3.1% |
| 90th percentile | 248 | 14.0% |
| 95th percentile | 405 | 22.9% |

The median KEV CVE scores 0.536 (99.0th percentile), so the typical entry is well above any cutoff. The problem is the tail, and the tail is not random. If you are unsure what the `epss` and `percentile` columns mean, our [EPSS data feed guide](/posts/epss-data-feed-columns-percentile-vs-probability-and-how-to-join-it-to-a-scanner-export/) covers them.

## Newest KEV entries score lowest

Split by `dateAdded`, the share below 0.1 falls as entries age:

| Listed in KEV | KEV CVEs | Below 0.1 | Share | Median EPSS |
| --- | --- | --- | --- | --- |
| Within 90 days | 106 | 52 | 49.1% | 0.104 |
| 91 to 365 days ago | 207 | 57 | 27.5% | 0.444 |
| More than 1 year ago | 1,455 | 327 | 22.5% | 0.583 |

Several recent listings we covered are in that first row. On November 6, WordPress CVE-2026-119977 (added November 3) scored 0.0116, Ivanti CVE-2026-111357 and CVE-2026-118527 (added October 30) scored 0.0053 and 0.0082, and VMware ESX CVE-2026-41709 (added October 28) scored 0.0069. Each would sit below even a 0.05 cutoff.

## Tracking the lag: 113 KEV additions, day by day

A snapshot cannot show whether low scores are permanent or just early. So we took the 113 KEV entries added between June 16 and October 7, 2026, and looked up each one in every daily EPSS file from June 15 to November 6 (145 files). That window starts the day after EPSS v5 replaced v4, so every score comes from the same model (`v2026.06.15`); our [EPSS v5 analysis](/posts/epss-v5-score-shift-model-version-v2026-06-15/) explains why mixing models would distort this. The October 7 end date gives every entry at least 30 days of follow-up.

| Day relative to KEV listing | Entries with a score | At or above 0.1 | Share | Median EPSS |
| --- | --- | --- | --- | --- |
| Day before | 77 | 15 | 19.5% | 0.0072 |
| Day of listing | 91 | 15 | 16.5% | 0.0076 |
| 7 days after | 113 | 38 | 33.6% | 0.0220 |
| 30 days after | 113 | 68 | 60.2% | 0.1689 |

Notes on reading it:

- **Missing scores are real.** 36 of the 113 had no EPSS score the day before listing and 22 had none on the day itself, usually because the CVE had only just been published. By day 7 all 113 were scored.
- **Crossing time.** 15 entries were already at or above 0.1 the day before listing. Of the rest, 64 crossed 0.1 later, after a median of **14 days** (23 within a week). 34 had not reached 0.1 by November 6, 36 to 115 days after listing.
- **Timing, not cause.** EPSS files publish only the score. We cannot see which inputs moved a score, so we do not claim the KEV listing itself caused any rise.

Why the gap exists is consistent with how each list is built. CISA adds a CVE when there is "reliable evidence that the vulnerability has been actively exploited in the wild" ([CISA](https://cisa.gov/known-exploited-vulnerabilities)). EPSS is "the probability [0-1] of exploitation in the wild in the next 30 days (following score publication)", estimated from data ([EPSS scores README](https://github.com/empiricalsec/epss_scores)). The community [Risk Based Prioritization guide](https://riskbasedprioritization.github.io/epss/EPSS_and_CISA_KEV) puts it this way: EPSS reflects "the automated data we receive and collect", while KEV is "a list of human curated CVEs with historical exploitation activity", so a CVE can be in one and score low in the other. It also quotes FIRST's EPSS FAQ: where exploitation is evidenced, "that information should supersede anything EPSS has to say".

## What to change in a pipeline

These are our recommendations from the data above; we have not measured them on anyone's backlog.

1. **Route on KEV membership before any EPSS rule.** A listed CVE goes to the urgent queue whatever its score. This is the first step in our [prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/).
2. **Do not "promote" KEV entries by adding a bonus to the EPSS score.** A bonus sized for the median KEV entry (0.536) does nothing for an entry at 0.005.
3. **Treat a missing EPSS score as "unknown", not zero.** 22 of the 113 entries had no score on the day they were listed. A join that fills nulls with 0 drops exactly those.
4. **Refresh KEV more often than you refresh thresholds.** The [KEV JSON feed](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/) updates on listing days; the lag above means the KEV check is doing nearly all of the work for the first two weeks.
5. **Re-run the audit after every EPSS model change**, since cutoffs shift with the model.

## Audit your own cutoff

This script joins the two public files and reports how many KEV entries your cutoff misses, by listing age. We ran it with Python 3.12 on the files named above; the output below is for 0.1.

```python
#!/usr/bin/env python3
"""How many CISA KEV entries would an EPSS cutoff miss?
usage: kev_epss_audit.py known_exploited_vulnerabilities.json epss_scores-YYYY-MM-DD.csv.gz CUTOFF"""
import csv, gzip, json, sys
from datetime import date

kev_path, epss_path, cutoff = sys.argv[1], sys.argv[2], float(sys.argv[3])
catalog = json.load(open(kev_path))
with gzip.open(epss_path, "rt") as f:
    header = f.readline().strip()                 # "#model_version:...,score_date:..."
    scores = {r["cve"]: float(r["epss"]) for r in csv.DictReader(f)}
score_day = date.fromisoformat(header.split("score_date:")[1][:10])

print(f"KEV catalog {catalog['catalogVersion']}, EPSS {header[1:]}, cutoff {cutoff}")
buckets = {"added <= 90 days ago": [], "91-365 days": [], "over 1 year": []}
unscored = []
for v in catalog["vulnerabilities"]:
    if v["cveID"] not in scores:
        unscored.append(v["cveID"])
        continue
    age = (score_day - date.fromisoformat(v["dateAdded"])).days
    name = "added <= 90 days ago" if age <= 90 else "91-365 days" if age <= 365 else "over 1 year"
    buckets[name].append((v["cveID"], scores[v["cveID"]]))

total = below = 0
for name, rows in buckets.items():
    n_below = sum(1 for _, s in rows if s < cutoff)
    total += len(rows); below += n_below
    print(f"{name:22} {len(rows):5} KEV CVEs, {n_below:4} below cutoff ({n_below/len(rows):.1%})")
print(f"{'all scored':22} {total:5} KEV CVEs, {below:4} below cutoff ({below/total:.1%})")
print(f"not in EPSS file: {len(unscored)} {unscored[:5]}")
```

```text
$ python3 kev_epss_audit.py known_exploited_vulnerabilities.json epss_scores-2026-11-06.csv.gz 0.1
KEV catalog 2026.11.06, EPSS model_version:v2026.06.15,score_date:2026-11-06T12:00:23Z, cutoff 0.1
added <= 90 days ago     106 KEV CVEs,   52 below cutoff (49.1%)
91-365 days              207 KEV CVEs,   57 below cutoff (27.5%)
over 1 year             1455 KEV CVEs,  327 below cutoff (22.5%)
all scored              1768 KEV CVEs,  436 below cutoff (24.7%)
not in EPSS file: 1 ['CVE-2026-19868']
```

Get the KEV file from `raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json` and the EPSS file from the `empiricalsec/epss_scores` repository (one gzip file per day under the year folder). The script reads the whole EPSS file into memory, which is fine for about 400,000 rows.

## Limits of this article

The snapshot is one day (November 6, 2026). The day-by-day sample is 113 entries over one model version, which is enough to show a pattern but not to estimate a precise lag for any vendor or CVE type. "Day of listing" compares KEV `dateAdded` to the EPSS file of the same date; their publication times within the day differ. We did not examine why the 34 entries that stayed below 0.1 scored as they did.

## Sources and verification

| Important claim | Source | Status |
| --- | --- | --- |
| KEV counts, below-cutoff shares, medians, age buckets, per-CVE scores | [cisagov/kev-data](https://github.com/cisagov/kev-data) catalog 2026.11.06 joined to [empiricalsec/epss_scores](https://github.com/empiricalsec/epss_scores) 2026-11-06, computed with the script above | Verified (computed) |
| 113-entry day-by-day results (medians, shares, 14-day median crossing, 34 never) | Same KEV file and 145 daily EPSS files 2026-06-15 to 2026-11-06, all `v2026.06.15`, computed in Python | Verified (computed) |
| EPSS column definitions and 30-day window | [EPSS scores README](https://github.com/empiricalsec/epss_scores) | Verified |
| KEV inclusion criterion | [CISA KEV catalog page](https://cisa.gov/known-exploited-vulnerabilities) | Verified, Nov 7, 2026 |
| Data-generating difference between EPSS and KEV; FIRST FAQ "supersede" quote | [Risk Based Prioritization guide](https://riskbasedprioritization.github.io/epss/EPSS_and_CISA_KEV) (community guide quoting FIRST) | Qualified: secondary for the FIRST quote |
