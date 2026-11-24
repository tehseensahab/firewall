+++
title = "BOD 26-04 Decision Table: All 16 Rows in SSVC JSON"
date = 2026-11-24T04:50:00Z
tags = ["bod 26-04", "ssvc", "cisa", "kev", "vulnrichment", "decision table", "vulnerability management", "sla"]
categories = ["appsec"]
summary = "CERT/CC publishes BOD 26-04 as a machine-readable SSVC decision table (cisa:DT_BOD2604 1.0.0): four yes/no inputs, 16 rows, five timelines. Here is every row, how to feed it from a CVE record and the KEV catalog, a tested Python lookup, and how the KEV catalog's own due dates compare with it."
description = "BOD 26-04 decision table in SSVC JSON: KEV, public exposure, Automatable and Technical Impact map to 3 days+forensics, 3, 14, 60 days or upgrade. 16 rows, code."
author = "John Marshall"
imageAlt = "A woman with a marker drawing a flowchart of labelled boxes and a grid table on a large whiteboard"
imageCredit = "Photo by [Beatriz Cattel](https://unsplash.com/photos/46G4xEr122c) on Unsplash"
takeaways = [
  "CERT/CC's SSVC repository encodes BOD 26-04 as decision table cisa:DT_BOD2604 version 1.0.0, added on 10-11 June 2026. Inputs: cisa:KEV 1.0.0, cisa:PE (Publicly Exposed) 1.0.0, ssvc:A (Automatable) 2.0.0, ssvc:TI (Technical Impact) 1.0.0. Output: cisa:BOD2604 1.0.0 with values FSU, 60D, 14D, 3D and 3DF.",
  "The 16 rows cover every combination exactly once: 3 rows give 3 days plus forensic investigation, 2 give 3 days, 6 give 14 days, 3 give 60 days and 2 give fix on system upgrade.",
  "Three of the four inputs are public: KEV membership from the catalog, and Automatable and Technical Impact from the CISA-ADP SSVC block in the CVE record. Publicly Exposed is about your asset, so only your inventory can supply it.",
  "A KEV CVE with Automatable yes and Technical Impact total lands on 3 days plus forensic investigation whether or not the asset is exposed. A non-KEV CVE on an unexposed asset never gets more urgent than 60 days, even with total impact.",
  "CERT/CC's page says readers 'should consult the directive' for details; treat CISA's directive text as authoritative and this JSON as a convenient encoding of it.",
]

[[faq]]
q = "Where is the BOD 26-04 decision table published as JSON?"
a = "In the CERT/CC SSVC repository on GitHub: data/json/decision_tables/cisa/cisa_bod_26_04_1_0_0.json, with a CSV copy at data/csv/cisa/cisa_bod_26_04_1_0_0.csv. The same object is in data/json/ssvc_object_registry.json under DecisionTable, namespace cisa, key DT_BOD2604, version 1.0.0."

[[faq]]
q = "Which BOD 26-04 rows require forensic triage?"
a = "Three rows, all with In KEV yes and Technical Impact total: publicly exposed and not automatable; not exposed and automatable; exposed and automatable. In other words, a KEV CVE with total impact gets the 3-days-plus-forensics outcome unless the asset is both unexposed and the flaw is not automatable, in which case it is 14 days."

[[faq]]
q = "Can I compute the BOD 26-04 timeline from a CVE record alone?"
a = "No. The CVE record's CISA-ADP SSVC block supplies Automatable and Technical Impact, and the KEV catalog supplies In KEV, but Publicly Exposed describes your asset. The same CVE can be 14 days on an internal host and 3 days plus forensics on an internet-facing one."

[[faq]]
q = "Do private companies have to follow BOD 26-04?"
a = "No. Binding operational directives apply to US federal civilian executive branch agencies. Private teams can still reuse the table as a ready-made patch SLA policy, which is the use case this article covers."
+++

