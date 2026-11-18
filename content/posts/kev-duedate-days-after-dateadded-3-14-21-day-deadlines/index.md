+++
title = "KEV dueDate: 3, 14 or 21 Days After dateAdded, 2021-2026"
date = 2026-11-18T04:58:00Z
tags = ["vulnerability management", "kev", "cisa", "bod 26-04", "bod 22-01", "forensic triage", "kev-data", "sla"]
categories = ["security-operations"]
summary = "We measured dueDate minus dateAdded for all 1,782 entries in CISA's KEV catalog (version 2026.11.17) and replayed the cisagov/kev-data history to find every dueDate CISA edited after publication. The default gap was 14 days in 2021, 21 days from March 2022, and since mid-2026 is 3 or 14 days. Every forensicTriage Yes entry is due in 3 days, but 23 No entries are too."
description = "KEV dueDate is now 3 or 14 days after dateAdded; it was 21 days from 2022 to early 2026. Counts by year, forensicTriage link, edited due dates, and a script."
author = "John Marshall"
imageAlt = "A wall calendar page for December 2020 in four languages, with week numbers down the left and weekend dates in grey and red"
imageCredit = "Photo by [Waldemar Brandt](https://unsplash.com/photos/bY9bfWjLtiU) on Unsplash"
takeaways = [
  "In KEV catalog version 2026.11.17 (1,782 entries), the gap between dateAdded and dueDate is 3 or 14 days for every entry added since June 10, 2026: 128 entries at 3 days and 37 at 14 days.",
  "From March 2022 to early March 2026 the catalog's usual gap was 21 days, not the two weeks BOD 22-01 set as its default. 2021 entries used 14 days for newer CVEs and about six months (181 or 182 days) for CVE IDs from before 2021.",
  "All 105 entries added since June 10, 2026 with forensicTriage Yes are due in 3 days. 23 entries with forensicTriage No are also due in 3 days, so the field does not tell you the deadline: read dueDate.",
  "The CISA-ADP SSVC Technical Impact value in the CVE record does not predict dueDate either: 19 entries with Technical Impact total were given 14 days.",
  "CISA edits published due dates. The kev-data history since January 2025 shows 23 dueDate changes, including shortened deadlines; one (CVE-2022-0995) was moved to a date that had already passed. Re-read dueDate on every sync instead of caching it."
]

[[faq]]
q = "How many days does CISA give to fix a KEV vulnerability?"
a = "The catalog's dueDate sets it per entry. In KEV catalog version 2026.11.17, every entry added since June 10, 2026 is due either 3 or 14 calendar days after dateAdded. Between March 2022 and early March 2026 the usual gap was 21 days. For federal civilian agencies the binding timeline comes from BOD 26-04, which can differ per asset; the catalog shows one date per CVE."

[[faq]]
q = "Does forensicTriage Yes mean a 3-day due date?"
a = "In the current catalog, yes: all 105 entries added since June 10, 2026 with forensicTriage Yes have a dueDate 3 days after dateAdded. The reverse is not true. 23 entries with forensicTriage No also have a 3-day gap, so use dueDate rather than inferring the deadline from forensicTriage."

[[faq]]
q = "Can a KEV due date change after the entry is published?"
a = "Yes. Replaying every catalog version in the cisagov/kev-data repository since January 27, 2025 shows 23 dueDate changes. Some fixed data errors, some shortened a deadline (for example CVE-2025-0108 from April 8 to March 11, 2025) and one lengthened it (CVE-2026-86950, when its forensicTriage value changed from Yes to No)."

[[faq]]
q = "Are KEV due dates business days?"
a = "No. The gap is a whole number of calendar days. Of the 165 entries added since June 10, 2026, 49 have a dueDate that falls on a Saturday or Sunday, so a ticketing SLA that counts business days will run past the catalog date."
+++

**Short answer:** the KEV catalog's `dueDate` is a calendar date, set per entry, and the gap to `dateAdded` has changed three times. In the current catalog (version 2026.11.17, 1,782 entries) every entry added since June 10, 2026 is due **3 or 14 days** after it was added. Before that, from March 2022 until early March 2026, the usual gap was **21 days**. If you build SLAs from KEV, read `dueDate` from every catalog sync rather than hard-coding a number of days, because CISA also edits due dates after publishing them.

