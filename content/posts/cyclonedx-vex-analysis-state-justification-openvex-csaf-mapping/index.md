+++
title = "CycloneDX VEX: analysis.state and justification to OpenVEX"
date = 2026-11-03T04:40:00Z
tags = ["vex", "cyclonedx", "openvex", "csaf", "sbom", "vulnerability management", "appsec"]
categories = ["appsec"]
summary = "CycloneDX VEX uses six analysis states and nine justifications; OpenVEX and CSAF use four statuses and five justifications. Here is a field-by-field mapping, which pairs line up and which do not, how Trivy reads CycloneDX VEX, and a tested Python converter that refuses to invent justifications."
description = "CycloneDX VEX mapped to OpenVEX and CSAF: analysis.state, justification, response and BOM-Link affects, with a tested Python converter and the gaps that lose data."
author = "Craig Leslie"
imageAlt = "Close-up of a silver modular synthesizer panel with black knobs, patched with pink, green, orange, red and yellow cables"
imageCredit = "Photo by [John Barkiple](https://unsplash.com/photos/l090uFWoPaI) on Unsplash"
takeaways = [
  "CycloneDX VEX lives in a BOM's vulnerabilities array: analysis.state (6 values), analysis.justification (9 values), analysis.response (5 values) and affects[].ref pointing at a component, usually by BOM-Link.",
  "States map cleanly onto OpenVEX and CSAF statuses except two: false_positive has no counterpart and resolved_with_pedigree collapses into fixed. Trivy's code treats false_positive as not_affected.",
  "Only two of CycloneDX's nine justifications line up with the five CISA justifications used by OpenVEX and CSAF: code_not_present and code_not_reachable. The rest have no clean equivalent.",
  "OpenVEX lets a not_affected statement carry an impact_statement instead of a justification label, so a converter can keep the CycloneDX reason as text rather than guess a label.",
  "A CycloneDX VEX that points at components by BOM-Link only applies to the exact SBOM serial number and version it names. Trivy skips statements whose BOM-Link does not match the SBOM it scans."
]

[[faq]]
q = "Where is VEX data in a CycloneDX document?"
a = "In the vulnerabilities array. Each vulnerability has an id, an affects list whose ref points at a component (by bom-ref in the same BOM or by BOM-Link to another BOM), and an analysis object with state, justification, response and detail."

[[faq]]
q = "What is the OpenVEX equivalent of CycloneDX false_positive?"
a = "There is none. CycloneDX defines false_positive as a vulnerability that was falsely identified or associated with the component. OpenVEX and CSAF have only not_affected, affected, fixed and under_investigation. Trivy maps false_positive to not_affected; a converter should do the same and keep the original state in the impact statement."

[[faq]]
q = "Does code_not_reachable mean the same as vulnerable_code_not_in_execute_path?"
a = "Close enough to map, in our reading. CycloneDX defines code_not_reachable as vulnerable code that is not invoked at runtime; OpenVEX's vulnerable_code_not_in_execute_path covers a product that includes the vulnerable code but does not call or use it."

[[faq]]
q = "Can Trivy read CycloneDX VEX?"
a = "Yes, as an experimental feature. Trivy's documentation says it supports only a separate VEX BOM alongside a CycloneDX SBOM, that BOM-Links must be placed in affects.ref, and that a not_affected state stops the vulnerability being reported."
+++

**Scope.** This is a field-level mapping guide. We compared the CycloneDX JSON schemas for 1.6 and 1.7 (identical enums for the fields below), OpenVEX specification v0.2.0 and its JSON schema, and the CSAF 2.0 JSON schema and VEX profile text from the OASIS TC repository, then read how Trivy (main branch, commit `1d1ab074`, November 2, 2026) consumes CycloneDX VEX. The converter below was run with Python 3.13; its output validated against the OpenVEX 0.2.0 JSON schema and its inputs against the CycloneDX 1.6 schema. Our [VEX explainer](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/) covers what the statuses mean and how far to trust them; this article is only about moving statements between formats.

## The short answer

If you receive CycloneDX VEX and your pipeline speaks OpenVEX or CSAF (or the reverse), the states map almost one-to-one, but the justifications do not.