**Short answer:** BOD 26-04 sets federal remediation timelines from four yes/no questions: is the CVE in KEV, is the asset publicly exposed, is exploitation automatable, and is the technical impact total. CERT/CC publishes that mapping as a machine-readable SSVC decision table, `cisa:DT_BOD2604` version 1.0.0, with 16 rows and five outcomes ranging from "fix on system upgrade" to "3 days & forensic investigation". Three of the inputs come from public data you can fetch; the fourth comes from your asset inventory. Below are all 16 rows, the field-level mapping from a CVE record and the KEV catalog, and a lookup script we ran against real records.

This is the "encode the policy" step of the [vulnerability prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/). For what the directive requires of agencies (scope, phases, forensic triage), see our [BOD 26-04 explainer](/posts/cisa-bod-26-04-explained-kev-deadlines-forensic-triage-and-what-private-teams-can-borrow/); this article does not repeat it.

## Where the table lives

The [CERT/CC SSVC repository](https://github.com/CERTCC/SSVC) holds the table in three forms (we read commit `bf3213b`, 22 October 2026):

| File | Format |
|---|---|
| `data/json/decision_tables/cisa/cisa_bod_26_04_1_0_0.json` | SSVC DecisionTable JSON (schemaVersion 2.0.0) |
| `data/csv/cisa/cisa_bod_26_04_1_0_0.csv` | One row per combination, human-readable values |
| `data/json/ssvc_object_registry.json` | Registry entry: `types.DecisionTable.namespaces.cisa.keys.DT_BOD2604.versions["1.0.0"]` |

The table was added in a commit titled "Add CISA BOD 26-04 decision framework and related definitions" on 10 June 2026, with follow-up commits on 11 June. CERT/CC's [how-to page](https://certcc.github.io/SSVC/howto/cisa_response/) calls it "a tool [to] support implementers of CISA BOD 26-04" and adds: "Readers should consult the directive for more details about how to use the decision table below." Treat [CISA's directive](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk) as the authority and the JSON as an encoding of it.

## The four inputs and five outcomes

Each decision point is identified by namespace, key and version. These IDs are what the `mapping` rows use as keys.

| Decision point ID | Name | Values | Where you get it |
|---|---|---|---|
| `cisa:KEV:1.0.0` | In KEV | `N` No, `Y` Yes | [KEV catalog](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/): is `cveID` present? |
| `cisa:PE:1.0.0` | Publicly Exposed | `N` No, `Y` Yes | Your asset inventory |
| `ssvc:A:2.0.0` | Automatable | `N` No, `Y` Yes | CVE record, CISA-ADP SSVC option `Automatable` |
| `ssvc:TI:1.0.0` | Technical Impact | `P` Partial, `T` Total | CVE record, CISA-ADP SSVC option `Technical Impact` |

The registry defines Publicly Exposed as whether "the asset is accessible to unauthenticated or untrusted entities via public networks, such as the internet, regardless of its physical or logical location." Note the subject: the asset, not the vulnerability. CERT/CC's page says the same: "InKEV, Automatable, and Technical Impact address the vulnerability whereas Publicly Exposed questions the state of the asset."

The outcome group `cisa:BOD2604:1.0.0` has five values:

| Key | Name | Definition (verbatim from the registry) |
|---|---|---|
| `FSU` | Fix on system upgrade | "The vulnerability should be remediated the next time the vulnerable asset receives a scheduled major upgrade or rebuild." |
| `60D` | 60 days | "Remediate within 60 days." |
| `14D` | 14 days | "Remediate within 14 days." |
| `3D` | 3 days | "Remediate within 3 days." |
| `3DF` | 3 days & forensic investigation | "Remediate within 3 days and carry out a forensic triage of the asset to assess whether the system is compromised." |

## All 16 rows

We checked with a script that the 16 `mapping` rows cover each of the 2×2×2×2 input combinations exactly once. Sorted by outcome:

