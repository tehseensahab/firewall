+++
title = "KEV requiredAction: Map 45 Text Variants to Ticket Actions"
date = 2026-11-28T04:45:00Z
tags = ["cisa kev", "kev requiredaction", "bod 26-04", "bod 22-01", "vulnerability management", "ticket automation", "end-of-life"]
categories = ["security-operations"]
summary = "The KEV catalog's requiredAction field holds 45 distinct strings across 1,808 entries, but the wording tracks when CISA added an entry, not whether a patch exists. A census of catalog 2026.11.27, a classifier that maps every string to five ticket actions, and the end-of-life signal that moved to shortDescription."
description = "KEV requiredAction: 45 strings across 1,808 entries map to 5 ticket actions. The wording follows CISA's template era, not patch status; EoL flags moved to shortDescription."
author = "John Marshall"
takeaways = [
  "In KEV catalog 2026.11.27, the 1,808 requiredAction values reduce to 45 distinct strings, and four templates cover 1,666 entries (92%).",
  "The wording tracks when the entry was added. 'Apply updates per vendor instructions.' appears on 893 entries, all added between 2021-11-03 and 2023-06-23; no entry added since uses it, even where a vendor update exists.",
  "Every one of the 191 entries added from 2026-06-11 onward carries the same BOD 26-04 template. 340 older entries still cite BOD 22-01, which BOD 26-04 revoked; CISA did not rewrite them.",
  "Explicit end-of-life wording in requiredAction stops after 2025-07-22. Since then CISA flags possible EoL in shortDescription instead: 30 entries carry that flag outside the retire bucket.",
  "Do not decide 'patch' vs 'mitigate' from this field. Map it to a small set of ticket actions, check shortDescription for EoL, and take the fix itself from the vendor link in notes."
]

[[faq]]
q = "What does requiredAction mean in the CISA KEV catalog?"
a = "The KEV JSON schema describes requiredAction as 'The required action to address the vulnerability'. It is free text, not an enum. In catalog version 2026.11.27 the 1,808 entries use 45 distinct strings, most of them a handful of CISA templates."

[[faq]]
q = "Does 'apply mitigations per vendor instructions' mean there is no patch?"
a = "No. That wording is a template CISA has used on new entries since mid-2023, including for products with normal vendor updates: 108 Microsoft entries added since July 2023 carry mitigation wording. Read the vendor advisory linked in the notes field to see whether the fix is an update."

[[faq]]
q = "Why do some KEV entries still mention BOD 22-01?"
a = "CISA's BOD 26-04 page states that it revokes BOD 22-01, and every entry added from June 11, 2026 uses BOD 26-04 wording. Older entries were not rewritten: 340 entries in catalog 2026.11.27 still reference BOD 22-01. Treat that as historical text, not current guidance."

[[faq]]
q = "How do I detect end-of-life products in KEV?"
a = "Check two fields. Until July 2025 CISA put end-of-life instructions in requiredAction (83 entries). Since then the requiredAction is the generic template and the EoL warning sits in shortDescription, for example 'The impacted product(s) could be end-of-life (EoL) and/or end-of-service (EoS).'"
+++

**Short answer:** KEV's `requiredAction` is free text, but in practice it is a short list of CISA templates. In catalog version **2026.11.27** the **1,808** entries carry **45** distinct strings, and the template an entry got depends mostly on **when CISA added it**, not on whether a vendor patch exists. Map the field to a few ticket actions, check `shortDescription` for end-of-life flags, and never route "patch" versus "mitigate" on the wording alone.

This post covers one field. For the full feed layout see the [KEV JSON feed field guide](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/); for the vendor and directive links that sit beside this field, see the [KEV notes field parser](/posts/kev-notes-field-parse-links-vendor-advisory-bod-26-04-nvd/). Both feed the triage step of the [CVE-record-to-ticket prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/).

## Method

- **Data:** `known_exploited_vulnerabilities.json` from `cisagov/kev-data` (main branch), `catalogVersion` 2026.11.27, `dateReleased` 2026-11-27T18:03:12Z, 1,808 entries. Fetched November 28, 2026.
- **Schema:** `known_exploited_vulnerabilities_schema.json` in the same repository, which defines `requiredAction` as `"The required action to address the vulnerability"`, type `string`, and lists it as required.
- **Counts:** every number below comes from the Python classifier in this article, run with Python 3 against that file. Exact strings were compared after trimming whitespace (trimming does not change the count of 45).

## The four templates that cover 92% of the catalog

