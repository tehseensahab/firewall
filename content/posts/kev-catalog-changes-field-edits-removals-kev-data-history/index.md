+++
title = "KEV Catalog Changes: 157 Field Edits and 4 Removals"
date = 2026-11-26T04:45:00Z
tags = ["kev", "cisa", "kev-data", "known exploited vulnerabilities", "vulnerability management", "data engineering", "git history"]
categories = ["security-operations"]
summary = "CISA edits KEV entries after listing, and the catalog has no changelog field to tell you. We replayed all 349 readable kev-data catalog versions since January 2025: 157 content edits to text fields across 83 CVEs, 92 whitespace-only edits, four removals and one invalid JSON version. Here is what changes, a script to reproduce it and how to sync KEV safely."
description = "KEV catalog changes after listing: 157 content edits to vendor, product, name, description, action, notes and CWE fields, 4 removals. kev-data replay and code."
author = "Craig Leslie"
imageAlt = "An open notebook with fanned pages and a red pen lying beside it on a dark table"
imageCredit = "Photo by [Emmanuel Phaeton](https://unsplash.com/photos/Ft5Mb25iNmI) on Unsplash"
takeaways = [
  "CISA changes KEV entries after it lists them. Replaying 349 readable versions of known_exploited_vulnerabilities.json in cisagov/kev-data (January 27, 2025 to November 25, 2026) found 157 content edits to seven text fields across 83 CVEs.",
  "shortDescription (50 content edits), notes (38), vulnerabilityName (24) and product (20) change most. Typical edits: vendor renames such as Zimbra to Synacor, 'Unspecified Vulnerability' replaced with a weakness name, added chaining context and added mitigation links.",
  "A further 92 edits only removed leading or trailing spaces, 86 of them in the 2026.11.13 version. Code that compares vendorProject or product strings exactly saw those entries change.",
  "Four CVEs disappeared from the catalog; one (Ivanti EPMM CVE-2026-1281) came back the same day. The JSON has no removed or modified field, so an upsert-only sync keeps removed entries forever.",
  "Sync rule: key on cveID, store a hash of each entry, diff every pull for added, changed and missing IDs, strip whitespace before comparing, and validate the JSON before replacing your copy (one committed version was not valid JSON).",
]

[[faq]]
q = "Does CISA change KEV entries after they are added?"
a = "Yes. In the cisagov/kev-data history from January 27, 2025 to November 25, 2026, we counted 157 content edits to vendorProject, product, vulnerabilityName, shortDescription, requiredAction, notes and cwes across 83 CVEs, plus separate edits to dueDate, dateAdded, knownRansomwareCampaignUse and forensicTriage."

[[faq]]
q = "Can a CVE be removed from the KEV catalog?"
a = "Yes. Four CVEs disappeared from the catalog in that period: CVE-2025-4664, CVE-2025-6264, CVE-2026-1281 (re-added the same day) and CVE-2026-69836. The catalog data does not record why, so the only way to see a removal is to compare two versions."

[[faq]]
q = "Does the KEV JSON have a last-modified date per entry?"
a = "No. The schema defines catalogVersion, dateReleased and count for the file, and dateAdded and dueDate per entry, but no per-entry modified date or change log. To detect edits you have to diff versions yourself or replay the kev-data git history."

[[faq]]
q = "How should I store KEV data so edits are not missed?"
a = "Key each entry on cveID, keep a hash of the normalized entry, and on every pull report new IDs, changed hashes and missing IDs separately. Strip whitespace before comparing text, never join on vendorProject or product, and reject a download that does not parse or whose count does not match its entries."
+++

