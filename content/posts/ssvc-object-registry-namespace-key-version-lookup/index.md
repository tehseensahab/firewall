+++
title = "SSVC Object Registry: Resolve namespace:key:version IDs"
date = 2026-11-25T04:30:00Z
tags = ["ssvc", "ssvc object registry", "cert/cc", "selectionlist", "cisa", "vulnrichment", "csaf", "vulnerability management", "python"]
categories = ["appsec"]
summary = "CERT/CC's ssvc_object_registry.json holds every SSVC decision point and decision table by type, namespace, key and version. This guide shows the structure, how to resolve an ID like ssvc:E:1.1.0:P, how to validate a SelectionList and how to turn CISA's ADP SSVC words into registry keys."
description = "SSVC object registry: resolve ssvc:E:1.1.0 IDs to names and definitions, validate SelectionList values and map CISA-ADP SSVC words to keys. Python, no deps."
author = "Craig Leslie"
imageAlt = "Rows of wooden card catalogue drawers with metal label holders, receding out of focus"
imageCredit = "Photo by [Ilya Semenov](https://unsplash.com/photos/fCnYbTnJASs) on Unsplash"
takeaways = [
  "CERT/CC's data/json/ssvc_object_registry.json (schemaVersion 2.0.0, generated 2026-10-20) nests objects as types > namespaces > keys > versions. The current file holds 105 decision point keys in 148 versions and 16 decision tables.",
  "Every object has an ID of the form namespace:key:version, and a value adds a fourth part: ssvc:E:1.1.0:P is the Public PoC value of Exploitation version 1.1.0. Decision tables use the same IDs to name their inputs.",
  "Versions matter: ssvc:E:1.0.0 and ssvc:E:1.1.0 both have a P value, but 1.1.0 narrows it to public PoC or a well-known method. ssvc:EXP:1.0.1 renamed Unavoidable (U) to Open (O). Resolve the exact version, not the latest.",
  "CISA's ADP SSVC block does not use registry keys. In the 2026-11-25 cvelistV5 snapshot all 226,884 CISA-ADP SSVC blocks had version 2.0.3, role CISA Coordinator and the same three option names, so a small name-to-key map covers them.",
  "Namespaces starting with x_ are private and are not in the public registry; a validator should flag them rather than reject the whole document.",
]

[[faq]]
q = "Where is the SSVC object registry?"
a = "In the CERT/CC SSVC repository on GitHub at data/json/ssvc_object_registry.json. Its schema is data/schema/v2/SsvcObjectRegistry_2_0_0.schema.json. The file is generated from the project's Python models, so take it from a pinned commit if you need reproducible results."

[[faq]]
q = "What does ssvc:E:1.1.0:P mean?"
a = "Namespace ssvc, decision point key E (Exploitation), version 1.1.0, value key P (Public PoC). The same four parts locate the object in the registry: types.DecisionPoint.namespaces.ssvc.keys.E.versions['1.1.0'].values.P."

[[faq]]
q = "How do I convert CISA's SSVC options in a CVE record to registry keys?"
a = "Take the decision table named by the block's version (cisa:DT_CO:2.0.3 for every current CISA-ADP block), resolve its input decision points, then match each option name and value by name, case-insensitively. Exploitation 'poc' needs one alias because version 1.1.0 names that value 'Public PoC'."

[[faq]]
q = "Should my validator reject unknown namespaces?"
a = "Not by default. The SSVC namespace decision record allows unregistered namespaces that start with x_ for private or experimental use, and namespace extensions with a slash. Flag them for review and only reject when your pipeline requires registered objects."
+++

**Short answer:** CERT/CC publishes every SSVC decision point and decision table in one JSON file, `data/json/ssvc_object_registry.json`, indexed by type, namespace, key and version. Any SSVC value can be written as an ID such as `ssvc:E:1.1.0:P`, and that ID is also the path to its name and definition in the registry. Resolve the exact version, check value keys against it, and you can validate SSVC selections from CSAF files, map CISA's SSVC words in CVE records to the same keys, and look up a decision table outcome, all in about 100 lines of standard-library Python.

