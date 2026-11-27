+++
title = "KEV notes Field: Parse 3,606 Links Into Ticket Fields"
date = 2026-11-27T04:45:00Z
tags = ["kev", "cisa", "kev-data", "known exploited vulnerabilities", "bod 26-04", "vulnerability management", "data engineering", "python"]
categories = ["security-operations"]
summary = "The KEV notes field is a semicolon-joined string, not a list. We parsed all 1,805 entries in catalog 2026.11.25: 3,606 links, an NVD link in every entry, no vendor link in 789, BOD 26-04 labels on 186, and a handful of separator and URL quirks that break naive splitting. Classification rules, a tested Python parser and a fallback for the NVD-only entries."
description = "KEV notes field parsed: 3,606 links in 1,805 entries, classed as vendor, CISA BOD 26-04, directive or NVD. Python parser, separator quirks, NVD-only fallback."
author = "John Marshall"
imageAlt = "A close-up of a tangle of black, blue, beige and gold cables and plugs"
imageCredit = "Photo by [Brett Jordan](https://unsplash.com/photos/fMXC9nAWv3w) on Unsplash"
takeaways = [
  "notes is one free-text string per KEV entry. In catalog 2026.11.25 all 1,805 entries have it, and it holds 3,606 links: 1,805 NVD, 1,368 vendor or third-party, 370 BOD 26-04, 31 other CISA directive, 24 other CISA pages and 8 web.archive.org.",
  "Every entry has an NVD link, and in 1,804 of them it is the last link. 789 entries have no vendor or third-party link at all; 772, almost all added in 2021 and 2022, have only the NVD link.",
  "186 entries, all added from June 11, 2026, carry 'BOD 26-04:' and 'Forensics Triage Requirements:' labels. 65 of those have forensicTriage set to No, so the label is not the decision: read the forensicTriage field.",
  "Splitting on ' ; ' is not enough: 412 semicolons have no space before them, one URL (glibc, CVE-2023-4911) contains semicolons, two links use 'https:/' with one slash, 11 directive links end in ')', and one entry has page titles where the URLs should be.",
  "For the NVD-only entries, take vendor links from the CVE record: 494 of 768 records we fetched have a reference tagged vendor-advisory, patch or x_refsource_CONFIRM."
]

[[faq]]
q = "What is in the notes field of the CISA KEV catalog?"
a = "The schema calls it 'Any additional notes about the vulnerability' and types it as a string. In practice it holds links separated by semicolons, sometimes with labels such as 'BOD 26-04:' or 'CISA Mitigation Instructions:' and occasional free text. In catalog 2026.11.25 the 1,805 entries hold 3,606 links, and every entry includes an NVD link."

[[faq]]
q = "How do I split KEV notes into URLs?"
a = "Do not split on ' ; ' alone. Extract URLs with a pattern that lets a semicolon stay inside a URL unless it is followed by whitespace, another URL or the end of the string, trim trailing ')', ',' and '.', and repair 'https:/' with a single slash. The parser in this article does that and was run against the full catalog."

[[faq]]
q = "Does a 'Forensics Triage Requirements' link in notes mean forensic triage is required?"
a = "No. In catalog 2026.11.25, 186 entries carry that label and 65 of them have forensicTriage set to 'No'. The schema defines forensicTriage as 'Yes' if forensic triage is required per BOD 26-04, so use that field, not the presence of the link."

[[faq]]
q = "Where do I find the vendor advisory for a KEV entry whose notes only has an NVD link?"
a = "Fetch the CVE record from cvelistV5 and read the CNA references. For 768 of the 772 NVD-only entries we fetched the record; 494 have a reference tagged vendor-advisory, patch or the legacy x_refsource_CONFIRM, and 306 have vendor-advisory specifically."
+++

**Short answer:** the KEV `notes` field is a single string, not a list of links. In catalog version `2026.11.25` (1,805 entries) it holds **3,606 links**: an NVD link in every entry, a vendor or third-party link in 1,009 entries, and CISA directive links in 208. **789 entries have no vendor link**, and the label "Forensics Triage Requirements" appears on 65 entries whose `forensicTriage` value is `No`. If you copy `notes` into tickets, parse it, classify each link and take the triage decision from the structured field.

The [KEV JSON feed field guide](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/) covers all twelve fields and notes that `notes` needs splitting. This article does that job properly for the whole catalog: what kinds of links are in it, where naive splitting breaks, and how to fill the "vendor advisory" and "CISA guidance" fields of a remediation ticket. It is one step in the [CVE-record-to-ticket prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/).

## Method

