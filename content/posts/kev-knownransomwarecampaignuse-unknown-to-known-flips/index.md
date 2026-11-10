+++
title = "KEV knownRansomwareCampaignUse: 114 Unknown-to-Known Flips"
date = 2026-11-10T04:50:00Z
tags = ["cisa kev", "knownransomwarecampaignuse", "ransomware", "vulnerability prioritization", "vulnerability management", "security operations"]
categories = ["security-operations"]
summary = "CISA's KEV catalog marks each entry's ransomware use as Known or Unknown, and it changes that field without an announcement. We replayed every kev-data commit since January 2025: 114 entries flipped from Unknown to Known, none flipped back, and 25 of the 27 Known entries added in 2026 started as Unknown. Here is how often it happens, how long it takes, and a tested script to catch the next flip."
description = "KEV knownRansomwareCampaignUse flips from Unknown to Known silently: 114 times since Jan 2025, none reversed. Lag data, vendors and a script to catch flips."
author = "Craig Leslie"
imageAlt = "A grey industrial control panel with a round ALARM indicator, a RESET button, a key switch and a column of small indicator lamps, one of them lit red"
imageCredit = "Photo by [Jason Leung](https://unsplash.com/photos/a-close-up-of-a-machine-with-buttons-and-buttons-YVSFMhXZAWw) on Unsplash"
takeaways = [
  "knownRansomwareCampaignUse has two values. CISA's schema defines 'Known' as known to have been leveraged in a ransomware campaign and 'Unknown' as CISA lacking confirmation, so Unknown is not 'no'.",
  "Replaying 341 kev-data commits (January 27, 2025 to November 10, 2026), 114 entries changed from Unknown to Known: 59 in 2025 and 55 so far in 2026. No entry changed from Known back to Unknown.",
  "New entries are almost always listed as Unknown: 521 of the 524 entries that first appeared in the window. 50 of those 521 later flipped, with a median of 20 days after dateAdded; 17 flipped within a week.",
  "Flips also hit old entries: the median gap across all 114 is 352 days, and two Win32k CVEs flipped 1,771 days after they were added. Microsoft accounts for 33 of the 114.",
  "A flip does not change dateAdded or dueDate, so a pipeline that only looks for new cveIDs never sees it. Diff the field between catalog versions and route Unknown-to-Known changes into your ransomware-driven SLA."
]

[[faq]]
q = "What does knownRansomwareCampaignUse mean in the CISA KEV catalog?"
a = "It is a string field on every KEV entry. CISA's JSON schema says it is 'Known' if the vulnerability is known to have been leveraged as part of a ransomware campaign, and 'Unknown' if CISA lacks confirmation that it has been used for ransomware. Unknown means unconfirmed, not confirmed absent."

[[faq]]
q = "Does CISA announce when a KEV entry changes to Known ransomware use?"
a = "Not in a way you can rely on. The change shows up as an edited value in the catalog files. In the kev-data history from January 2025 to November 2026 the field changed 114 times, and dateAdded and dueDate stay the same, so a flip is only visible if you compare the field between catalog versions."

[[faq]]
q = "How long after a KEV listing does the ransomware flag usually flip?"
a = "For the 50 entries that were both added and flipped between January 27, 2025 and November 10, 2026, the median was 20 days after dateAdded, 17 flipped within 7 days and 39 within 90 days. Across all 114 flips, including entries added before 2025, the median was 352 days."

[[faq]]
q = "What share of KEV entries are marked Known for ransomware?"
a = "In catalog version 2026.11.09, 361 of 1,773 entries (20.4%) have knownRansomwareCampaignUse set to Known. Among entries added in 2026, 27 are Known, and 25 of those were listed as Unknown first."
+++

CISA's Known Exploited Vulnerabilities (KEV) catalog tags every entry with `knownRansomwareCampaignUse`: `Known` or `Unknown`. That value is not fixed at listing. Replaying the public [kev-data](https://github.com/cisagov/kev-data) Git history from January 27, 2025 to November 10, 2026, we found **114 entries that changed from `Unknown` to `Known`**, and none that went the other way. Of the 27 entries added in 2026 that are now marked `Known`, **25 were listed as `Unknown` first**.

A flip leaves `dateAdded` and `dueDate` untouched, so a pipeline that only watches for new CVE IDs will never notice. If your process gives ransomware-linked KEV entries a shorter SLA, you need to diff this field between catalog versions. This article shows how often it changes, how long it takes, and a tested script that catches it. For where KEV sits in the wider triage flow, see our [vulnerability prioritization workflow from CVE record to ticket](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/).