This guide is for engineers who consume SSVC from more than one place. Our [Vulnrichment SSVC guide](/posts/cisa-vulnrichment-how-to-read-ssvc-values-in-a-cve-record-and-turn-them-into-a-patch-decision/) explains what the three CISA values mean, the [BOD 26-04 decision table post](/posts/bod-26-04-decision-table-ssvc-json-lookup/) walks one table row by row, and the [CSAF 2.1 metrics guide](/posts/csaf-2-1-metrics-epss-ssvc-cvss-v4-per-product/) shows where vendors put SSVC in advisories. This piece is about the lookup layer underneath all three.

## What is in the registry file

The figures below come from the file at CERT/CC SSVC commit `11e6fdf` (generated `2026-10-20T16:15:07Z`), parsed with Python.

The top level has five keys: `name` ("SSVC Object Registry"), `definition`, `schemaVersion` (`2.0.0`), `generatedAt` and `types`. Under `types` there are two object types, each split by namespace:

| Type | Namespace | Keys | Versions |
|---|---|---:|---:|
| DecisionPoint | `ssvc` | 25 | 35 |
| DecisionPoint | `cvss` | 60 | 93 |
| DecisionPoint | `basic` | 13 | 13 |
| DecisionPoint | `cisa` | 5 | 5 |
| DecisionPoint | `nist#800-30` | 1 | 1 |
| DecisionPoint | `x_com.yahooinc#prioritized-risk-remediation` | 1 | 1 |
| DecisionTable | `ssvc` | 7 | 7 |
| DecisionTable | `cvss` | 7 | 7 |
| DecisionTable | `cisa` | 2 | 2 |

That is 105 decision point keys in 148 versions, and 16 decision tables. The `ssvc` namespace holds the project's own decision points (Exploitation `E`, Automatable `A`, Technical Impact `TI`, Mission and Well-Being Impact `MWI` and so on). `cvss` models CVSS metrics as decision points, `cisa` holds CISA-specific ones (`KEV`, `PE` for Publicly Exposed, `BOD2604`, the `CISA` outcome and `MP`), and `basic` holds generic scales such as yes/no and low/medium/high.

The path to any object is fixed:

```text
types.<Type>.namespaces.<namespace>.keys.<key>.versions.<version>.obj
types.DecisionPoint.namespaces.<ns>.keys.<key>.versions.<version>.values.<value_key>
```

Each version entry carries the full object under `obj`. Decision point versions also carry a `values` dictionary keyed by value key, so you do not have to scan the `obj.values` list. Decision tables have no `values` map.

## The ID format: namespace:key:version[:value]

The registry code in the SSVC repository (`src/ssvc/registry/base.py`) looks objects up "by its ID in the format `namespace:key:version[:value_key]`". Decision tables use the same three-part IDs to list their inputs. For example, the CISA Coordinator table `cisa:DT_CO:2.0.3` declares these decision points:

```json
["ssvc:E:1.1.0", "ssvc:A:2.0.0", "ssvc:TI:1.0.0", "ssvc:MWI:1.0.0", "cisa:CISA:1.1.0"]
```

The last one is the outcome (`T` Track, `T*` Track*, `AT` Attend, `AC` Act), and the table has 36 mapping rows.

### Why you must resolve the exact version

The registry keeps old versions, and they are not always cosmetic:

| ID | What changed |
|---|---|
| `ssvc:E:1.0.0` vs `ssvc:E:1.1.0` | Value P is "PoC" in 1.0.0 and includes "private evidence of exploitation is attested but not shared" and "widespread hearsay". In 1.1.0 it is "Public PoC": "Typical public PoC exists in sources such as Metasploit or websites like ExploitDB; or (2) the vulnerability has a well-known method of exploitation." |
| `ssvc:EXP:1.0.0` vs `ssvc:EXP:1.0.1` | System Exposure value Unavoidable (`U`) became Open (`O`). A `U` under 1.0.1 is invalid. |
| `ssvc:HI` 2.0.0, 2.0.1, 2.0.2 | Three versions of Human Impact with the same keys but edited definitions; a September 2026 commit to the registry is titled "Correct HI:2.0.2 value definitions to match DT_HI:1.0.0". |

