+++
title = "CISA KEV JSON Feed: What Each Field Means and How to Match It Against a Scanner Export"
date = 2026-10-15T06:05:00Z
tags = ["vulnerability management", "tools"]
categories = ["security-operations"]
summary = "CISA publishes the Known Exploited Vulnerabilities catalog as a JSON file. Here is every field, what the schema does and does not promise, how due dates and the forensic triage flag behave in the data, and a tested 30-line Python script that joins the feed to a scanner CSV."
description = "How to read the CISA KEV JSON feed: field-by-field meaning, what dueDate, knownRansomwareCampaignUse and forensicTriage do and do not tell you, data pitfalls, and a tested Python script that matches KEV against a vulnerability scanner export."
author = "FirewallSync Editorial"
imageAlt = "A computer screen photographed at an angle, showing a blue cohort grid labelled user activity by cohort and line graphs with 68K, 16K and 1.7K figures"
imageCredit = "Photo by [1981 Digital](https://unsplash.com/photos/yqaskj8lQBE) on Unsplash"
takeaways = [
  "CISA's Known Exploited Vulnerabilities (KEV) catalog is available as JSON at a stable URL. The copy we downloaded on October 15, 2026 was catalog version 2026.10.14, released 2026-10-14T19:27:28Z, and its count field (1,745) matched the number of entries and the number of unique CVE IDs.",
  "Each entry has 12 fields. The schema says knownRansomwareCampaignUse is \"Unknown\" when CISA lacks confirmation, so \"Unknown\" means unconfirmed, not \"not used\". In our copy 361 entries are \"Known\" and 1,384 are \"Unknown\".",
  "dueDate is not a constant interval. Among the 128 entries added on or after June 10, 2026, the gap from dateAdded to dueDate was 3 days for 105 entries and 14 days for 23. Entries added in 2025 mostly show 21 days (226 of 245).",
  "forensicTriage is \"Yes\" on 84 entries, all of them added between June 25 and October 14, 2026, and every one of them has a three-day due date. Three-day due dates also appear on 21 entries marked \"No\".",
  "Matching is a join on cveID. Normalize case and whitespace, treat a CVE that is absent from KEV as \"no CISA exploitation record\" rather than \"safe\", and re-pull the file daily because CISA updates it on weekdays."
]

[[faq]]
q = "Where is the CISA KEV JSON file?"
a = "CISA's KEV page links the JSON feed, which we downloaded from https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json on October 15, 2026. CISA also mirrors the data, a CSV and the JSON schema in the cisagov/kev-data repository on GitHub."
[[faq]]
q = "How often is the KEV JSON updated?"
a = "The cisagov/kev-data README says the catalog is updated whenever KEV changes, which typically happens on weekdays during US Eastern business hours when there are new or updated entries. The CISA catalog page itself does not state an update frequency."
[[faq]]
q = "Does knownRansomwareCampaignUse = Unknown mean a vulnerability is not used by ransomware?"
a = "No. The schema defines Unknown as CISA lacking confirmation that the vulnerability has been used for ransomware. It can change to Known later."
[[faq]]
q = "Is the dueDate field a deadline for my company?"
a = "Not by itself. The date is the due date for the required action in the catalog; CISA's BOD 26-04 directive that the entries cite binds U.S. federal civilian agencies. Other organizations can use the date as a reference point for how urgently CISA treats the entry, then set their own policy."
+++

The Known Exploited Vulnerabilities (KEV) catalog is CISA's list of vulnerabilities with evidence of exploitation in the wild. The catalog page is built for people. Teams that want to automate, for example flagging scanner findings that are in KEV, need the machine-readable JSON file and an accurate idea of what each field promises. This guide covers the file's structure, the traps we found in the data, and a script that joins it to a scanner export.

**Scope.** This is research-based analysis plus one script we ran. On October 15, 2026 we downloaded the live JSON file, read CISA's KEV page, the published JSON schema and the kev-data repository README, and ran the script below against a five-row test CSV we wrote. All counts below are from that single download and will change as CISA edits the catalog. For what KEV deadlines mean for U.S. federal agencies, see our explainer on [CISA BOD 26-04](/posts/cisa-bod-26-04-explained-kev-deadlines-forensic-triage-and-what-private-teams-can-borrow/); for when to rank KEV above scores, see [CVSS vs EPSS vs KEV](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/).