| CycloneDX `analysis.state` | OpenVEX `status` | CSAF `product_status` | Trivy (code) |
| --- | --- | --- | --- |
| `not_affected` | `not_affected` | `known_not_affected` | not_affected |
| `false_positive` | `not_affected` (no exact match) | `known_not_affected` (no exact match) | not_affected |
| `exploitable` | `affected` | `known_affected` | affected |
| `in_triage` | `under_investigation` | `under_investigation` | under_investigation |
| `resolved` | `fixed` | `fixed` | fixed |
| `resolved_with_pedigree` | `fixed` (pedigree evidence is lost) | `fixed` | fixed |

Of CycloneDX's nine justifications, only `code_not_present` and `code_not_reachable` have a clear counterpart among the five CISA-derived labels that OpenVEX and CSAF share. Convert those two; carry the other seven as text.

## Where VEX sits in a CycloneDX document

CycloneDX has no separate VEX document type. VEX is the `vulnerabilities` array of a BOM, and the fields that matter are:

- `id`: the vulnerability identifier, such as a CVE ID.
- `affects[].ref`: what the statement is about. The schema allows a `bom-ref` in the same document or a BOM-Link element. A BOM-Link has the form `urn:cdx:serialNumber/version#bom-ref`, and the schema's pattern requires the serial number UUID, a version of 1 or more, and a fragment.
- `analysis.state`: one of `resolved`, `resolved_with_pedigree`, `exploitable`, `in_triage`, `false_positive`, `not_affected`.
- `analysis.justification`: one of nine reasons, described below.
- `analysis.response`: zero or more of `can_not_fix`, `will_not_fix`, `update`, `rollback`, `workaround_available`.
- `analysis.detail`: free text. The schema says that if a vulnerability is not exploitable, "this field should include specific details on why the component or service is not impacted."

A VEX statement can sit inside the SBOM itself or in a separate BOM that only has `vulnerabilities` and refers back to the SBOM by BOM-Link. That second pattern matters for tooling, below.

## States: four clean pairs and two lossy ones

The CycloneDX schema defines the six states in its `meta:enum`. Four map directly:

- `not_affected`: "The component or service is not affected by the vulnerability. Justification should be specified for all not_affected cases." This is OpenVEX `not_affected` and CSAF `known_not_affected`.
- `exploitable`: "The vulnerability may be directly or indirectly exploitable." This is OpenVEX `affected` and CSAF `known_affected`.
- `in_triage`: "The vulnerability is being investigated." This is `under_investigation` in both.
- `resolved`: "The vulnerability has been remediated." This is `fixed` in both.

Two lose meaning:

- **`false_positive`**: "The vulnerability is not specific to the component or service and was falsely identified or associated." OpenVEX and CSAF have no status for "the scanner was wrong". The safe target is `not_affected`, which is also what Trivy's `cdxStatus` function does (`case cdx.IASFalsePositive, cdx.IASNotAffected: return types.FindingStatusNotAffected`). Keep the word `false_positive` in the impact statement so a reviewer can see it.
- **`resolved_with_pedigree`**: remediated "and evidence of the changes are provided in the affected components pedigree". It becomes `fixed`, and the pointer to pedigree evidence is lost unless you keep it as text.

## Justifications: two of nine line up

OpenVEX's five justification labels come from CISA's June 2022 status-justification document, and the CSAF 2.0 schema's `flags[].label` uses the same five strings. CycloneDX defines a different set of nine. Here is each one with its CycloneDX definition and our reading of the closest OpenVEX/CSAF label.

| CycloneDX `justification` | CycloneDX definition | OpenVEX / CSAF label | Our call |
| --- | --- | --- | --- |
| `code_not_present` | "The code has been removed or tree-shaked." | `vulnerable_code_not_present` | Map |
| `code_not_reachable` | "The vulnerable code is not invoked at runtime." | `vulnerable_code_not_in_execute_path` | Map |
| `requires_dependency` | "Exploitability requires a dependency that is not present." | none exact (`component_not_present` means the vulnerable component itself is absent) | Text |
| `requires_configuration` | "Exploitability requires a configurable option to be set/unset." | none | Text |
| `requires_environment` | "Exploitability requires a certain environment which is not present." | none | Text |
| `protected_by_compiler` | "Exploitability requires a compiler flag to be set/unset." | none exact | Text |
| `protected_at_runtime` | "Exploits are prevented at runtime." | `inline_mitigations_already_exist` only if the protection cannot be disabled | Text |
| `protected_at_perimeter` | "Attacks are blocked at physical, logical, or network perimeter." | none | Text |
| `protected_by_mitigating_control` | "Preventative measures have been implemented that reduce the likelihood and/or impact of the vulnerability." | none | Text |