The repository's own `lookup_latest()` helper picks the highest semantic version, which is convenient for authoring but wrong for reading someone else's data. A selection that says `ssvc:E:1.0.0` with value P may rest on hearsay; the same letter under 1.1.0 means a public exploit or a well-known method.

## Code: resolve, validate and map

The script below needs Python 3.9 or later and no third-party packages. We ran it against the registry at commit `11e6fdf` with `python3 -I ssvc_registry.py data/json/ssvc_object_registry.json`; the output follows the code. It is a reference implementation for a pipeline, not a full schema validator: run JSON Schema validation (`SelectionList_2_0_0.schema.json`) first, then these semantic checks.

```python
"""Resolve and validate SSVC selections against CERT/CC's ssvc_object_registry.json.
Python 3.9+, standard library only. Usage: python3 ssvc_registry.py path/to/ssvc_object_registry.json
"""
import json, sys

def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)["types"]

def resolve(types, objtype, obj_id):
    """obj_id = 'namespace:key:version' or 'namespace:key:version:value_key'."""
    parts = obj_id.split(":")
    if len(parts) not in (3, 4):
        raise ValueError(f"bad id {obj_id!r}")
    ns, key, ver = parts[:3]
    try:
        entry = types[objtype]["namespaces"][ns]["keys"][key]["versions"][ver]
    except KeyError:
        return None
    if len(parts) == 4:
        return entry.get("values", {}).get(parts[3])
    return entry["obj"]

def check_selection_list(types, sl):
    """Return a list of problems with an SSVC SelectionList 2.0.0 object."""
    problems = []
    for s in sl.get("selections", []):
        ns, key, ver = s["namespace"], s["key"], s["version"]
        dp_id = f"{ns}:{key}:{ver}"
        if ns.startswith("x_"):
            problems.append(f"{dp_id}: unregistered x_ namespace, not in the public registry")
            continue
        if "/" in ns:
            problems.append(f"{dp_id}: namespace extension; resolve the base namespace separately")
            continue
        dp = resolve(types, "DecisionPoint", dp_id)
        if dp is None:
            known = sorted(types["DecisionPoint"]["namespaces"].get(ns, {}).get("keys", {}).get(key, {}).get("versions", {}))
            problems.append(f"{dp_id}: not in registry (known versions: {known or 'none'})")
            continue
        valid = {v["key"] for v in dp["values"]}
        for v in s["values"]:
            if v["key"] not in valid:
                problems.append(f"{dp_id}: value {v['key']!r} not one of {sorted(valid)}")
    return problems

def adp_ssvc_to_selections(types, content, table_id=None):
    """Map CISA-ADP SSVC 'options' (names like 'active') to registry keys,
    using the inputs of the CISA Coordinator table that matches content['version']."""
    table_id = table_id or f"cisa:DT_CO:{content['version']}"
    table = resolve(types, "DecisionTable", table_id)
    if table is None:
        raise LookupError(f"no decision table {table_id}")
    by_name = {}
    for dp_id in table["decision_points"]:
        dp = resolve(types, "DecisionPoint", dp_id)
        by_name[dp["name"].lower()] = (dp_id, {v["name"].lower(): v["key"] for v in dp["values"]})
    out = []
    for opt in content["options"]:
        (name, value), = opt.items()
        dp_id, values = by_name[name.lower()]
        # ADP uses "poc"; ssvc:E:1.1.0 names the value "Public PoC"
        vkey = values.get(value.lower()) or {"poc": values.get("public poc")}.get(value.lower())
        ns, key, ver = dp_id.split(":")
        out.append({"namespace": ns, "key": key, "version": ver, "values": [{"key": vkey}]})
    return {"schemaVersion": "2.0.0", "timestamp": content["timestamp"],
            "target_ids": [content["id"]], "selections": out}

def decide(types, table_id, selections, extra):
    """Look up the outcome row in a decision table. extra = {'ssvc:MWI:1.0.0': 'H'} etc."""
    table = resolve(types, "DecisionTable", table_id)
    have = {f"{x['namespace']}:{x['key']}:{x['version']}": x["values"][0]["key"] for x in selections}
    have.update(extra)
    for row in table["mapping"]:
        if all(have.get(k) == v for k, v in row.items() if k != table["outcome"]):
            return row[table["outcome"]]
    return None

if __name__ == "__main__":
    types = load(sys.argv[1])
    print(resolve(types, "DecisionPoint", "ssvc:E:1.1.0:P")["name"])
    adp = {"timestamp": "2026-10-21T00:00:00+00:00", "id": "CVE-2026-76466", "version": "2.0.3",
           "role": "CISA Coordinator",
           "options": [{"Exploitation": "active"}, {"Automatable": "yes"}, {"Technical Impact": "total"}]}
    sl = adp_ssvc_to_selections(types, adp)
    print(json.dumps(sl["selections"]))
    print(check_selection_list(types, sl))
    for mwi in ("L", "H"):
        out = decide(types, "cisa:DT_CO:2.0.3", sl["selections"], {"ssvc:MWI:1.0.0": mwi})
        print("MWI", mwi, "->", out, resolve(types, "DecisionPoint", f"cisa:CISA:1.1.0:{out}")["name"])
    bad = {"selections": [
        {"namespace": "ssvc", "key": "E", "version": "2.0.0", "values": [{"key": "A"}]},
        {"namespace": "ssvc", "key": "EXP", "version": "1.0.1", "values": [{"key": "U"}]},
        {"namespace": "x_example.test#test", "key": "E", "version": "1.0.0", "values": [{"key": "A"}]}]}
    for p in check_selection_list(types, bad):
        print(p)
```