## Where to get the file and how fresh it is

CISA's [KEV catalog page](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) offers CSV and JSON downloads and a JSON schema. The JSON URL we used:

```
https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json
```

It downloaded without authentication or an API key using Python's standard library and `curl`. The file is about 1.8 MB.

The [cisagov/kev-data repository](https://github.com/cisagov/kev-data) holds the same data, a CSV and the current [schema](https://github.com/cisagov/kev-data/blob/develop/known_exploited_vulnerabilities_schema.json), and its git history is the only practical change log: the README says the KEV "has no inline file revision history or log that's easily accessible after the fact." Per that README the repository updates within minutes of cisa.gov, and updates "typically happen weekdays during normal US Eastern business hours when there are new or updated KEV entries."

The top of the file carries four metadata fields. In our download:

| Field | Value on October 15, 2026 | Meaning (per schema) |
|---|---|---|
| `catalogVersion` | 2026.10.14 | Version string of the catalog |
| `dateReleased` | 2026-10-14T19:27:28.0105Z | Release time, UTC |
| `count` | 1745 | Total number of entries |
| `vulnerabilities` | array of 1,745 objects | The entries |

We checked that `count`, the array length and the number of distinct `cveID` values were all 1,745. That is worth asserting in your own pipeline: if they disagree, the download is probably truncated.

## The entry fields, one by one

Every entry has 12 fields in our copy (`cveID`, `vendorProject`, `product`, `vulnerabilityName`, `dateAdded`, `shortDescription`, `requiredAction`, `dueDate`, `knownRansomwareCampaignUse`, `forensicTriage`, `notes`, `cwes`). The table gives CISA's schema definition and, where we measured something, what the data shows.

| Field | Schema definition (paraphrased) | What to watch for |
|---|---|---|
| `cveID` | CVE ID, `CVE-YYYY-NNNN`; the number part can have more than four digits | Match on this. Scanners may emit lowercase or padded values, so normalize |
| `vendorProject`, `product` | Vendor/project and product names | Free text, not a CPE (Common Platform Enumeration, the standard product naming scheme). `product` can be "Multiple Products". Do not match on these |
| `vulnerabilityName` | Name of the vulnerability | Display only |
| `dateAdded` | Date added to the catalog, `YYYY-MM-DD` | The date CISA added it, not the disclosure or first-exploitation date |
| `shortDescription` | Short description | Display only |
| `requiredAction` | Required action to address it | Text varies by entry; recent entries refer to BOD 26-04 |
| `dueDate` | Date the required action is due, `YYYY-MM-DD` | See next section |
| `knownRansomwareCampaignUse` | "Known" if leveraged in a ransomware campaign; "Unknown" if CISA lacks confirmation | 361 Known, 1,384 Unknown in our copy |
| `forensicTriage` | "Yes" if forensic triage is required per BOD 26-04, "No" if not | 84 Yes, 1,661 No |
| `notes` | Additional notes | Free text; see below |
| `cwes` | Array of CWE (Common Weakness Enumeration) IDs, `CWE-NNNN` | Can be empty: 175 entries have none |

Source for the definitions: CISA's [published schema](https://github.com/cisagov/kev-data/blob/develop/known_exploited_vulnerabilities_schema.json). The counts are our own tallies of the downloaded file.

### `notes` is not a single URL

Many entries put several links in `notes`, separated by semicolons and sometimes by empty segments. In our copy 963 of 1,745 notes contain a semicolon and 973 contain more than one `http`. Example from the entry added on October 14, 2026 for Ahsay AhsayCBS (CVE-2026-105134): the field holds a vendor announcement, two CISA BOD 26-04 links and an NVD link in one string. If you want links, split on `;`, trim, and drop empties.

### Reading `knownRansomwareCampaignUse` correctly

The two values are not symmetric. "Known" is a positive confirmation; "Unknown" is the absence of one. Treating "Unknown" as "no ransomware risk" is a misreading the schema itself rules out. The count of "Known" entries by year added is also not a measure of ransomware activity that year, since the flag can be updated after the entry is added; we did not test how often that happens.

## `dueDate` is not a fixed interval

If you assume "due date = added + N days" you will be wrong for much of the file. We computed `dueDate − dateAdded` in calendar days for every entry:

| Year added | Entries | Most common gap |
|---|---|---|
| 2021 | 311 | 181 days (189 entries), 14 days (111) |
| 2022 | 555 | 21 days (403) |
| 2023 | 187 | 21 days (177) |
| 2024 | 186 | 21 days (175) |
| 2025 | 245 | 21 days (226) |
| 2026 | 261 | 3 days (136), 14 days (78), 21 days (44) |

Across the whole file, 238 entries have a gap of exactly 181 days. We did not investigate why, and the data does not say.

The 2026 change lines up with BOD 26-04, CISA's directive dated June 10, 2026. Restricting to the 128 entries added on or after June 10, 2026 (the directive's date, our cut-off):

