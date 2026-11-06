+++
title = "EPSS v5: How Scores Shifted and What to Re-baseline"
date = 2026-11-06T04:45:00Z
tags = ["epss", "epss v5", "vulnerability management", "vulnerability prioritization", "security operations"]
categories = ["security-operations"]
summary = "EPSS v5 (model v2026.06.15) replaced v4 in the daily feed on June 15, 2026. We diffed the last v4 file against the first v5 file: 26% fewer CVEs at or above 0.1, 41% fewer at or above 0.5, a median score almost three times higher, and only 588 of the top 1,000 CVEs unchanged. Here is what that means for threshold rules, and a tested guard that stops your pipeline on the next model change."
description = "EPSS v5 went live on June 15, 2026. CVEs at or above 0.1 fell 26% overnight and top-1,000 overlap was 588. Diff data, threshold fixes and a model_version guard."
author = "John Marshall"
imageAlt = "Close-up of an oval dial thermometer whose glass is covered in ice crystals, with a red needle visible beneath the frost"
imageCredit = "Photo by [Chris Kennedy](https://unsplash.com/photos/a-close-up-of-a-thermometer-on-a-table-kXvEKPsv5oE) on Unsplash"
takeaways = [
  "The EPSS daily file switched from model v2025.03.14 (v4) to v2026.06.15 (v5) on June 15, 2026. The first line of every file names the model, so a pipeline can detect the change without any outside notice.",
  "Comparing the June 14 (v4) and June 15 (v5) files: 23,069 CVEs scored 0.1 or higher before the switch and 17,041 after, a 26.1% drop. At 0.5 the count fell from 7,193 to 4,249 (40.9%).",
  "Low scores moved up and high scores moved down. The median rose from 0.00262 to 0.00751, while the 99th percentile fell from 0.772 to 0.595. 71.5% of CVEs scored on both days moved by a factor of two or more.",
  "Percentile rules kept their size by design, but not their membership: 9,837 CVEs crossed into the 90th percentile and 9,944 dropped out of it in one day, against 25 and 29 the day before.",
  "KEV-listed CVEs mostly kept their flags: of 1,619 entries added by June 14, 1,224 scored 0.1 or higher under v4 and 1,219 under v5. Their median score still fell from 0.704 to 0.535."
]

[[faq]]
q = "When did EPSS v5 start?"
a = "The daily EPSS file carried model_version v2026.06.15 for the first time on June 15, 2026. The June 14 file was the last scored by v2025.03.14 (v4). Empirical Security announced v5 on May 13, 2026, and published beta files labelled v2026.05.12 between May 22 and June 8."

[[faq]]
q = "Why did my EPSS alerts drop after June 15, 2026?"
a = "If the alert uses a fixed probability cutoff, v5 put far fewer CVEs above it. In our comparison, the count of CVEs at or above 0.1 fell 26.1% and at or above 0.5 fell 40.9% between the last v4 file and the first v5 file. Nothing about those vulnerabilities changed that day; the model did."

[[faq]]
q = "Should I use EPSS percentile or probability after the v5 change?"
a = "Percentile keeps a stable count (the top 10% is always about 10% of scored CVEs), so it survives model changes better for queue sizing. Probability is the calibrated output and the one to use for expected-value reasoning, but any fixed cutoff needs re-baselining whenever model_version changes."

[[faq]]
q = "How do I detect the next EPSS model change?"
a = "Read the first line of each daily CSV. Since v2 it is a comment of the form #model_version:...,score_date:.... Compare model_version to the value from your previous run, and if it differs, pause threshold-driven alerts, diff the two files and re-baseline before resuming."
+++

The EPSS daily file changed models on **June 15, 2026**. The first line of the June 14 file reads `#model_version:v2025.03.14` (v4). The June 15 file reads `#model_version:v2026.06.15` (v5). We compared those two files, which together hold 340,204 CVEs scored on both days. If your pipeline gates on a fixed EPSS probability, it lost about a quarter of its flagged CVEs overnight: **23,069 CVEs scored 0.1 or higher under v4 and 17,041 under v5**. Nothing about those vulnerabilities changed that day; the model did.

This article covers what changed in v5, what the shift looks like in the data, and what to re-baseline. For the file format itself (columns, header line, how to join it to a scanner export), see our [EPSS data feed guide](/posts/epss-data-feed-columns-percentile-vs-probability-and-how-to-join-it-to-a-scanner-export/). That guide already lists the five model versions and their start dates; this one measures the most recent change.

## What changed in v5