| Entries | Exact text (trimmed) | Added |
|---:|---|---|
| 893 | Apply updates per vendor instructions. | 2021-11-03 to 2023-06-23 |
| 323 | Apply mitigations per vendor instructions, follow applicable BOD 22-01 guidance for cloud services, or discontinue use of the product if mitigations are unavailable. | 2023-10-10 to 2026-06-09 |
| 260 | Apply mitigations per vendor instructions or discontinue use of the product if mitigations are unavailable. | 2023-07-17 to 2025-02-24 |
| 190 | Apply mitigations in accordance with vendor instructions, ensuring compliance with CISA’s BOD 26-04 Prioritizing Security Updates Based on Risk (see URL in Notes) guidance and CISA’s “Forensics Triage Requirements” (see URL in Notes). Follow applicable BOD 26-04 guidance for cloud services or discontinue use of the product if mitigations are unavailable. Stakeholders are responsible for evaluating each asset's internet exposure and ensuring adherence to BOD 26-04 patching guidelines. | 2026-06-11 onward |

Those four account for 1,666 entries. A 191st BOD 26-04 entry has the same text without the final full stop, and several BOD 22-01 entries differ only by a missing period, a leading quote mark or an appended workaround, which is why exact-string matching overcounts the variety. The remaining strings are end-of-life instructions, emergency-directive pointers and a few one-off instructions.

## The wording follows CISA's template era, not patch status

The clearest example is the first template. "Apply updates per vendor instructions." appears on 893 entries, every one added between **2021-11-03** and **2023-06-23**. No entry added after that date uses it, although CISA has kept adding vulnerabilities that vendors fixed with ordinary updates. Of the 853 entries added after 2023-06-23, none got the plain "apply updates" text; 108 Microsoft entries added since July 2023 carry mitigation wording instead.

The same applies at the other end. From **2026-06-11** onward, all 191 new entries use the BOD 26-04 template, whatever the product. CISA's BOD 26-04 page is dated June 10, 2026 and states that it revokes BOD 22-01 (our [BOD 26-04 explainer](/posts/cisa-bod-26-04-explained-kev-deadlines-forensic-triage-and-what-private-teams-can-borrow/) covers the directive itself). The last BOD 22-01 template entry was added on 2026-06-09.

CISA did not rewrite older entries when the directive changed: **340 entries** in catalog 2026.11.27 still contain "BOD 22-01". If your ticket text quotes `requiredAction` verbatim, those tickets point at a revoked directive. Our [KEV catalog change audit](/posts/kev-catalog-changes-field-edits-removals-kev-data-history/) shows how rarely CISA edits existing entries at all.

## End-of-life moved to shortDescription

Until mid-2025 CISA wrote end-of-life instructions into `requiredAction`, for example "The impacted product is end-of-life and should be disconnected if still in use." (52 entries). The last entry with EoL wording in `requiredAction` was added on **2025-07-22**.

Since then, entries for possibly unsupported products keep the generic template in `requiredAction` and add a sentence to `shortDescription`. Two entries added in November 2026, CVE-2026-131914 (Idunno AntiCsrf) and CVE-2026-90436 (Apache Axis), end their descriptions with: "The impacted product(s) could be end-of-life (EoL) and/or end-of-service (EoS). Users are advised to discontinue use and/or transition to a supported version." Their `requiredAction` is the BOD 26-04 template.

A parser that only reads `requiredAction` misses this: 30 entries outside the retire bucket carry an EoL flag in `shortDescription` (23 with legacy mitigation text, 7 with BOD 26-04 text).

## A classifier for the whole catalog

The script maps every entry to one of five actions, first rule wins, plus an EoL flag from `shortDescription`. It is a working example, tested against catalog 2026.11.27 only; new template wording will need a new rule.

```python
"""Classify CISA KEV requiredAction text into ticket actions.
Run: python3 kev_actions.py known_exploited_vulnerabilities.json"""
import json, re, sys, collections

RULES = [  # first match wins
    ("directive",       r"Emergency Directive|\bED \d{2}-\d{2}|CISA instructions|BOD 23-02|CISA.s guidelines"),
    ("retire",          r"(?i)end-of-life|\beo[ls]\b|retired and replaced"),
    ("bod-26-04",       r"BOD 26-04"),
    ("mitigate-legacy", r"BOD 22-01|mitigation|remediation"),
    ("update",          r"[Aa]pply updates"),
]
EOL_DESC = re.compile(r"end-of-life|\(EoL\)", re.I)

def classify(entry):
    text = entry["requiredAction"].strip()
    action = next((name for name, pat in RULES if re.search(pat, text)), "manual-review")
    # Since mid-2025 CISA flags possible EoL in shortDescription, not requiredAction.
    eol_flag = action != "retire" and bool(EOL_DESC.search(entry.get("shortDescription", "")))
    return action, eol_flag

if __name__ == "__main__":
    vulns = json.load(open(sys.argv[1]))["vulnerabilities"]
    counts, eol, span = collections.Counter(), collections.Counter(), {}
    for v in vulns:
        action, flag = classify(v)
        counts[action] += 1; eol[action] += flag
        lo, hi = span.get(action, (v["dateAdded"], v["dateAdded"]))
        span[action] = (min(lo, v["dateAdded"]), max(hi, v["dateAdded"]))
    for a, n in counts.most_common():
        print(f"{a:16} {n:5}  added {span[a][0]} to {span[a][1]}  eol-in-description {eol[a]}")
    print("total", sum(counts.values()))
```