Why so strict? The OpenVEX spec defines `inline_mitigations_already_exist` as built-in protections that "cannot be subverted by the attacker and cannot be configured or disabled by the user." A CycloneDX `protected_at_runtime` or `protected_by_compiler` claim does not tell you that. `protected_at_perimeter` and `protected_by_mitigating_control` describe the deployment, not the product, and a mitigating control that "reduce[s] the likelihood and/or impact" is weaker than "not affected" in the CISA sense.

This mapping is our editorial reading of the published definitions. We did not find a mapping table published by the CycloneDX project or CISA.

OpenVEX gives you a way out: for `not_affected`, "a VEX statement MUST include either a status justification or an impact_statement." So you can emit a `not_affected` statement with no label and an impact statement that preserves the original CycloneDX reason. CSAF's VEX profile has the same escape hatch: each `known_not_affected` product needs either a machine-readable flag or a human-readable justification in `threats` with category `impact`.

## Responses and action statements

For affected products, both targets require an action:

- OpenVEX: for `affected`, "a VEX statement MUST include a statement that SHOULD describe actions to remediate or mitigate the vulnerability" (`action_statement`).
- CSAF VEX profile: for `known_affected`, "additional product specific information SHALL be provided in `/vulnerabilities[]/remediations` as an action statement."

CycloneDX's `response` values give you a starting point. `update` and `rollback` fit CSAF's `vendor_fix` remediation category, `workaround_available` fits `workaround`, and `will_not_fix` / `can_not_fix` fit `no_fix_planned` (or `none_available`), which the CSAF profile explicitly permits for an action statement. OpenVEX takes a free-text `action_statement`, so join the responses with `analysis.detail`. If an `exploitable` statement has neither a response nor detail, the converted statement will be valid but useless; send it back to the supplier.

## BOM-Link: the part that silently drops statements

A CycloneDX VEX BOM that references components by BOM-Link is bound to one SBOM version. Trivy's docs (v0.67) say the tool "only supports the Independent BOM and VEX BOM format, so you need to provide a separate VEX file alongside the SBOM," that "BOM-Links must be placed in `affects.ref`," and that the input SBOM must be CycloneDX. The usage example is `trivy sbom trivy.sbom.cdx --vex trivy.vex.cdx`. The feature is marked experimental.

Trivy's code adds a detail the docs do not spell out: if the BOM-Link's serial number or version does not equal the scanned SBOM's, it logs `URN doesn't match with SBOM` and skips the statement. Regenerate the SBOM (new serial number or version) without regenerating the VEX, and every suppression stops applying. That fails safe, since findings come back rather than disappear, but it surprises teams.

OpenVEX has no BOM-Link. Products are identified by an `@id` such as a Package URL, so a converter has to resolve each BOM-Link to the referenced component's `purl` in the SBOM. That is why the converter below takes both files.

## A tested converter: CycloneDX VEX to OpenVEX

This Python 3 script reads a CycloneDX SBOM and a separate CycloneDX VEX BOM and writes an OpenVEX 0.2.0 document. It maps states as in the first table, maps only the two clean justifications, and keeps everything else as text. It is illustrative, not production-ready: it does not handle version ranges in `affects[].versions`, services, or nested BOMs beyond `components`.

```python
#!/usr/bin/env python3
"""Convert a CycloneDX VEX BOM (independent VEX, BOM-Link refs) to OpenVEX v0.2.0.
Usage: python3 cdx2openvex.py sbom.cdx.json vex.cdx.json author > out.openvex.json"""
import json, sys, hashlib
from datetime import datetime, timezone