| In KEV | Publicly exposed | Automatable | Technical impact | Timeline |
|---|---|---|---|---|
| Yes | Yes | Yes | Total | **3 days + forensic investigation** |
| Yes | Yes | No | Total | **3 days + forensic investigation** |
| Yes | No | Yes | Total | **3 days + forensic investigation** |
| Yes | Yes | Yes | Partial | 3 days |
| No | Yes | Yes | Total | 3 days |
| Yes | No | No | Partial | 14 days |
| Yes | Yes | No | Partial | 14 days |
| Yes | No | Yes | Partial | 14 days |
| Yes | No | No | Total | 14 days |
| No | Yes | Yes | Partial | 14 days |
| No | Yes | No | Total | 14 days |
| No | Yes | No | Partial | 60 days |
| No | No | Yes | Partial | 60 days |
| No | No | Yes | Total | 60 days |
| No | No | No | Partial | Fix on system upgrade |
| No | No | No | Total | Fix on system upgrade |

Totals: 3 rows `3DF`, 2 rows `3D`, 6 rows `14D`, 3 rows `60D`, 2 rows `FSU`.

### Patterns worth knowing before you automate it

- **Forensics needs KEV and total impact.** All three `3DF` rows have In KEV yes and Technical Impact total. The only KEV-plus-total row without forensics is the unexposed, non-automatable one (14 days).
- **A KEV CVE never goes below 14 days.** All eight KEV rows are `14D`, `3D` or `3DF`.
- **Exposure alone can produce a 3-day deadline without KEV.** Not in KEV, publicly exposed, automatable and total impact gives `3D`.
- **On an unexposed asset, non-KEV flaws top out at 60 days.** Total impact does not change the outcome there: no/no/no gives `FSU` for both partial and total, and no/no/yes gives `60D` for both.

That last point is the one that surprises people used to CVSS-driven SLAs: a CVSS 9.8 bug that is not in KEV, on an internal-only host, with a not-automatable SSVC assessment, is a fix-on-upgrade item under this table.

## Mapping a CVE record into the table