Output against catalog 2026.11.27:

```text
update             912  added 2021-11-03 to 2024-08-21  eol-in-description 0
mitigate-legacy    606  added 2021-12-10 to 2026-06-09  eol-in-description 23
bod-26-04          191  added 2026-06-11 to 2026-11-27  eol-in-description 7
retire              83  added 2021-11-03 to 2025-07-22  eol-in-description 0
directive           14  added 2023-10-16 to 2026-05-14  eol-in-description 0
manual-review        2  added 2022-06-02 to 2024-03-25  eol-in-description 0
total 1808
```

Notes on the buckets:

- **update** (912) is the 893 plain entries plus 19 "Apply updates per vendor instructions or discontinue use of the product if updates are unavailable" variants added up to August 2024.
- **directive** (14) covers emergency directives (for example ED 26-03 for Cisco SD-WAN), BOD 23-02 for internet-exposed Cisco IOS XE Web UI, and "Apply mitigations as set forth in the CISA instructions linked below." These point to CISA documents that go beyond the vendor fix.
- **retire** (83) includes three SharePoint entries that combine "disconnect end-of-life versions" with "follow the mitigations" for supported versions; such mixed entries need both actions on the ticket.
- **manual-review** (2) are one-offs: CVE-2019-7256 ("Contact the vendor for guidance on remediating firmware, per their advisory.") and CVE-2022-26134, which begins "Immediately block all internet traffic to and from affected products AND apply the update per vendor instructions".

## Turning the buckets into ticket actions

| Bucket | What the text actually tells you | Ticket action |
|---|---|---|
| update, mitigate-legacy, bod-26-04 | Fix per the vendor; mitigate or stop using it if there is no fix | Look up the fix in the vendor advisory from `notes`; open a remediation ticket with the KEV `dueDate` |
| bod-26-04 with `forensicTriage` = Yes | As above, plus CISA's forensic triage reference (123 of the 191 entries) | Add a compromise-check subtask before closing |
| retire, or any entry with the EoL flag | Product may be unsupported | Open an asset-retirement or upgrade-path ticket; confirm support status with the vendor |
| directive | A CISA directive or hunt guidance applies | Attach the linked CISA document; expect hunt and hardening steps, not just a patch |
| manual-review | One-off instruction | Route to a human |

The first row deliberately merges three wordings. The difference between "apply updates" and "apply mitigations" is the template era, so treating them differently would schedule a 2022 Windows entry and a 2025 Windows entry for different work. Deadlines come from `dueDate`, not from this field; our [KEV dueDate analysis](/posts/kev-duedate-days-after-dateadded-3-14-21-day-deadlines/) covers how those are set.

## Limits of this article

- The counts describe one catalog version (2026.11.27). CISA can add new template wording at any time; rerun the script and look at `manual-review` before trusting the mapping.
- The classifier reads text with regular expressions. It does not know whether a vendor patch exists; that answer is in the vendor advisory, not in KEV.
- BOD 26-04 and BOD 22-01 are directives for U.S. Federal Civilian Executive Branch agencies. Private teams can borrow the actions above but are not bound by them.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Catalog version 2026.11.27, 1,808 entries, 45 distinct requiredAction strings, template counts and date ranges, 340 BOD 22-01 mentions, 30 EoL flags in shortDescription, 123 forensicTriage Yes | [cisagov/kev-data, known_exploited_vulnerabilities.json](https://github.com/cisagov/kev-data) (counted with the script above) | Verified |
| requiredAction defined as "The required action to address the vulnerability", type string, required | [kev-data schema file](https://github.com/cisagov/kev-data/blob/main/known_exploited_vulnerabilities_schema.json) | Verified |
| BOD 26-04 page dated June 10, 2026 states it revokes BOD 22-01 | [CISA, BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk); CISA's BOD 22-01 page is now titled "(Revoked)" | Verified (October 2026 reading of the BOD 26-04 page) |
| The template change reflects when entries were added, not patch availability | Our reading of the date ranges above; CISA does not document the template history | Qualified (editorial interpretation) |