STATUS = {  # CycloneDX analysis.state -> OpenVEX status
    "not_affected": "not_affected", "false_positive": "not_affected",
    "exploitable": "affected", "in_triage": "under_investigation",
    "resolved": "fixed", "resolved_with_pedigree": "fixed",
}
# Only the pairs whose definitions line up; everything else is carried as text.
JUSTIFICATION = {
    "code_not_present": "vulnerable_code_not_present",
    "code_not_reachable": "vulnerable_code_not_in_execute_path",
}

def purls_by_ref(sbom):
    serial, version = sbom["serialNumber"], sbom.get("version", 1)
    out, stack = {}, list(sbom.get("components", []))
    while stack:
        c = stack.pop()
        if "bom-ref" in c and "purl" in c:
            out[f"urn:cdx:{serial.removeprefix('urn:uuid:')}/{version}#{c['bom-ref']}"] = c["purl"]
        stack.extend(c.get("components", []))
    return out

def convert(sbom, vex, author):
    refs, statements, problems = purls_by_ref(sbom), [], []
    for v in vex.get("vulnerabilities", []):
        a = v.get("analysis", {})
        state = a.get("state")
        if state not in STATUS:
            problems.append(f"{v['id']}: no analysis.state, skipped"); continue
        products = []
        for af in v.get("affects", []):
            purl = refs.get(af["ref"])
            if purl: products.append({"@id": purl})
            else: problems.append(f"{v['id']}: {af['ref']} not found in SBOM")
        if not products: continue
        s = {"vulnerability": {"name": v["id"]}, "products": products, "status": STATUS[state]}
        detail = a.get("detail", "").strip()
        if s["status"] == "not_affected":
            j = JUSTIFICATION.get(a.get("justification"))
            if j: s["justification"] = j
            note = f"CycloneDX state={state}, justification={a.get('justification', 'none')}"
            s["impact_statement"] = f"{note}. {detail}".strip()
        elif s["status"] == "affected":
            resp = ", ".join(a.get("response", [])) or "none given"
            s["action_statement"] = f"CycloneDX response: {resp}. {detail}".strip()
        statements.append(s)
    body = json.dumps(statements, sort_keys=True).encode()
    doc = {"@context": "https://openvex.dev/ns/v0.2.0",
           "@id": "https://example.com/vex/" + hashlib.sha256(body).hexdigest()[:16],
           "author": author,
           "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
           "version": 1, "statements": statements}
    return doc, problems

if __name__ == "__main__":
    sbom, vex = (json.load(open(p)) for p in sys.argv[1:3])
    doc, problems = convert(sbom, vex, sys.argv[3])
    json.dump(doc, sys.stdout, indent=2)
    for p in problems: print("WARN", p, file=sys.stderr)