**Short answer:** a KEV entry is not frozen when CISA publishes it. Replaying every readable version of the catalog in the [cisagov/kev-data](https://github.com/cisagov/kev-data) repository, from January 27, 2025 to catalog version `2026.11.25`, we found 157 content edits to seven text fields across 83 CVEs, another 92 edits that only trimmed whitespace, and four CVEs that were removed (one came back the same day). The JSON carries no per-entry change date, so if your pipeline only inserts new `cveID`s, it is quietly out of date.

Earlier posts covered the date and flag fields: [edited `dueDate` values](/posts/kev-duedate-days-after-dateadded-3-14-21-day-deadlines/) and [Unknown-to-Known ransomware flips](/posts/kev-knownransomwarecampaignuse-unknown-to-known-flips/). This one covers everything else: the names, descriptions, actions, notes and CWEs that scanners and ticketing tools copy into findings, and the entries that vanish. For what each field means, start with the [KEV JSON feed field guide](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/).

## Method

- **Input:** a full clone of `cisagov/kev-data` (default branch `develop`, head `51e0a77`, committed 2026-11-25T22:59:40Z). The current catalog is version `2026.11.25` with 1,805 entries.
- **Versions:** every first-parent commit that touched `known_exploited_vulnerabilities.json`, oldest first. That is 350 commits; one (`15200f9`, catalog `2025.02.25`) is not valid JSON, leaving 349 readable versions. The oldest is catalog `2025.01.24`, committed January 27, 2025, so edits made before then are not visible.
- **Comparison:** for every CVE present in two consecutive versions we compared `vendorProject`, `product`, `vulnerabilityName`, `shortDescription`, `requiredAction`, `notes` and `cwes`. An edit is **whitespace-only** if the old and new strings are equal after stripping leading and trailing spaces; every other change is a **content** edit. A **removal** is a CVE present in one version and missing from the next.

The schema file in the same repository describes `notes` as "Any additional notes about the vulnerability" and `shortDescription` as "A short description of the vulnerability". Nothing in it promises these stay fixed, and it defines no field that records a change.

## Results

| Field | Content edits | Whitespace-only edits |
|---|---:|---:|
| `shortDescription` | 50 | 36 |
| `notes` | 38 | 8 |
| `vulnerabilityName` | 24 | 27 |
| `product` | 20 | 13 |
| `vendorProject` | 11 | 6 |
| `requiredAction` | 9 | 2 |
| `cwes` | 5 | 0 |
| **Total** | **157** | **92** |

The 157 content edits touched 83 distinct CVEs; the 92 whitespace edits touched 76. A single version, `2026.11.13`, holds 86 of the whitespace edits (36 descriptions, 27 names, 13 products, 8 notes, 2 required actions). Version `2026.11.17` trimmed trailing spaces from six `vendorProject` values (`"SimpleHelp "` and `"Array Networks "`).

### What content edits look like

The edits fall into a few patterns. All examples are old → new values from the replay.

**Vendor and product renames.** On 2025-02-24 CISA edited ten Zimbra entries in one version: eight moved from `vendorProject` `Zimbra` to `Synacor`, and products were normalized to `Zimbra Collaboration Suite (ZCS)` and names rewritten to match. Other renames: `Palo Alto` → `Palo Alto Networks` (CVE-2025-0108), `Hewlett Packard (HP)` → `Hewlett Packard Enterprise (HPE)` (CVE-2025-37164), and typo fixes such as `PTRG Network Monitor` → `PRTG Network Monitor` (CVE-2018-19410) and `Kernal` → `Kernel` (CVE-2018-14634).

**A weakness name replaces "Unspecified".** `Android Runtime Unspecified Vulnerability` became `Android Runtime Use-After-Free Vulnerability` (CVE-2025-48543), and `F5 BIG-IP Unspecified Vulnerability` became `F5 BIG-IP Stack-Based Buffer Overflow Vulnerability`, with `cwes` going from empty to `CWE-121` the same day (CVE-2025-53521).

**Context added to the description.** CVE-2025-53770 (SharePoint) gained: "This vulnerability could be chained with CVE-2025-53771. CVE-2025-53770 is a patch bypass for CVE-2025-49704". CVE-2025-55182 (React Server Components) gained a note that CVE-2025-66478 "has been rejected, but it is associated with" it. GeoVision entries (CVE-2024-11120, CVE-2024-6047) gained an end-of-life warning ending "Users should discontinue product utilization."

**Changed required actions.** The three SharePoint entries (CVE-2025-49704, CVE-2025-49706, CVE-2025-53770) moved on 2025-08-05 from "CISA recommends…" wording to an instruction beginning "Disconnect public-facing versions of SharePoint Server that have reached their end-of-life (EOL) or end-of-service (EOS)". A `requiredAction` change is the one most likely to change what an owner must do, and it arrives with no new `dueDate`.

**Notes: links added, moved or fixed.** Most `notes` edits add a vendor or CISA mitigation URL, swap a moved vendor page, or add the boilerplate that a vulnerability "affects a common open-source component". `notes` is a `" ; "`-separated list of URLs and text, so a parser that splits it will see the list grow.

**CWE corrections.** Five `cwes` edits: three filled an empty list, one added a second CWE (CVE-2025-24985: `CWE-190` → `CWE-190`, `CWE-122`) and one fixed an invalid ID (CVE-2026-31431: `CWE-699` → `CWE-669`; CWE-699 is a CWE view, not a weakness entry).

### Removals

| CVE | Catalog product | dateAdded | Missing from version | Now |
|---|---|---|---|---|
| CVE-2025-4664 | Google Chromium | 2025-05-15 | 2025.06.09 | absent |
| CVE-2025-6264 | Rapid7 Velociraptor | 2025-10-14 | 2025.10.22 | absent |
| CVE-2026-1281 | Ivanti EPMM | 2026-01-29 | 2026.01.29 (later commit) | re-added same day |
| CVE-2026-69836 | Microsoft Entra ID | 2026-08-21 | 2026.08.21 (later commit) | absent |

The catalog data gives no reason for any removal; commit messages are the generic "Add Updated KEV Files for <date>". We did not find a CISA statement for these removals and do not speculate on why. What matters for tooling: an entry you imported can stop existing, and nothing in the next file says so.

### One version was not valid JSON

Commit `15200f9` (2025-02-25, catalog `2025.02.25`, 1,280 entries) fails to parse ("Unterminated string" near the `dateAdded` of a Progress WS_FTP entry). The next commit, about an hour later, replaced it. A job that pulled the raw file in that window and did not validate it would have either crashed or, worse, overwritten a good local copy with nothing.

## Reproduce it

Python 3.9+ and git, standard library only. We ran it on 2026-11-26 against the clone described above (`python3 -I kev_edits.py kev-data`); the output matches the tables.

```python
# Replay cisagov/kev-data history and count post-listing edits per KEV field.
# Usage: git clone https://github.com/cisagov/kev-data && python3 kev_edits.py kev-data
import collections, json, subprocess, sys

repo = sys.argv[1]
FILE = "known_exploited_vulnerabilities.json"
TEXT = ["vendorProject", "product", "vulnerabilityName", "shortDescription",
        "requiredAction", "notes", "cwes"]

def git(*args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, check=True).stdout

commits = git("log", "--first-parent", "--reverse", "--format=%H", "--", FILE).split()
prev, edits, removed, invalid = None, collections.Counter(), [], []
cves = collections.defaultdict(set)
for h in commits:
    try:
        cat = json.loads(git("show", f"{h.decode()}:{FILE}"))
    except json.JSONDecodeError:
        invalid.append(h.decode()[:7])
        continue
    cur = {v["cveID"]: v for v in cat["vulnerabilities"]}
    if prev:
        for cve, v in cur.items():
            old = prev.get(cve)
            if not old:
                continue
            for f in TEXT:
                a, b = old.get(f), v.get(f)
                if a != b:
                    kind = ("whitespace" if isinstance(a, str) and isinstance(b, str)
                            and a.strip() == b.strip() else "content")
                    edits[(f, kind)] += 1
                    cves[kind].add(cve)
        removed += [(c, cat["catalogVersion"]) for c in prev if c not in cur]
    prev = cur

print("catalog versions replayed:", len(commits) - len(invalid), "invalid JSON:", invalid)
for f in TEXT:
    print(f"{f:18} content {edits[(f, 'content')]:3}  whitespace-only {edits[(f, 'whitespace')]:3}")
print("CVEs with content edits:", len(cves["content"]),
      "| with whitespace-only edits:", len(cves["whitespace"]))
print("removed:", removed)
```

Output (abridged):

```text
catalog versions replayed: 349 invalid JSON: ['15200f9']
shortDescription   content  50  whitespace-only  36
notes              content  38  whitespace-only   8
CVEs with content edits: 83 | with whitespace-only edits: 76
removed: [('CVE-2025-4664', '2025.06.09'), ('CVE-2025-6264', '2025.10.22'),
          ('CVE-2026-1281', '2026.01.29'), ('CVE-2026-69836', '2026.08.21')]
```

The script reports a removal when a CVE drops out; CVE-2026-1281 reappears in a later commit the same day and is in the current catalog.

## How to sync KEV without missing edits

1. **Key on `cveID` only.** Never join scanner findings to KEV on `vendorProject` or `product`. They are free text, they get renamed (Zimbra → Synacor) and they gained and lost trailing spaces.
2. **Hash each entry and diff three ways.** On every pull, compute a hash of each normalized entry and report *added* IDs, *changed* hashes and *missing* IDs. Changed and missing are the two cases an insert-only sync never sees.
3. **Normalize before you hash.** Strip leading and trailing whitespace from strings and sort `cwes`, or the 2026.11.13 clean-up will look like 76 changed CVEs.
4. **Route changes by field.** A changed `requiredAction`, `dueDate` or `forensicTriage` should reopen or update the ticket. A changed `notes` or `shortDescription` should refresh the ticket text. A renamed vendor or product should update your display name, not create a new finding.
5. **Handle removals explicitly.** When a CVE disappears, keep your history but stop applying KEV-driven SLAs to it, and flag it for a human rather than silently deleting the ticket.
6. **Validate before replacing.** Parse the file, check that `count` equals the number of `vulnerabilities`, and keep the previous copy if either check fails.

These steps slot into the "is it in KEV?" stage of our [CVE-record-to-ticket prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/); the point is that the answer, and the wording attached to it, can change after the ticket exists.

## Limits of this article

- **Window:** kev-data history starts January 27, 2025. Edits CISA made to older entries before that date are not visible.
- **Granularity:** we compare consecutive committed versions. If CISA changed a field and changed it back between two commits, we would not see it.
- **Classification:** "whitespace-only" means leading or trailing spaces. Internal double spaces count as content edits; 234 current `notes` values contain a double space.
- **Scope:** we counted seven text fields. Date and flag fields are covered in the linked `dueDate` and ransomware posts and not re-counted here.
- **No reasons:** the data does not say why an entry was edited or removed. Patterns described above are our reading of the diffs.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| 350 commits to the JSON file, 349 readable, 1 invalid (`15200f9`) | [cisagov/kev-data](https://github.com/cisagov/kev-data) git history at `51e0a77`, script above | Verified |
| 157 content edits across 83 CVEs; 92 whitespace-only across 76 CVEs; per-field counts | Same replay, script above | Verified |
| 86 whitespace edits in version 2026.11.13; 6 vendorProject trims in 2026.11.17 | Same replay | Verified |
| Example old → new values (Zimbra, Palo Alto, HPE, Android, F5, SharePoint, React, GeoVision, CWE) | Same replay, per-entry diffs | Verified |
| Four removals and CVE-2026-1281 re-added | Same replay; presence checked in catalog 2026.11.25 | Verified |
| Catalog 2026.11.25 has 1,805 entries | `known_exploited_vulnerabilities.json` at `51e0a77` | Verified |
| Field descriptions; no per-entry modified field | [known_exploited_vulnerabilities_schema.json](https://github.com/cisagov/kev-data/blob/develop/known_exploited_vulnerabilities_schema.json) | Verified |
| Reasons for edits and removals | Not stated in the data; patterns are our interpretation | Qualified |