## What the field means

The KEV JSON schema in kev-data defines the field like this:

> "'Known' if this vulnerability is known to have been leveraged as part of a ransomware campaign; 'Unknown' if CISA lacks confirmation that the vulnerability has been utilized for ransomware"

Two consequences follow:

- **`Unknown` is not "no".** It means CISA has not confirmed ransomware use. Don't treat it as a negative signal or a reason to slow down.
- **`Known` is a one-way upgrade in practice.** In the window we measured, no entry went from `Known` back to `Unknown`.

The field sits alongside `dateAdded`, `dueDate`, `requiredAction` and the rest. Our [field guide to the KEV JSON feed](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/) covers each of them.

## How we measured

- **Data:** every commit to `known_exploited_vulnerabilities.json` in [cisagov/kev-data](https://github.com/cisagov/kev-data), from the first commit (2025-01-27) to the commit for catalog version 2026.11.09 (pushed 2026-11-10 03:13 UTC). That's 341 commits. One commit, from 2025-02-25, did not parse as JSON and was skipped; any change in it shows up in the next commit.
- **Flip:** a `cveID` whose `knownRansomwareCampaignUse` value differs from its value in the previous parsed commit.
- **Flip date:** the Git commit timestamp. It records when the change reached the repository, not when CISA's analysts decided it, so treat it as an upper bound with day-level precision.
- **Lag:** flip date minus the entry's `dateAdded`, in whole days.

The repository only starts in January 2025, so flips before that date are invisible here. The 1,252 entries in the first commit form the baseline: 245 were already `Known`.

## How often the flag flips

| Period | Unknown → Known | Known → Unknown |
|---|---|---|
| 2025 (from Jan 27) | 59 | 0 |
| 2026 (to Nov 10) | 55 | 0 |
| **Total** | **114** | **0** |

The 2025 total matches the 59 flips GreyNoise's Glenn Thorpe counted for 2025, as [reported by The Register](https://www.theregister.com/2026/02/03/greynoise_cisa_ransomware_gripe/) in February 2026. Thorpe described the change as "no alert, no announcement" and "Just a field change in a JSON file". Our count comes from an independent replay of the same public history.

Flips come in batches rather than a steady trickle. The largest single days were 2025-05-12 (14 flips) and 2026-08-14 (10). The most recent flip in the data was CVE-2026-63077 (JetBrains TeamCity) on 2026-09-23, 48 days before this article. A quiet spell is normal and does not mean the field has stopped changing.

By vendor, Microsoft accounts for 33 of the 114 flips, followed by Ivanti (6), Fortinet (5), SonicWall (5) and Oracle (5).

## New entries almost always start as Unknown

Of the 524 entries that first appeared in the catalog during the window, **521 were listed as `Unknown`** and only 3 as `Known`. Ransomware attribution usually arrives after exploitation evidence, so the first version of an entry rarely carries it.

For the 50 entries that were both added and flipped inside the window:

| Lag from dateAdded to flip | Entries | Cumulative |
|---|---|---|
| 7 days or less | 17 | 17 |
| 8–30 days | 12 | 29 |
| 31–90 days | 10 | 39 |
| More than 90 days | 11 | 50 |

The median lag is 20 days and the longest is 554 days. One entry, CVE-2025-61882 (Oracle E-Business Suite), shows a lag of −1: it appeared in the repository on 2025-10-06 with a `dateAdded` of 2025-10-07 and flipped the same day.

Seen from the other side: of the 289 entries in the current catalog with a 2026 `dateAdded`, 27 are `Known`, and 25 of those got there through a flip. If you only read the field once, at listing, you would have missed almost all of this year's ransomware signal.

## Old entries flip too

64 of the 114 flips were on entries that were already in the catalog when the repository started. Across all 114, the median lag is **352 days**, and the longest are CVE-2016-7255 and CVE-2019-0859 (both Microsoft Win32k, added 2021-11-03), which flipped on 2026-09-09, 1,771 days later.

For triage, this means an entry you closed or risk-accepted years ago can pick up a ransomware link today. That's a reason to reopen it, especially on systems that never got the fix. The same logic applies to KEV backfills of old CVEs, covered in our [KEV time-to-listing analysis](/posts/kev-time-to-listing-cve-published-to-dateadded-days-by-vendor/).

## Detect flips between two catalog versions

The script below compares two KEV JSON snapshots and prints every entry whose `knownRansomwareCampaignUse` changed. It uses only the Python standard library. We ran it with Python 3 on the kev-data snapshots for catalog versions 2026.08.11 and 2026.08.14. The output (abbreviated) matches the 2026-08-14 batch in the full replay:

```python
#!/usr/bin/env python3
"""Report KEV entries whose knownRansomwareCampaignUse changed between two snapshots.
Usage: python3 kev_ransomware_flips.py OLD.json NEW.json
"""
import json, sys

def load(path):
    with open(path) as f:
        doc = json.load(f)
    return doc["catalogVersion"], {v["cveID"]: v for v in doc["vulnerabilities"]}

old_ver, old = load(sys.argv[1])
new_ver, new = load(sys.argv[2])
print(f"# {old_ver} -> {new_ver}")
for cve, v in sorted(new.items()):
    before = old.get(cve, {}).get("knownRansomwareCampaignUse")
    after = v["knownRansomwareCampaignUse"]
    if before is not None and before != after:
        print(f"{cve}\t{before} -> {after}\tadded {v['dateAdded']}\t"
              f"{v['vendorProject'].strip()} {v['product'].strip()}")
```

```text
# 2026.08.11 -> 2026.08.14
CVE-2016-0189	Unknown -> Known	added 2022-03-28	Microsoft Internet Explorer
CVE-2018-0802	Unknown -> Known	added 2021-11-03	Microsoft Office
CVE-2019-5591	Unknown -> Known	added 2021-11-03	Fortinet FortiOS
CVE-2021-4034	Unknown -> Known	added 2022-06-27	Red Hat Polkit
CVE-2025-60710	Unknown -> Known	added 2026-04-13	Microsoft Windows
...
```

To run it in production, keep the last catalog you processed, and when a new `catalogVersion` arrives, run the diff before you overwrite the old file. To backfill history, clone kev-data and feed consecutive commits to the same function (`git log --reverse --format=%H -- known_exploited_vulnerabilities.json` lists them; `git show <commit>:known_exploited_vulnerabilities.json` extracts each one).

The script skips entries that are new in the second snapshot, because their listing value is not a change. Handle new entries in your normal KEV ingest.

## What to do with a flip

1. **Treat Unknown → Known as a new event.** Open or re-prioritize tickets for every asset that still carries the CVE, even if the KEV due date has already passed or the finding was risk-accepted.
2. **Don't read Unknown as low risk.** Of this year's `Known` entries, 25 of 27 started as `Unknown`. A ransomware-only fast lane that ignores everything else will lag the data by weeks.
3. **Record the flip date yourself.** The catalog keeps no history of the field, so your ticket or data store is the only place that will remember when the link appeared.
4. **Combine it with other signals, don't substitute it for them.** EPSS scores for newly listed KEV CVEs often start low (see our [analysis of EPSS for KEV entries](/posts/epss-scores-for-kev-cves-low-after-listing-threshold-audit/)), so a flip is a useful second trigger rather than the only one.

## Limits of this article

- The data covers January 27, 2025 to November 10, 2026. Earlier flips are not visible in the kev-data repository.
- Flip dates are Git commit times, not CISA decision times.
- CISA does not publish the evidence behind a `Known` value, so this article measures when the label changed, not why.
- One entry that flipped, CVE-2025-6264 (Rapid7 Velociraptor), has since been removed from the catalog. It is counted in the 114 but not in the 361 current `Known` entries.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Definition of Known and Unknown | [KEV JSON schema, cisagov/kev-data](https://github.com/cisagov/kev-data/blob/develop/known_exploited_vulnerabilities_schema.json) | Verified |
| 114 Unknown → Known flips, 0 reversals; lag and vendor figures | Replay of [cisagov/kev-data](https://github.com/cisagov/kev-data) commit history, 2025-01-27 to 2026-11-10 | Verified (our computation) |
| 361 of 1,773 entries Known (20.4%) | [KEV JSON](https://github.com/cisagov/kev-data), catalogVersion 2026.11.09 | Verified |
| GreyNoise counted 59 flips in 2025; "no alert, no announcement" | [The Register, Feb 3, 2026](https://www.theregister.com/2026/02/03/greynoise_cisa_ransomware_gripe/) | Qualified (press report of third-party research; matches our count) |