- **Input:** `known_exploited_vulnerabilities.json` from [cisagov/kev-data](https://github.com/cisagov/kev-data), catalog version `2026.11.25`, `dateReleased` 2026-11-25T19:48:12Z, 1,805 entries, downloaded November 27, 2026.
- **Schema:** the repository's `known_exploited_vulnerabilities_schema.json` describes `notes` as "Any additional notes about the vulnerability" with type `string`. It defines no structure inside it.
- **Parsing:** the Python parser below, run against the full file. Every count in this article comes from that run or the small checks listed under "Reproduce it".
- **CVE records:** for entries whose only link is NVD, we fetched the matching record from [CVEProject/cvelistV5](https://github.com/CVEProject/cvelistV5) (`main`, November 27, 2026) and read the CNA `references` tags.

## What the 3,606 links are

| Link class | Rule | Links | Entries with one |
|---|---|---|---|
| NVD | host `nvd.nist.gov` | 1,805 | 1,805 |
| Vendor or third party | any other host except CISA and the Internet Archive | 1,368 | 1,009 |
| CISA BOD 26-04 | `cisa.gov/.../directives/bod-26-04...` | 370 | 185 |
| Other CISA directive | `cisa.gov/.../directives/...` (emergency directives and supplemental direction) | 31 | 23 |
| Other CISA page | other `cisa.gov` paths (alerts, ICS advisories, mitigation pages) | 24 | 24 |
| Archive | `web.archive.org` | 8 | 8 |

The most common hosts after NVD and CISA are `support.apple.com` (220 links), `msrc.microsoft.com` (137), `github.com` (87), `git.kernel.org` (50) and `sec.cloudapps.cisco.com` (44). "Vendor or third party" is a host rule, not a judgement: `github.com` and `git.kernel.org` links are usually upstream commits or advisories rather than a vendor bulletin.

Links per entry: 772 entries have one link, 686 have two, 93 three, 172 four, and 82 have five or more (the maximum is 11).

### The NVD link is the anchor, usually last

Every entry has an NVD `vuln/detail` link, and in 1,804 entries it is the final link. The exception is CVE-2026-56155, where a Microsoft AD FS decommission guide follows the NVD link. Do not rely on "last link = NVD"; classify by host.

### 789 entries have no vendor link

789 entries contain no vendor or third-party link, and **772** contain nothing but the NVD link. Those 772 are old entries: 294 added in 2021 and 474 in 2022, plus 4 added since 2024. If your ticket template expects a vendor advisory from `notes`, roughly two in five KEV entries will leave it empty.

The CVE record is the better fallback. We fetched cvelistV5 records for the 772 NVD-only entries (768 returned JSON; 4 requests returned an HTML error page and were not retried). In the CNA container:

- **494** records have at least one reference tagged `vendor-advisory`, `patch` or `x_refsource_CONFIRM`.
- **306** have a `vendor-advisory` tag; 28 have `patch`.
- 36 have references with no tags at all.

The [CVE schema's reference tags](https://github.com/CVEProject/cve-schema/blob/main/schema/tags/reference-tags.json) define `vendor-advisory` as "Advisory is from the vendor/publisher/maintainer of the product or the parent organization" and `patch` as a reference that "contains an update to the software that fixes the vulnerability". `x_refsource_CONFIRM` is not in that list; it is an `x_` extension tag, which the schema allows, and it is common in records converted from the older MITRE format (326 of the 768). Treat it as a likely, not certain, vendor link.

## Labels and boilerplate

Some segments carry a label before the URL, and a few carry prose:

| Text in `notes` | Entries | What it signals |
|---|---|---|
| `BOD 26-04:` and `Forensics Triage Requirements:` | 186 | Added June 11, 2026 or later; links to the directive and its implementation guidance |
| Open-source component / third-party library boilerplate ("check with specific vendors…") | 87 | No single vendor fix; the affected product list is yours to build |
| `Reference CISA's ED 21-03` / `ED 21-02` (emergency directive) | 11 | Legacy emergency directive guidance |
| `CISA Mitigation Instructions:` | 16 | CISA-authored mitigation page or directive |

Several wording variants of the open-source boilerplate exist ("affects a common open-source component", "could affect an open-source component", "affects an open-source component"), so match on a phrase such as `third-party library` rather than the full sentence.

### The forensic triage label is not the decision

All but two of the 188 entries added from June 11 to November 25, 2026 have the labels. But the labels are attached whether or not triage applies:

| Entries with the "Forensics Triage Requirements" label | `forensicTriage` = Yes | `forensicTriage` = No |
|---|---|---|
| 186 | 121 | 65 |

The 65 "No" entries are spread across every month from June to November 2026 (12 in November alone). The schema is explicit about which field decides: `forensicTriage` is "'Yes' if this vulnerability requires forensic triage per BOD 26-04; 'No' if forensic triage is not required per BOD 26-04". One Yes entry, the Ivanti Connect Secure CVE-2026-104935 added on October 13, 2026, has no labels at all. So: link the implementation guidance in the ticket when you like, but set the triage task from `forensicTriage`. Our [BOD 26-04 explainer](/posts/cisa-bod-26-04-explained-kev-deadlines-forensic-triage-and-what-private-teams-can-borrow/) covers what forensic triage involves.

## Where naive splitting breaks

`notes.split(" ; ")` works for most entries and silently mangles the rest. What we found in the current file:

1. **Separator spacing varies.** 1,292 semicolons are written ` ; `, 412 as `; ` with no space before, one as ` ;`, and the TIBCO entry for CVE-2018-5430 joins two URLs with a bare `;`.
2. **A URL contains semicolons.** The glibc gitweb link for CVE-2023-4911 is `https://sourceware.org/git/?p=glibc.git;a=commitdiff;h=1056e5b4…`. Splitting on `;` cuts it into three fragments.
3. **Single-slash scheme.** Two links start `https:/` (Ivanti for CVE-2026-104935, Code Aurora for CVE-2013-2597). A strict URL regex skips them, and the Ivanti entry then appears to have no vendor link.
4. **Trailing punctuation.** The 11 emergency-directive links are written inside parentheses in prose, so the URL picks up a trailing `)`.
5. **Titles instead of URLs.** CVE-2026-96951 has `BOD 26-04: BOD 26-04: Prioritizing Security Updates Based on Risk | CISA` where the link should be; the parser keeps it as text, not as a link.
6. **Empty segments.** Some entries contain `; ;`, such as the Ahsay entry for CVE-2026-105134.

None of these are errors you can report and forget: the [catalog changes audit](/posts/kev-catalog-changes-field-edits-removals-kev-data-history/) found 38 content edits to `notes` since January 2025, so a quirk can be fixed or introduced in any release. Parse defensively on every pull.

## A parser that handles the whole catalog

Python 3.9+, standard library only. We ran it on catalog `2026.11.25`; the output below is from that run.

```python
"""Split CISA KEV `notes` into typed links. Python 3.9+, stdlib only."""
import json, re, sys
from collections import Counter

# A URL may contain ';' (gitweb: ?p=glibc.git;a=commitdiff;h=...), so only a ';'
# followed by whitespace, another URL or end of string ends it.
URL = re.compile(r"https?:/+[^\s;]*(?:;(?!\s|https?:|$)[^\s;]*)*")
LABEL = re.compile(r"(BOD 26-04|Forensics Triage Requirements|CISA Mitigation Instructions"
                   r"|Additional References):\s*$")

def kind(url):
    host = url.split("/")[2].lower()
    path = url.lower()
    if host == "nvd.nist.gov":
        return "nvd"
    if host.endswith("cisa.gov"):
        if "/directives/bod-26-04" in path:
            return "cisa-bod-26-04"
        if "/directives/" in path:
            return "cisa-directive"
        return "cisa-other"
    if host == "web.archive.org":
        return "archive"
    return "vendor-or-third-party"

def parse_notes(notes):
    links, text = [], []
    pos = 0
    for m in URL.finditer(notes):
        before = notes[pos:m.start()]
        pos = m.end()
        url = m.group(0)
        while url[-1] in ".,]" or (url[-1] == ")" and url.count("(") < url.count(")")):
            url = url[:-1]
        url = re.sub(r"^(https?:)/(?!/)", r"\1//", url)   # repair 'https:/host'
        label = LABEL.search(before.split(";")[-1])
        links.append({"url": url, "kind": kind(url),
                      "label": label.group(1) if label else None})
        text += [s.strip() for s in before.split(";")]
    text += [s.strip() for s in notes[pos:].split(";")]
    text = [t for t in text if t and not LABEL.fullmatch(t)]
    return {"links": links, "text": text}

if __name__ == "__main__":
    vulns = json.load(open(sys.argv[1]))["vulnerabilities"]
    kinds, entries_with = Counter(), Counter()
    for v in vulns:
        p = parse_notes(v["notes"])
        ks = [l["kind"] for l in p["links"]]
        kinds.update(ks)
        entries_with.update(set(ks))
        if not any(k in ("vendor-or-third-party", "archive") for k in ks):
            entries_with["no-vendor-link"] += 1
    print("entries", len(vulns), "links", sum(kinds.values()))
    for k, n in kinds.most_common():
        print(f"{k:24} links={n:5} entries={entries_with[k]}")
    print("entries without a vendor/third-party link:", entries_with["no-vendor-link"])
    demo = next(v for v in vulns if v["cveID"] == "CVE-2023-4911")
    print(json.dumps(parse_notes(demo["notes"])["links"][0]))
```

Run it with `curl -sO https://raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json && python3 kev_notes.py known_exploited_vulnerabilities.json`:

```text
entries 1805 links 3606
nvd                      links= 1805 entries=1805
vendor-or-third-party    links= 1368 entries=1009
cisa-bod-26-04           links=  370 entries=185
cisa-directive           links=   31 entries=23
cisa-other               links=   24 entries=24
archive                  links=    8 entries=8
entries without a vendor/third-party link: 789
{"url": "https://sourceware.org/git/?p=glibc.git;a=commitdiff;h=1056e5b4c3f2d90ed2b4a55f96add28da2f4c8fa", "kind": "vendor-or-third-party", "label": null}
```

BOD 26-04 links appear in 185 entries, not 186, because CVE-2026-96951 carries the labels with page titles instead of URLs.

The parser is a starting point, not a URL validator. The trailing-punctuation rule can, in principle, trim a legitimate final `.` or `,`; the eight archive links include a text-fragment URL with commas inside it, which the rule leaves intact because the commas are not at the end. Re-run the counts after each catalog release and look at anything new.

## Turning parsed notes into ticket fields

A reasonable mapping for a remediation ticket:

| Ticket field | Take it from | Fallback |
|---|---|---|
| Vendor advisory | `vendor-or-third-party` links in `notes` | CNA `references` tagged `vendor-advisory`, then `patch`, then `x_refsource_CONFIRM` in the CVE record |
| CISA guidance | `cisa-directive` and `cisa-other` links | none; leave empty |
| Forensic triage required | `forensicTriage` field | never the presence of the BOD 26-04 label |
| Directive reference | `cisa-bod-26-04` links | the directive pages themselves |
| Analyst context | `text` segments (open-source boilerplate, ED prose) | `requiredAction` and `shortDescription` |
| NVD | `nvd` link | build it from `cveID` |

Two practical notes. First, show every vendor link, not only the first: 114 entries have two vendor or third-party links and 72 have three or more, often one per affected product or platform. Second, keep the raw `notes` string on the ticket next to the parsed fields, so an analyst can see what the parser did with an odd entry. For the deadline and the rest of the prioritization inputs, join the KEV entry with [EPSS](/posts/epss-data-feed-columns-percentile-vs-probability-and-how-to-join-it-to-a-scanner-export/) and the CVE record as the workflow guide describes.

## Reproduce it

- Separator counts: `re.finditer(r'(\s*);(\s*)', notes)` over all entries, bucketed by whether whitespace appears before and after.
- Labels: substring counts of `BOD 26-04:` and `Forensics Triage Requirements:` in `notes`, cross-tabulated with `forensicTriage`.
- NVD-only fallback: for each entry whose only parsed link is NVD, fetch `https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/<year>/<NNxxx>/<CVE>.json` and collect `containers.cna.references[].tags`.

## Limits of this article

- **One snapshot.** Counts are for catalog `2026.11.25`. CISA edits `notes` after listing, so numbers and quirks will drift.
- **Host-based classes.** "Vendor or third party" means "not NVD, CISA or the Internet Archive". We did not check whether each host belongs to the affected vendor.
- **Links not checked.** We did not request any of the 3,606 URLs, so we cannot say how many are dead or redirected.
- **Four CVE records not fetched.** The fallback counts cover 768 of 772 NVD-only entries.
- **Why the labels appear on "No" entries** is not stated in the data; the pattern suggests the labels are a template applied to every new entry, but that is our reading.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Catalog 2026.11.25, 1,805 entries, released 2026-11-25T19:48:12Z | [known_exploited_vulnerabilities.json](https://github.com/cisagov/kev-data/blob/main/known_exploited_vulnerabilities.json) | Verified |
| `notes` and `forensicTriage` descriptions | [known_exploited_vulnerabilities_schema.json](https://github.com/cisagov/kev-data/blob/main/known_exploited_vulnerabilities_schema.json) | Verified |
| 3,606 links and class counts; 789 entries without vendor link; 772 NVD-only by year; links per entry | Parser run above | Verified |
| 186 labelled entries: 121 Yes, 65 No; CVE-2026-104935 Yes without labels | Same file, substring counts | Verified |
| Separator, semicolon-in-URL, `https:/`, `)` and title-instead-of-URL quirks with example CVEs | Same file | Verified |
| 494 / 306 / 28 / 36 reference-tag counts for 768 NVD-only records | [CVEProject/cvelistV5](https://github.com/CVEProject/cvelistV5) records fetched November 27, 2026 | Verified |
| `vendor-advisory` and `patch` tag definitions; `x_` extension tags allowed | [cve-schema reference-tags.json](https://github.com/CVEProject/cve-schema/blob/main/schema/tags/reference-tags.json), [CVE_Record_Format.json](https://github.com/CVEProject/cve-schema/blob/main/schema/CVE_Record_Format.json) | Verified |
| `x_refsource_CONFIRM` usually marks a vendor link | Our interpretation of legacy records | Qualified |
| Labels are a template applied to new entries | Not stated by CISA; inferred from the data | Qualified |