Output:

```text
Public PoC
[{"namespace": "ssvc", "key": "E", "version": "1.1.0", "values": [{"key": "A"}]}, {"namespace": "ssvc", "key": "A", "version": "2.0.0", "values": [{"key": "Y"}]}, {"namespace": "ssvc", "key": "TI", "version": "1.0.0", "values": [{"key": "T"}]}]
[]
MWI L -> AT Attend
MWI H -> AC Act
ssvc:E:2.0.0: not in registry (known versions: ['1.0.0', '1.1.0'])
ssvc:EXP:1.0.1: value 'U' not one of ['C', 'O', 'S']
x_example.test#test:E:1.0.0: unregistered x_ namespace, not in the public registry
```

The ADP example is the real SSVC block from the CVE record for [Cisco Expressway CVE-2026-76466](/posts/cisco-expressway-cve-2026-76466-kev-root-rce-fixed-release/) in cvelistV5 (timestamp `2026-10-21T00:00:00+00:00`). With Mission and Well-Being Impact low, the CISA Coordinator table returns Attend; with high, Act.

## Mapping CISA-ADP SSVC words to registry keys

CISA's ADP container stores SSVC as words, not keys:

```json
{"options": [{"Exploitation": "active"}, {"Automatable": "yes"}, {"Technical Impact": "total"}],
 "role": "CISA Coordinator", "version": "2.0.3"}
```