Empirical Security, which runs the EPSS model and hosts the data, [announced EPSS V5 on May 13, 2026](https://lifestyle.kbew98country.com/story/220743/empirical-security-releases-epss-v5/). The release says v5 "incorporates improved modeling techniques and optimization algorithms" and that "the calibration step has been refined." It also cites a better classifier for published exploit code and "the addition of new data feeds."

The headline claim is a 23% improvement. Empirical's [research post](https://research.empiricalsecurity.com/research/epss-v5-is-here) defines the metric only loosely, as one that rewards "ranking genuinely exploited vulnerabilities above ones that pose no real threat." On data from May 4, 2026, it reports that v4 scored 0.514 and v5 scored 0.633, where "a random guess would score around 0.025, and a perfect model would score 1.0." We did not reproduce that evaluation.

The rollout is visible in the public [empiricalsec/epss_scores](https://github.com/empiricalsec/epss_scores) repository:

| Date | What the repository shows |
| --- | --- |
| 2026-05-22 to 2026-06-08 | `beta_scores/epssv5_beta-*.csv.gz`, header `#model_version:v2026.05.12` |
| 2026-06-14 | Last daily file on `v2025.03.14` (v4), `score_date` 12:55:00Z |
| 2026-06-15 | First daily file on `v2026.06.15` (v5), `score_date` 12:03:41Z |
| 2026-11-05 | Still `v2026.06.15` |

The beta files carry a different model label (`v2026.05.12`) from the production model, so treat beta scores as a preview of v5, not as v5 itself. The repository README lists the model changes for v2, v3 and v4 but, as of November 6, 2026, has no v5 entry. The file header was the reliable signal.

The CSV format did not change. Both files have the same comment line followed by `cve,epss,percentile`.

## How the scores moved

We loaded `2026/epss_scores-2026-06-14.csv.gz` and `2026/epss_scores-2026-06-15.csv.gz` from the repository and compared CVEs present in both. For a baseline, we ran the same comparison on June 13 and June 14, two consecutive v4 days.

| Measure | v4 (June 14) | v5 (June 15) | Normal day (June 13 to 14) |
| --- | --- | --- | --- |
| CVEs scored | 341,350 | 340,247 | 341,309 to 341,350 |
| Median EPSS | 0.00262 | 0.00751 | unchanged |
| Mean EPSS | 0.03328 | 0.02934 | unchanged |
| 99th percentile of EPSS | 0.77230 | 0.59470 | n/a |
| CVEs at or above 0.1 | 23,069 | 17,041 | 23,071 to 23,069 |
| CVEs at or above 0.5 | 7,193 | 4,249 | 7,194 to 7,193 |
| Crossed 0.1 upward / downward | 3,820 / 9,847 | | 9 / 11 |
| Crossed the 90th percentile in / out | 9,837 / 9,944 | | 25 / 29 |
| Moved by 2x or more | 243,259 of 340,204 (71.5%) | | 313 of 341,309 |
| Top 1,000 by EPSS that stayed top 1,000 | 588 | | 999 |

Three patterns stand out.

**The distribution got narrower.** The lowest v4 score was 0.00001 and 93,484 CVEs sat below 0.001. Under v5 the minimum is 0.00046 and only 3,552 CVEs are below 0.001. At the top end, the 99th percentile fell from 0.772 to 0.595. The median ratio of v5 to v4 score was 2.89: most low-scored CVEs went up, while many of the high scorers came down. That fits the release's description of recalibration, but the release does not say this is the intended effect, so treat it as our reading of the data.

**Fixed cutoffs shrank.** A rule like `epss >= 0.1` matched 26.1% fewer CVEs the day v5 went live, and `epss >= 0.5` matched 40.9% fewer. Of the CVEs that crossed 0.1, 9,847 dropped below it and only 3,820 rose above it.

**Percentile rules kept their size, not their members.** A percentile is a rank, so the 90th-percentile bucket stays about 10% of scored CVEs. But 9,837 CVEs entered it and 9,944 left it in one day, compared with 25 and 29 on a normal v4 day. If you track "new CVEs in the top decile" as a work queue, June 15 would have looked like a flood.

1,146 CVEs scored on June 14 were missing from the June 15 file and 43 appeared for the first time. By November 5, all but 119 of the missing ones were back in the feed. We did not establish why they were absent that day.

## What happened to KEV-listed CVEs

To see whether v5 demoted known-exploited vulnerabilities, we took the [CISA KEV catalog](https://github.com/cisagov/kev-data) (catalog version 2026.11.04) and kept only the 1,619 entries whose `dateAdded` is on or before June 14, 2026, so the set matches what was known on the switch date. All 1,619 were scored on both days.

| KEV CVEs (added by 2026-06-14) | v4 | v5 |
| --- | --- | --- |
| Median EPSS | 0.704 | 0.535 |
| At or above 0.1 | 1,224 | 1,219 |
| At or above the 90th percentile | 1,323 | 1,366 |

The probability for KEV entries came down along with the rest of the high end. But almost the same number cleared 0.1, and more of them landed in the top decile. KEV-listed CVEs that a 0.1 rule already caught were still caught. A rule set to 0.5 or 0.7 on the assumption that KEV CVEs sit there would have lost many of them, since the median is now about 0.54.

This is one reason KEV should stay a separate input instead of being folded into an EPSS cutoff. Our [CVSS vs EPSS vs KEV comparison](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/) covers why; the [prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/) shows where each signal sits in the patch decision.

## What to re-baseline

These are our recommendations, based on the data above. We have not measured their effect on any team's backlog.

1. **Find every fixed probability cutoff.** SLA rules, ticket triggers, dashboard colours and scanner policies. If one was tuned against v4 data, check how many CVEs it matches today versus before June 15.
2. **Decide what the cutoff is for.** If it sizes a queue ("the top few thousand CVEs"), switch it to a percentile. If it expresses risk ("at least a 10% chance of exploitation in 30 days"), keep the probability, because v5's calibration is meant to make that reading more accurate, but accept that the queue size will move.
3. **Do not compare scores across the switch.** A CVE that went from 0.4 to 0.2 on June 15 did not become less likely to be exploited that day. If you chart EPSS history, mark June 15, 2026 (and the earlier switches on 2022-02-04, 2023-03-07 and 2025-03-17).
4. **Keep KEV as an override.** Do not rely on EPSS to bring KEV entries above a high cutoff.
5. **Store `model_version` next to every score.** Then you can always tell which model produced a score your system acted on.

## A guard for the next model change

There is no API callback when the model changes, but the file tells you. This script compares the header of yesterday's and today's file and exits non-zero on a model change, so a CI job or cron wrapper can stop before ingesting.

```python
"""Stop an EPSS ingest when the model version changes.
Usage: python3 epss_model_guard.py yesterday.csv.gz today.csv.gz"""
import gzip, sys

def header(path):
    with gzip.open(path, "rt") as f:
        first = f.readline().strip()
    if not first.startswith("#"):
        return {"model_version": "pre-v2 (no header)", "score_date": ""}
    return dict(kv.split(":", 1) for kv in first.lstrip("#").split(","))

old, new = header(sys.argv[1]), header(sys.argv[2])
print(f"previous: {old['model_version']} scored {old['score_date']}")
print(f"current:  {new['model_version']} scored {new['score_date']}")
if old["model_version"] != new["model_version"]:
    print("MODEL CHANGE: hold threshold-based alerts and re-baseline before ingesting")
    sys.exit(2)
```

We ran it with Python 3 against files from the repository:

```text
$ python3 epss_model_guard.py epss_scores-2026-06-14.csv.gz epss_scores-2026-06-15.csv.gz
previous: v2025.03.14 scored 2026-06-14T12:55:00Z
current:  v2026.06.15 scored 2026-06-15T12:03:41Z
MODEL CHANGE: hold threshold-based alerts and re-baseline before ingesting
exit=2

$ python3 epss_model_guard.py epss_scores-2026-11-04.csv.gz epss_scores-2026-11-05.csv.gz
previous: v2026.06.15 scored 2026-11-04T12:03:12Z
current:  v2026.06.15 scored 2026-11-05T12:03:04Z
exit=0
```

When the guard trips, run the same comparison we did above (counts at your cutoffs, percentile churn, KEV coverage) before you turn alerts back on. Note the `score_date` format also changed with v4 (from `+0000` offsets to `Z`), so parse it as ISO 8601 instead of matching a fixed string.

## Limits of this article

- We compared one pair of days. Scores on later v5 days have kept moving as new signals arrive, so today's counts differ from June 15.
- The 23% improvement figure and the description of model changes come from Empirical Security. We did not test model accuracy.
- KEV is a list of vulnerabilities known to be exploited, not a ground truth for EPSS's 30-day prediction window, so the KEV table shows coverage, not accuracy.
- We did not find a FIRST page describing v5 in the sources we could reach. If FIRST publishes a different start date or model description, the file headers above are still what your pipeline will see.

## Sources and verification

| Important claim | Source | Status |
| --- | --- | --- |
| Model version and score date of each daily and beta file; all score counts, medians, percentiles and crossings | [empiricalsec/epss_scores](https://github.com/empiricalsec/epss_scores) files for 2026-06-13, 06-14, 06-15, 11-04, 11-05 and `beta_scores/`, computed with Python | Verified (computed) |
| README lists v2, v3 and v4 start dates and no v5 entry | [epss_scores README](https://github.com/empiricalsec/epss_scores) | Verified, Nov 6, 2026 |
| v5 announced May 13, 2026; modeling, calibration, exploit-code classifier and data-feed changes; 23% improvement | [Empirical Security press release](https://lifestyle.kbew98country.com/story/220743/empirical-security-releases-epss-v5/) | Verified (vendor claim) |
| v4 scored 0.514 and v5 0.633 on May 4, 2026 data; random about 0.025 | [EPSS V5 Is Here](https://research.empiricalsecurity.com/research/epss-v5-is-here) | Qualified: metric not fully specified |
| KEV entries added by 2026-06-14 (1,619) and their scores | [cisagov/kev-data](https://github.com/cisagov/kev-data), catalog 2026.11.04, joined to the EPSS files | Verified (computed) |