| `forensicTriage` | Gap to `dueDate` | Entries |
|---|---|---|
| Yes | 3 days | 84 |
| No | 3 days | 21 |
| No | 14 days | 23 |

Three observations, all about this data and not about the directive's text:

1. Every "Yes" entry in the file falls in this group, and the earliest has `dateAdded` of 2026-06-25.
2. Every "Yes" entry has a three-day gap. The reverse is not true: 21 "No" entries also have three days.
3. So `forensicTriage` and a short deadline are separate signals. A tool that infers one from the other will be wrong for those 21 entries.

Whose deadline is it? The entries cite BOD 26-04, which applies to U.S. Federal Civilian Executive Branch agencies. For any other organization the date is context, not an obligation. The directive also sets timelines from asset exposure and other factors that the feed cannot represent; our [BOD 26-04 explainer](/posts/cisa-bod-26-04-explained-kev-deadlines-forensic-triage-and-what-private-teams-can-borrow/) covers that.

## A tested join against a scanner export

The script below reads a CSV with columns `host,cve,severity`, downloads the feed, and prints each finding with the KEV fields appended, KEV hits first, ordered by `dueDate`. It uses only the Python standard library.

```python
#!/usr/bin/env python3
"""Join a scanner CSV (columns: host,cve,severity) to the CISA KEV JSON feed."""
import csv, json, sys, urllib.request

URL = "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json"

with urllib.request.urlopen(URL, timeout=30) as r:
    feed = json.load(r)
kev = {v["cveID"].upper(): v for v in feed["vulnerabilities"]}
print(f"catalog {feed['catalogVersion']}, released {feed['dateReleased']}, "
      f"count field {feed['count']}, entries {len(kev)}", file=sys.stderr)

rows = []
with open(sys.argv[1], newline="") as f:
    for row in csv.DictReader(f):
        cve = row["cve"].strip().upper()
        hit = kev.get(cve)
        rows.append({
            **row, "cve": cve, "in_kev": bool(hit),
            "dateAdded": hit["dateAdded"] if hit else "",
            "dueDate": hit["dueDate"] if hit else "",
            "ransomware": hit["knownRansomwareCampaignUse"] if hit else "",
            "forensicTriage": hit["forensicTriage"] if hit else "",
        })

rows.sort(key=lambda r: (not r["in_kev"], r["dueDate"] or "9999"))
w = csv.DictWriter(sys.stdout, fieldnames=list(rows[0]))
w.writeheader(); w.writerows(rows)
```

We ran it on October 15, 2026 against this five-row file. Row 4 has a lowercase ID with a trailing space, and the last CVE ID is invented to represent a finding that is not in KEV:

```
host,cve,severity
web-01,CVE-2026-105134,High
web-01,CVE-2020-29583,Critical
db-02,CVE-2026-105134,High
db-02,cve-2021-44228 ,Critical
db-02,CVE-2099-0001,Low
```

Output (the `catalog ... entries` line goes to stderr):

```
catalog 2026.10.14, released 2026-10-14T19:27:28.0105Z, count field 1745, entries 1745
host,cve,severity,in_kev,dateAdded,dueDate,ransomware,forensicTriage
db-02,CVE-2021-44228,Critical,True,2021-12-10,2021-12-24,Known,No
web-01,CVE-2020-29583,Critical,True,2021-11-03,2022-05-03,Unknown,No
web-01,CVE-2026-105134,High,True,2026-10-14,2026-10-17,Unknown,Yes
db-02,CVE-2026-105134,High,True,2026-10-14,2026-10-17,Unknown,Yes
db-02,CVE-2099-0001,Low,False,,,,
```