The [Vulnrichment README](https://github.com/cisagov/vulnrichment) says the version field means "major.minor denotes the SSVC version, and patch denotes the decision tree version", giving 2.0.3 for the current CISA tree, and urges consumers "to observe the version when decoding SSVC scores". The registry happens to contain a `cisa:DT_CO` table at exactly version 2.0.3, so the script uses `cisa:DT_CO:<version>` to find the input decision points. Treat that as a working convention, not something CISA documents: if CISA ships a new version and no table with that ID exists, the script raises `LookupError` instead of guessing.

How much variety do you need to handle? We counted every CVE JSON file in the cvelistV5 bulk export `2026-11-25_all_CVEs_at_midnight` (431,850 records):

| Field | Values seen in CISA-ADP SSVC blocks | Count |
|---|---|---:|
| `version` | 2.0.3 | 226,884 (all) |
| `role` | CISA Coordinator | 226,884 (all) |
| Option names | Exploitation, Automatable, Technical Impact | 226,884 (all) |
| Exploitation | none / poc / active | 176,560 / 48,525 / 1,799 |
| Automatable | no / yes | 174,860 / 52,024 |
| Technical Impact | partial / total | 147,724 / 79,160 |

Every value matches a registry value name case-insensitively except one: ADP writes `poc`, while `ssvc:E:1.1.0` names the value "Public PoC". The script carries that single alias. The fourth input of the CISA Coordinator table, Mission and Well-Being Impact, never appears in a CVE record because it describes your organization, so `decide()` takes it as a separate argument.

## Namespaces you will not find in the registry

The SSVC project's namespace decision record (ADR 0012, accepted 2025-07-22) defines three kinds:

- **Registered namespaces** such as `ssvc`, `cvss` and `cisa`, "for objects that we create and maintain".
- **Unregistered namespaces** that "must start with an `x_` prefix followed by a reverse domain name and conclude with a fragment, such as `x_example.test#test`", intended "for experimental or private use".
- **Namespace extensions**, written with a slash (the ADR's example is `ssvc//.example.isao#constituency-1`), which "refine existing objects with additional data or semantics" rather than introduce new ones.

The public registry does contain one `x_` namespace (`x_com.yahooinc#prioritized-risk-remediation`), but you should not expect a partner's private decision points to resolve. The script reports x_ and extension namespaces as findings instead of failing the document, so a CSAF file that mixes `ssvc:E` with a vendor's private decision point still yields the parts you can check.

## Common mistakes

- **Resolving the latest version.** It silently rewrites the meaning of an old selection (see `E` and `EXP` above).
- **Comparing names instead of keys.** Names change between versions ("PoC" vs "Public PoC"); keys and versions are the stable identifiers. Keep names for display only.
- **Treating `T*` as invalid.** The SelectionList schema's key pattern explicitly grandfathers `T*` ("`T*` is explicitly grandfathered in as a valid key, but should not be used for new objects"), and the CISA outcome uses it for Track*.
- **Reading the registry from `main` at runtime.** The file is regenerated from code. Vendor it at a pinned commit and update deliberately, like any other dependency.
- **Assuming CVE records carry all inputs.** CISA's block gives three of the four Coordinator inputs. Your asset context supplies the rest, as our [patch-decision workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/) shows.

## Limits of this article

Counts reflect the registry at commit `11e6fdf` and the cvelistV5 export of 2026-11-25; both change. The mapping from CISA's version string to `cisa:DT_CO:2.0.3` is our inference from matching IDs, not a published CISA rule. The script checks registry membership and value keys only; it does not enforce schema rules such as required timestamps.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Registry structure, schemaVersion 2.0.0, generatedAt 2026-10-20, 105 keys / 148 versions / 16 tables | [CERTCC/SSVC `data/json/ssvc_object_registry.json`](https://github.com/CERTCC/SSVC/blob/main/data/json/ssvc_object_registry.json) at commit 11e6fdf, parsed with Python | Verified |
| ID format `namespace:key:version[:value_key]`; `lookup_latest` picks highest semver | [CERTCC/SSVC `src/ssvc/registry/base.py`](https://github.com/CERTCC/SSVC/blob/main/src/ssvc/registry/base.py) | Verified |
| E 1.0.0 vs 1.1.0 P definitions, EXP U to O, DT_CO 2.0.3 inputs and 36 rows | Registry file (verbatim definitions) | Verified |
| Namespace types and x_ rule | [CERTCC/SSVC ADR 0012](https://github.com/CERTCC/SSVC/blob/main/docs/adr/0012-ssvc-namespaces.md) | Verified |
| `T*` grandfathered key; SelectionList required fields | [CERTCC/SSVC `SelectionList_2_0_0.schema.json`](https://github.com/CERTCC/SSVC/blob/main/data/schema/v2/SelectionList_2_0_0.schema.json) | Verified |
| CISA-ADP version semantics | [cisagov/vulnrichment README](https://github.com/cisagov/vulnrichment) | Verified |
| 226,884 CISA-ADP SSVC blocks, value counts | [cvelistV5 release](https://github.com/CVEProject/cvelistV5/releases) `2026-11-25_all_CVEs_at_midnight`, counted with Python | Verified (snapshot) |
| ADP version 2.0.3 maps to registry table `cisa:DT_CO:2.0.3` | Our inference from matching IDs | Qualified |