This article measures the field. For what each KEV field means, see our [KEV JSON feed field guide](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/). For what BOD 26-04 requires of federal agencies, see [CISA BOD 26-04 explained](/posts/cisa-bod-26-04-explained-kev-deadlines-forensic-triage-and-what-private-teams-can-borrow/). For where KEV fits in a patch decision, see the [vulnerability prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/).

## What the field is

The catalog schema in [cisagov/kev-data](https://github.com/cisagov/kev-data) describes `dueDate` as "The date the required action is due in the format YYYY-MM-DD". It is required on every entry. A second field, `forensicTriage`, is described as "'Yes' if this vulnerability requires forensic triage per BOD 26-04; 'No' if forensic triage is not required per BOD 26-04". That field first appears in the catalog published on September 1, 2026, when it was filled in for all entries then listed (38 Yes, 1,649 No).

Neither field states the number of days. To get it, subtract `dateAdded` from `dueDate`.

## Gap by year added

We computed `dueDate − dateAdded` in days for all 1,782 entries in catalog version 2026.11.17 (released 2026-11-17T17:53Z). The three most common gaps per year:

| Year added | Entries | Most common gaps (days: entries) |
|---|---|---|
| 2021 | 311 | 181: 189 · 14: 111 · 182: 11 |
| 2022 | 555 | 21: 403 · 14: 88 · 181: 49 |
| 2023 | 187 | 21: 177 · 4: 7 · 7: 1 |
| 2024 | 186 | 21: 175 · 7: 7 · 12: 2 |
| 2025 | 245 | 21: 226 · 7: 12 · 1: 6 |
| 2026 | 298 | 3: 159 · 14: 92 · 21: 44 |

Three regimes are visible:

1. **2021 to early 2022: two weeks or six months.** [BOD 22-01](https://www.cisa.gov/binding-operational-directive-22-01) told agencies to remediate "within 6 months for vulnerabilities with a Common Vulnerabilities and Exposures (CVE) ID assigned prior to 2021" and "within two weeks for all other vulnerabilities", and added: "These default timelines may be adjusted in the case of grave risk to the Federal Enterprise." The 2021 data follows that split: 179 of the 2021 entries with pre-2021 CVE IDs have a 181-day gap and 11 have 182; 110 entries with 2021 CVE IDs have 14 days.
2. **March 2022 to March 2026: 21 days.** The first 21-day entry was added on 2022-03-03 and the last on 2026-03-05. The last six-month entry was added on 2022-03-07 and the last 2022 entry with 14 days on 2022-06-08. We did not find a CISA statement explaining the switch from two weeks to 21 days, so we report it only as what the data shows.
3. **2026: 3 and 14 days.** The first 3-day entry was added on 2026-01-27 (Fortinet, CVE-2026-24858), months before BOD 26-04 was published on June 10, 2026. The first 14-day entry in this regime was added on 2026-03-09. Since June 10, 2026 no other gap appears.

Short one-off gaps exist outside those patterns, for example six 1-day entries added in 2025 and two 2-day Cisco entries (CVE-2022-20775 and CVE-2026-20127) added on 2026-02-25.

## Since BOD 26-04: 3 or 14 days, and what forensicTriage tells you

For the 165 entries added on or after June 10, 2026:

| Gap | forensicTriage | Entries |
|---|---|---|
| 3 days | Yes | 105 |
| 3 days | No | 23 |
| 14 days | No | 37 |

Every Yes entry is due in 3 days. But a No does not mean 14 days: 23 No entries are due in 3 days too, including CVE-2015-5477 (BIND) from the October 8, 2026 batch our BOD 26-04 article examined.

We also joined these 165 entries to their CVE records in [CVEProject/cvelistV5](https://github.com/CVEProject/cvelistV5) and read the CISA-ADP SSVC "Technical Impact" option:

| Gap | forensicTriage | Technical Impact total | Technical Impact partial |
|---|---|---|---|
| 3 days | Yes | 104 | 1 |
| 3 days | No | 13 | 10 |
| 14 days | No | 19 | 18 |

Under BOD 26-04 the agency timeline depends on KEV status, public exposure, automatability and technical impact for the specific asset, and the catalog publishes one date per CVE. Because 19 "total" entries got 14 days and 10 "partial" entries got 3, you cannot rebuild the catalog's `dueDate` from the SSVC values in the CVE record. Treat `dueDate` as CISA's published decision for that CVE and copy it as is. (The SSVC fields themselves are explained in [our Vulnrichment SSVC guide](/posts/cisa-vulnrichment-how-to-read-ssvc-values-in-a-cve-record-and-turn-them-into-a-patch-decision/).)

### Weekends count

The gap is in calendar days. Of the 165 due dates since June 10, 2026, 26 fall on a Saturday and 23 on a Sunday, and 44 on a Friday. An internal SLA of "3 business days from KEV listing" will often land after the catalog date.

## CISA edits due dates after publishing

The [kev-data](https://github.com/cisagov/kev-data) repository keeps every catalog version since January 27, 2025 (345 commits to the JSON file when we checked). Replaying them and comparing each entry's `dateAdded`, `dueDate` and `forensicTriage` between consecutive versions found these changes, apart from the one-time September 1, 2026 backfill of `forensicTriage`:

| Catalog version | CVE | Change |
|---|---|---|
| 2025.02.18 | CVE-2025-0108 (PAN-OS) | dueDate 2025-04-08 → 2025-03-11 |
| 2025.04.29 | CVE-2025-3928 (Commvault) | dueDate 2025-05-17 → 2025-05-19 |
| 2025.10.06 | CVE-2025-61882 | dateAdded and dueDate each moved one day earlier |
| 2025.10.15 | CVE-2025-54253 | dateAdded and dueDate each moved one day earlier |
| 2025.12.09 | CVE-2025-55182 (React Server Components) | dueDate 2025-12-26 → 2025-12-12 |
| 2025.12.17 | 15 entries added 2021-11-03 | dueDate corrected to 2022-05-03 (previously earlier than dateAdded) |
| 2026.05.20 | CVE-2010-0249 (Internet Explorer) | dateAdded 2026-06-03 → 2026-05-20, dueDate unchanged |
| 2026.08.17 | CVE-2025-62593 | dateAdded and dueDate each moved one day earlier |
| 2026.10.08 | CVE-2026-86950 (Apple) | forensicTriage Yes → No, dueDate 2026-10-02 → 2026-10-13 |
| 2026.10.08 | CVE-2022-0995 (Linux kernel) | forensicTriage No → Yes, dueDate 2026-09-09 → 2026-08-29 |
| 2026.10.08 | CVE-2026-88779 (NetScaler), CVE-2023-22894 (Strapi) | forensicTriage flipped, dueDate unchanged |
| 2026.10.13 | CVE-2026-12569 (PTC Windchill) | forensicTriage No → Yes, dueDate unchanged |

That is 23 `dueDate` changes in total. Two cases matter most for automation:

- **Shortened deadlines.** CVE-2025-0108 lost four weeks and CVE-2025-55182 lost two. A ticket created from the first catalog version would show the wrong date.
- **Retroactive deadlines.** CVE-2022-0995's new dueDate (2026-08-29) was published on October 8, 2026, so the entry went straight to overdue. If your pipeline only reads new entries, it never sees this.

Our [KEV time-to-listing analysis](/posts/kev-time-to-listing-cve-published-to-dateadded-days-by-vendor/) covers the other end of the timeline: how long CVEs wait before `dateAdded`.

## Run it yourself

Tested with Python 3 (standard library only) against `known_exploited_vulnerabilities.json` downloaded from `raw.githubusercontent.com/cisagov/kev-data/main/` on November 18, 2026.

```python
import json, sys, collections
from datetime import date

kev = json.load(open(sys.argv[1]))
print("catalogVersion", kev["catalogVersion"], "count", kev["count"])

def days(v):
    return (date.fromisoformat(v["dueDate"]) - date.fromisoformat(v["dateAdded"])).days

by_year = collections.defaultdict(collections.Counter)
for v in kev["vulnerabilities"]:
    by_year[v["dateAdded"][:4]][days(v)] += 1
for year in sorted(by_year):
    c = by_year[year]
    print(year, sum(c.values()), c.most_common(4))

# Entries added from a given date: interval vs forensicTriage
since = sys.argv[2] if len(sys.argv) > 2 else "2026-06-10"
pairs = collections.Counter(
    (days(v), v.get("forensicTriage"))
    for v in kev["vulnerabilities"] if v["dateAdded"] >= since)
print("since", since, sorted(pairs.items()))

# Open items: due today or later, and those due on a weekend
today = date.today()
for v in kev["vulnerabilities"]:
    due = date.fromisoformat(v["dueDate"])
    if due >= today:
        flag = " (weekend)" if due.weekday() >= 5 else ""
        print(v["cveID"], v["dateAdded"], v["dueDate"], days(v), v.get("forensicTriage"), flag)
```

Run it as `python3 kev_due.py known_exploited_vulnerabilities.json`. On November 18, 2026 it printed seven entries still open, all with 14-day gaps, the latest CVE-2026-115731 due 2026-12-01.

To find edited due dates, clone `cisagov/kev-data` (about 3 MB), list commits with `git log --reverse -- known_exploited_vulnerabilities.json`, load each version with `git show <commit>:known_exploited_vulnerabilities.json`, and compare each CVE's `(dateAdded, dueDate, forensicTriage)` with the previous version.

## What to do with this

- **Copy `dueDate` into the ticket and update it on every sync.** Key the comparison on `cveID` across the whole catalog, not only on entries added since your last run.
- **Alert on changes, not just additions.** A shortened or past `dueDate` on an existing entry deserves the same page as a new entry.
- **Do not derive the deadline** from `forensicTriage`, SSVC Technical Impact or CVSS. In the current data none of them reproduces the catalog date.
- **Count calendar days.** Map the catalog date to your SLA directly instead of adding business days.
- **If you are not a federal agency,** the catalog date is a strong urgency signal, not your legal deadline. Our [CVSS vs EPSS vs KEV comparison](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/) covers how to weigh it.

## Limits of this article

- Counts come from catalog version 2026.11.17 and the kev-data history from January 27, 2025 onward. Edits made before that date are not visible in the repository.
- `dueDate` in the catalog is one date per CVE. Federal agencies' asset-level timelines under BOD 26-04 depend on exposure and other decision points the catalog does not carry; we did not re-verify the directive's Table 1 for this article.
- We describe what the data shows about the 21-day period and the 2026 change; we found no CISA statement explaining either.
- SSVC values were read from cvelistV5 records on November 18, 2026; CISA-ADP can update them after a CVE is added to KEV.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| dueDate and forensicTriage field descriptions | [kev-data schema](https://github.com/cisagov/kev-data/blob/main/known_exploited_vulnerabilities_schema.json) | Verified |
| Gap counts by year and since June 10, 2026 | [KEV catalog JSON, version 2026.11.17](https://github.com/cisagov/kev-data) (script above) | Verified |
| forensicTriage first published 2026-09-01 (38 Yes, 1,649 No) | kev-data git history | Verified |
| BOD 22-01 six-month / two-week defaults and grave-risk adjustment | [CISA BOD 22-01](https://www.cisa.gov/binding-operational-directive-22-01) | Verified |
| SSVC Technical Impact per entry | [CVEProject/cvelistV5](https://github.com/CVEProject/cvelistV5) CISA-ADP containers | Verified |
| 23 dueDate edits since January 2025 | kev-data git history replay | Verified |
| BOD 26-04 publication date June 10, 2026 | [CISA BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk), via our [earlier article](/posts/cisa-bod-26-04-explained-kev-deadlines-forensic-triage-and-what-private-teams-can-borrow/) | Qualified (page not re-fetched today) |