CISA's Vulnrichment ADP container stores SSVC as an `options` list of words, not the registry's value keys. A real example, from the CVE record for [CVE-2026-76466](/posts/cisco-expressway-cve-2026-76466-kev-root-rce-fixed-release/) (Cisco Expressway) in [cvelistV5](https://github.com/CVEProject/cvelistV5):

```json
{"type": "ssvc", "content": {
  "timestamp": "2026-10-21T00:00:00+00:00",
  "options": [{"Exploitation": "active"}, {"Automatable": "yes"}, {"Technical Impact": "total"}],
  "role": "CISA Coordinator", "version": "2.0.3", "id": "CVE-2026-76466"}}
```

The [Vulnrichment README](https://github.com/cisagov/vulnrichment) explains the version string: "major.minor denotes the SSVC version, and patch denotes the decision tree version. For the current CISA decision tree, this results in a version number of 2.0.3". It also urges consumers "to observe the version when decoding SSVC scores". In the SSVC registry, the CISA Coordinator table `cisa:DT_CO` 2.0.3 uses `ssvc:A:2.0.0` and `ssvc:TI:1.0.0`, the same decision point versions as `DT_BOD2604`, so the word-to-key mapping is direct:

| CISA-ADP option | Value | DT_BOD2604 key |
|---|---|---|
| `Automatable` | `yes` / `no` | `ssvc:A:2.0.0` = `Y` / `N` |
| `Technical Impact` | `total` / `partial` | `ssvc:TI:1.0.0` = `T` / `P` |

`Exploitation` is not an input to this table: KEV membership plays that role. For how to read the ADP block itself, see [CISA Vulnrichment: reading SSVC values](/posts/cisa-vulnrichment-how-to-read-ssvc-values-in-a-cve-record-and-turn-them-into-a-patch-decision/).

## A lookup script

The script below reads the decision table JSON, a cvelistV5 record and the KEV catalog, takes exposure as a flag, and prints the row's outcome. It refuses to guess when the CVE has no CISA-ADP SSVC block or carries an SSVC version other than 2.0.3. Python 3 standard library only.

```python
#!/usr/bin/env python3
"""BOD 26-04 timeline lookup from the CERT/CC SSVC decision table.
Usage: bod2604.py DT_JSON CVE_JSON KEV_JSON --exposed yes|no"""
import json, sys, argparse

p = argparse.ArgumentParser()
p.add_argument("dt"); p.add_argument("cve"); p.add_argument("kev")
p.add_argument("--exposed", choices=["yes", "no"], required=True)
a = p.parse_args()

dt = json.load(open(a.dt))
assert (dt["namespace"], dt["key"], dt["version"]) == ("cisa", "DT_BOD2604", "1.0.0")
outcome_id = dt["outcome"]                              # "cisa:BOD2604:1.0.0"
labels = {v["key"]: v["name"] for v in dt["decision_points"][outcome_id]["values"]}

# 1. CISA-ADP SSVC options from the CVE record (CISA Coordinator tree 2.0.3)
rec = json.load(open(a.cve))
cve_id = rec["cveMetadata"]["cveId"]
ssvc = None
for adp in rec["containers"].get("adp", []):
    for m in adp.get("metrics", []) or []:
        o = m.get("other", {})
        if o.get("type") == "ssvc":
            ssvc = o["content"]
if ssvc is None:
    sys.exit(f"{cve_id}: no CISA-ADP SSVC block; cannot evaluate")
if ssvc["version"] != "2.0.3":
    sys.exit(f"{cve_id}: unexpected SSVC version {ssvc['version']}; re-check the mapping")
opts = {k: v for o in ssvc["options"] for k, v in o.items()}

# 2. KEV membership from the catalog
in_kev = any(v["cveID"] == cve_id for v in json.load(open(a.kev))["vulnerabilities"])

# 3. Map words to decision-point value keys and look up the row
yn = {"yes": "Y", "no": "N"}
row_in = {
    "cisa:KEV:1.0.0": "Y" if in_kev else "N",
    "cisa:PE:1.0.0": yn[a.exposed],
    "ssvc:A:2.0.0": yn[opts["Automatable"]],
    "ssvc:TI:1.0.0": {"partial": "P", "total": "T"}[opts["Technical Impact"]],
}
for row in dt["mapping"]:
    if all(row[k] == v for k, v in row_in.items()):
        print(cve_id, row_in, "->", row[outcome_id], labels[row[outcome_id]])
        break
```

We ran it on 24 November 2026 against KEV catalog version 2026.11.23 and current cvelistV5 records:

```text
$ python3 bod2604.py dt.json CVE-2026-76466.json kev.json --exposed no
CVE-2026-76466 {..., 'cisa:PE:1.0.0': 'N', 'ssvc:A:2.0.0': 'Y', 'ssvc:TI:1.0.0': 'T'} -> 3DF 3 days & forensic investigation
$ python3 bod2604.py dt.json CVE-2026-40217.json kev.json --exposed no
CVE-2026-40217 {..., 'cisa:PE:1.0.0': 'N', 'ssvc:A:2.0.0': 'N', 'ssvc:TI:1.0.0': 'T'} -> 14D 14 days
$ python3 bod2604.py dt.json CVE-2026-40217.json kev.json --exposed yes
CVE-2026-40217 {..., 'cisa:PE:1.0.0': 'Y', 'ssvc:A:2.0.0': 'N', 'ssvc:TI:1.0.0': 'T'} -> 3DF 3 days & forensic investigation
```

The second CVE (BerriAI LiteLLM, added to KEV on 18 November) shows why exposure matters: the same flaw is a two-week item on an internal host and a three-day forensic case on an internet-facing one. For production use, load the KEV catalog once into a set instead of scanning it per CVE, and pull exposure from your CMDB or attack-surface tool rather than a flag.

## How the KEV catalog's own due dates line up

The KEV catalog publishes one `dueDate` and one `forensicTriage` flag per CVE, while the table needs a per-asset exposure value. So we checked whether each catalog entry's deadline matches the table for *some* exposure value. Method: the 175 entries in KEV catalog 2026.11.23 with `dateAdded` on or after 10 June 2026, joined to their current cvelistV5 records (all 175 carry a CISA-ADP SSVC block, version 2.0.3); `dueDate` minus `dateAdded` in days, plus `forensicTriage`, compared with the table's outcome for In KEV yes, the record's Automatable and Technical Impact, and each exposure value.

| Comparison | Entries (of 175) |
|---|---|
| Matches the table with Publicly Exposed = yes | 134 |
| Matches the table with Publicly Exposed = no | 109 |
| Matches for at least one exposure value | 161 |
| Matches for neither | 14 |

Two cautions. First, we compared against the SSVC values in today's records; CISA can update ADP values after a KEV listing, and we did not replay their history. Second, the catalog deadline is CISA's per-CVE call and the directive (per our earlier reading) lets the clock start at whichever comes first, KEV listing or an agency finding the flaw. So the 14 non-matching entries are not errors on CISA's part; they are a reason to compute your own outcome per asset instead of copying `dueDate`. Our [KEV dueDate analysis](/posts/kev-duedate-days-after-dateadded-3-14-21-day-deadlines/) covers the catalog side in more depth.

## Using it outside federal agencies

For a private team, the table is a ready-made SLA policy with two properties that CVSS thresholds lack: it uses exploitation evidence (KEV) and an asset attribute (exposure) as first-class inputs. Three practical choices:

1. **Make exposure a data field.** Tag every asset `publicly_exposed: yes|no` using the registry's definition, and default unknown assets to yes.
2. **Decide what to do when SSVC is missing.** Not every CVE has a CISA-ADP SSVC block. Our script exits; a policy might treat missing Automatable and Technical Impact as yes and total until triaged.
3. **Pin versions.** Store `cisa:DT_BOD2604:1.0.0` and the SSVC version you mapped from (`2.0.3`) on each ticket, so a future table or tree version does not silently change old decisions.

## Limits of this article

- We could not fetch CISA's directive page from our research environment in this run, so we did not compare the 16 rows against the directive's own table line by line. The JSON is CERT/CC's encoding; CERT/CC points readers to the directive.
- Row counts and the KEV comparison are from data pulled on 24 November 2026 and will drift as KEV and CVE records change.
- The script is a tested illustration, not a compliance tool.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Table ID, version, inputs, outcomes, 16 rows and value definitions | [CERTCC/SSVC](https://github.com/CERTCC/SSVC) `data/json/decision_tables/cisa/cisa_bod_26_04_1_0_0.json`, `data/csv/cisa/cisa_bod_26_04_1_0_0.csv`, `data/json/ssvc_object_registry.json` (commit bf3213b) | Verified (parsed with Python) |
| Added 10 June 2026, follow-ups 11 June | CERTCC/SSVC git log for the table files | Verified |
| "Readers should consult the directive"; asset vs vulnerability inputs | [CERT/CC how-to page](https://certcc.github.io/SSVC/howto/cisa_response/) (source `docs/howto/cisa_response.md`) | Verified |
| CISA-ADP SSVC version 2.0.3 meaning | [cisagov/vulnrichment README](https://github.com/cisagov/vulnrichment) | Verified |
| CISA Coordinator table 2.0.3 uses ssvc:A:2.0.0 and ssvc:TI:1.0.0 | SSVC registry, `cisa:DT_CO` 2.0.3 | Verified |
| CVE-2026-76466 and CVE-2026-40217 SSVC values | [cvelistV5](https://github.com/CVEProject/cvelistV5) records, fetched 24 Nov 2026 | Verified |
| 175 post-June entries; 134 / 109 / 161 / 14 comparison | [cisagov/kev-data](https://github.com/cisagov/kev-data) catalog 2026.11.23 joined to cvelistV5 | Verified (our computation) |
| Row-by-row match with the directive's own table | CISA directive text | Not checked in this run (see Limits) |