```

### Test run

We fed it a three-component CycloneDX 1.6 SBOM (log4j-core 2.14.1, jackson-databind 2.13.0, snakeyaml 1.30) and a VEX BOM with four statements. The assessments in the VEX are invented test data, not real vendor findings:

1. CVE-2021-44228 on log4j-core: `not_affected`, `code_not_reachable`.
2. CVE-2022-42003 on jackson-databind: `not_affected`, `requires_configuration`.
3. CVE-2022-1471 on snakeyaml: `exploitable`, response `update`.
4. CVE-2021-44228 again, but with a BOM-Link naming SBOM version `2` instead of `1`.

Both input files passed `check-jsonschema` against the CycloneDX 1.6 schema. The run printed one warning to stderr and three statements; the output validated against `openvex_json_schema.json` (v0.2.0) with the Python `jsonschema` package:

```text
WARN CVE-2021-44228: urn:cdx:3e671687-395b-41f5-a30f-a58921a69b79/2#pkg-log4j not found in SBOM
```

The `statements` array of the output:

```json
[
{
  "vulnerability": { "name": "CVE-2021-44228" },
  "products": [ { "@id": "pkg:maven/org.apache.logging.log4j/log4j-core@2.14.1" } ],
  "status": "not_affected",
  "justification": "vulnerable_code_not_in_execute_path",
  "impact_statement": "CycloneDX state=not_affected, justification=code_not_reachable. JNDI lookups are never invoked; the app logs through SLF4J with Logback."
},
{
  "vulnerability": { "name": "CVE-2022-42003" },
  "products": [ { "@id": "pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.13.0" } ],
  "status": "not_affected",
  "impact_statement": "CycloneDX state=not_affected, justification=requires_configuration. The deserialization feature this issue depends on is disabled in our ObjectMapper configuration."
},
{
  "vulnerability": { "name": "CVE-2022-1471" },
  "products": [ { "@id": "pkg:maven/org.yaml/snakeyaml@1.30" } ],
  "status": "affected",
  "action_statement": "CycloneDX response: update. Dependency upgrade ships in release 4.2."
}
]
```

The second statement is the important one: it stays `not_affected` with no invented label, and the reason survives as text. The fourth input statement was dropped with a warning instead of being applied to the wrong SBOM.

## Common mistakes

- **Mapping every `protected_*` justification to `inline_mitigations_already_exist`.** That label claims the protection cannot be disabled. A WAF rule or a compiler flag can.
- **Dropping `false_positive` statements** because the target format has no matching status. Map them to `not_affected` and say why.
- **Dropping the `detail` text.** It is often the only evidence a reviewer has, and both OpenVEX and CSAF have a place for it.
- **Reusing a VEX BOM after regenerating the SBOM.** BOM-Links name an exact serial number and version.
- **Treating converted VEX as first-party.** Keep the original author. OpenVEX `author` should be the organization that made the assessment, not the converter.

## Where this fits

VEX is the "is my product actually affected" step in our [vulnerability prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/), after the CVE record and before KEV, SSVC and EPSS. The SBOM that the VEX points at is covered in our guide to [SBOM minimum elements in 2026](/posts/sbom-minimum-elements-2026-what-cisa-and-partners-changed-from-the-2021-ntia-baseline/). If you want a signal for which `exploitable` statements to fix first, our [CVSS vs EPSS vs KEV comparison](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/) covers the trade-offs.

## Limits of this article

The justification mapping is our reading of the published definitions; no standards body has published it. We read CSAF 2.0 from the OASIS TC's GitHub repository (schema and editor's draft prose) rather than the OASIS-hosted standard. We read Trivy's main branch, not a tagged release, and its docs for v0.67; behaviour may differ in the version you run. We did not run Trivy itself or test the reverse conversion (OpenVEX or CSAF to CycloneDX), which is harder because CycloneDX `affects` needs a component reference the OpenVEX product may not resolve to.

## Sources and verification

| Important claim | Source | Status |
| --- | --- | --- |
| CycloneDX states, justifications, responses and their definitions; detail field; BOM-Link pattern | [CycloneDX bom-1.6 / bom-1.7 JSON schemas](https://github.com/CycloneDX/specification/tree/master/schema) | Verified |
| BOM-Link syntax `urn:cdx:serialNumber/version#bom-ref` | [CycloneDX BOM-Link](https://www.cyclonedx.org/capabilities/bomlink/) | Verified |
| OpenVEX statuses, five justifications, justification or impact_statement rule, action_statement rule | [OpenVEX spec v0.2.0](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md) | Verified |
| CSAF product_status categories, flag labels, remediation categories | [CSAF 2.0 JSON schema](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/json_schema/csaf_json_schema.json) | Verified |
| CSAF VEX profile requirements for known_not_affected and known_affected | [CSAF 2.0 prose, section 4.5](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/prose/csaf-v2-editor-draft.md) | Qualified (TC repository draft text) |
| Trivy maps false_positive to not_affected and skips BOM-Links that do not match the SBOM | [Trivy pkg/vex/cyclonedx.go](https://github.com/aquasecurity/trivy/blob/main/pkg/vex/cyclonedx.go) | Verified (main branch, 2026-11-02) |
| Trivy CycloneDX VEX: separate VEX BOM, BOM-Link in affects.ref, CycloneDX SBOM only, experimental | [Trivy docs: VEX file](https://trivy.dev/docs/latest/supply-chain/vex/file) | Verified |
| Converter output and schema validation | Our run, Python 3.13, jsonschema, check-jsonschema | Verified (code) |