Read this carefully, because it shows the pitfalls above:

- **Sorting by `dueDate` is not the same as sorting by urgency.** The 2021 and 2022 entries sort first because their due dates are in the past, yet the only "Yes" triage flags are on the entry added the day before we ran this. Sort by what you actually want, for example `forensicTriage` first, then `dateAdded` descending.
- **Normalization worked.** The lowercase, space-padded `cve-2021-44228 ` matched Log4Shell (Apache Log4j2), which is in KEV with `dateAdded` 2021-12-10.
- **A miss is not a clean bill of health.** `CVE-2099-0001` is simply absent from KEV. KEV only lists vulnerabilities CISA has evidence were exploited; it says nothing about the rest.
- **The script does not match products.** If your scanner reports a CVE on a product version that a vendor has already patched or backported, the join still flags it. Confirm against the vendor advisory.

### Making it production-ready

These are our suggestions; we did not build or test them beyond the script above.

1. **Fail loudly on a bad download.** Assert `len(vulnerabilities) == count` and that the file parses before replacing yesterday's copy.
2. **Pull daily on weekdays** (the kev-data README says updates cluster in US Eastern business hours) and keep each day's file, or use the kev-data git history, so you can diff what was added.
3. **Detect changes beyond additions.** The README mentions "new or updated" entries, so compare the whole entry, not just the set of CVE IDs.
4. **Keep the flags separate in your ticket system.** Store `dateAdded`, `dueDate`, `forensicTriage` and `knownRansomwareCampaignUse` as distinct fields rather than a single priority, for the reasons in the table above.
5. **Pair with other data.** KEV answers "has this been exploited?" Add the exploitability details in [CISA Vulnrichment SSVC values](/posts/cisa-vulnrichment-how-to-read-ssvc-values-in-a-cve-record-and-turn-them-into-a-patch-decision/) and your own exposure data, and watch the [backlog dynamics](/posts/the-vulnerability-backlog-that-never-shrinks/) so KEV items do not get buried.

## Limits of this article

We tested the script only against a five-row file, not a real scanner export, and only on Python 3 with the standard library. Counts come from one download on October 15, 2026. We did not determine why 238 entries have a 181-day gap, how often fields are edited after addition, or which CISA process sets each `dueDate`. The CISA catalog page does not define the fields or state an update frequency, so those points rely on the schema file and the kev-data README.

## Sources and verification

Checked on October 15, 2026.

| Important claim | Source | Verification |
|---|---|---|
| Catalog version 2026.10.14, release time, count 1,745 equals array length and unique CVE IDs | [CISA KEV JSON feed](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json), downloaded October 15, 2026 | Verified (snapshot) |
| Field definitions, including the Known/Unknown and forensicTriage semantics and the `cwes` format | [CISA KEV JSON schema](https://github.com/cisagov/kev-data/blob/develop/known_exploited_vulnerabilities_schema.json) | Verified |
| Weekday update pattern; repository synchronised within minutes; no inline revision history | [cisagov/kev-data README](https://github.com/cisagov/kev-data/blob/develop/README.md) | Verified; the CISA catalog page itself states no update frequency |
| JSON, CSV and schema links on CISA's page | [CISA KEV catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) | Verified |
| Counts of Known/Unknown, forensicTriage Yes/No, empty cwes, notes patterns, due-date gap tables, 128 entries since June 10, 2026 | Our calculation on the downloaded JSON | Qualified: depends on the October 15, 2026 snapshot; June 10, 2026 cut-off is the BOD 26-04 page date |
| BOD 26-04 applies to U.S. federal civilian agencies | [CISA, BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk) | Verified |
| Ahsay AhsayCBS CVE-2026-105134 added 2026-10-14, due 2026-10-17, triage Yes | KEV JSON as above | Verified (snapshot) |
| Script output | Run by us on October 15, 2026 against the five-row CSV shown | Verified |
| Production suggestions | Our analysis | Qualified: not tested |
