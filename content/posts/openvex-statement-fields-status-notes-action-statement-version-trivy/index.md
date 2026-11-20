+++
title = "OpenVEX Statement Fields: What Trivy and go-vex Ignore"
date = 2026-11-20T04:30:00Z
tags = ["vex", "openvex", "trivy", "go-vex", "vexctl", "vulnerability management", "sbom"]
categories = ["appsec"]
summary = "OpenVEX v0.2.0 defines 13 statement fields, but Trivy v0.76.2 acts on two of them: status and justification, from the matching statement with the newest timestamp. Here is what happens to status_notes, action_statement, last_updated, version and supplier, read from the go-vex v0.2.9 and Trivy source."
description = "OpenVEX statement fields Trivy acts on: status and justification only. status_notes, action_statement, last_updated are ignored; version and supplier dropped."
author = "John Marshall"
imageAlt = "Black-framed reading glasses resting on a printed document, the text blurred beneath the lenses"
imageCredit = "Photo by [Mari Helin](https://unsplash.com/photos/ilSnKT1IMxE) on Unsplash"
takeaways = [
  "Trivy v0.76.2 reads two fields from an OpenVEX statement: status (it suppresses only not_affected and fixed) and justification, which it copies into the Statement of a modified finding.",
  "status_notes, impact_statement, action_statement, action_statement_timestamp and last_updated are decoded by go-vex v0.2.9 but play no part in Trivy's decision.",
  "When several statements match, go-vex sorts them by timestamp only, falling back to the document timestamp. Bumping last_updated or a statement version does not make a statement win.",
  "go-vex v0.2.9 has no struct field for statement version or supplier, so tools built on it, such as vexctl add and merge, drop both when they rewrite a document.",
  "Trivy does not run go-vex's statement validation, so an affected statement without an action_statement, which the spec says MUST have one, still loads."
]

[[faq]]
q = "Which OpenVEX fields does Trivy use?"
a = "In Trivy v0.76.2, the products, subcomponents and vulnerability name decide whether a statement matches. Of the matching statements, Trivy takes the one with the newest timestamp and uses its status and justification. It suppresses the finding only for not_affected or fixed, and records the justification as the Statement of the modified finding."

[[faq]]
q = "Does last_updated change which OpenVEX statement wins?"
a = "Not in go-vex v0.2.9 or Trivy. SortStatements compares the statement timestamp, or the document timestamp when a statement has none. last_updated is decoded and written back, but not compared. To supersede a statement, add a new statement with a newer timestamp."

[[faq]]
q = "Why did my OpenVEX statement version disappear?"
a = "The OpenVEX spec defines an optional statement-level version, but the go-vex v0.2.9 Statement struct has no field for it. Go's JSON decoder discards unknown keys, so vexctl add, vexctl merge and other go-vex based tools write the document back without it. Statement supplier is dropped the same way."

[[faq]]
q = "Is action_statement required for affected status?"
a = "Yes, by the spec and the JSON schema: an affected statement MUST include one. go-vex's Statement.Validate rejects an affected statement without it, but Trivy does not call that check when it loads a VEX file. vexctl fills the field with the placeholder \"No action statement provided\" when you omit --action-statement."
+++

**Short answer:** OpenVEX v0.2.0 gives a statement 13 fields, from `status` and `justification` to `status_notes`, `action_statement`, `last_updated` and a statement-level `version`. Trivy v0.76.2, through the go-vex v0.2.9 library, acts on two of them once a statement matches: **`status`** and **`justification`**. It picks the winning statement by **`timestamp`** alone. Everything else is either decoded and ignored, or, for statement `version` and `supplier`, not decoded at all and lost when a go-vex tool rewrites the file.

That matters if you write VEX for your own images and expect a scanner to honour it. A field you set to change the outcome may have no effect, and a field you rely on as an audit trail may vanish on the next `vexctl add`.

This article reads the [OpenVEX v0.2.0 specification](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md), its [JSON schema](https://github.com/openvex/spec/blob/main/openvex_json_schema.json), [go-vex v0.2.9](https://github.com/openvex/go-vex/tree/v0.2.9) (the newest tag on November 20, 2026, and the version pinned in Trivy's go.mod) and [Trivy v0.76.2](https://github.com/aquasecurity/trivy/tree/v0.76.2). For what the statuses mean, start with [VEX explained](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/); for how products and purls match, see [OpenVEX products and subcomponents](/posts/openvex-products-subcomponents-purl-matching-trivy/).

## Field by field: spec, schema, go-vex, Trivy

| Statement field | Spec v0.2.0 | JSON schema | go-vex v0.2.9 | Trivy v0.76.2 |
| --- | --- | --- | --- | --- |
| `vulnerability` | required | required | decoded | matched against the finding ID |
| `products` / `subcomponents` | required for a complete statement, can be inherited | optional | decoded | matched against the scanned purls |
| `status` | required | required | decoded, validated by `Validate()` | **acts on it**: suppresses `not_affected` and `fixed` |
| `justification` | `not_affected` needs it or `impact_statement` | same rule (`anyOf`) | decoded | **copied** into the modified finding's `Statement` |
| `timestamp` | optional, inherits from the document | optional | decoded, **used to sort** | the newest matching statement wins |
| `last_updated` | optional | optional | decoded, not compared | ignored |
| `status_notes` | MAY | optional | decoded | ignored |
| `impact_statement` | alternative to `justification` | alternative | decoded | ignored |
| `action_statement` | MUST for `affected` | required for `affected` | decoded; `Validate()` enforces it | ignored, not validated |
| `action_statement_timestamp` | optional | optional | decoded | ignored |
| `version` (statement) | optional, "Defaults to zero" | integer, `minimum: 1` | **no struct field: dropped** | not seen |
| `supplier` (statement) | optional | (not listed) | **no struct field: dropped** | not seen |

"Ignored" means the field takes no part in whether Trivy suppresses a finding or in what it records about the suppression. The data is still in your file; it is just not consumed.

## How Trivy decides

Trivy's OpenVEX handler is short. In [`pkg/vex/openvex.go`](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/openvex.go), `NotAffected` asks go-vex for the matching statements, then:

```go
// Take the latest statement for a given vulnerability and product
// as a sequence of statements can be overridden by the newer one.
stmt := stmts[len(stmts)-1]
if stmt.Status == openvex.StatusNotAffected || stmt.Status == openvex.StatusFixed {
    modifiedFindings := types.NewModifiedFinding(vuln, findingStatus(stmt.Status), string(stmt.Justification), v.source)
    return modifiedFindings, true
}
```

Two consequences follow directly from that code:

1. **Only `status` changes the result.** `affected` and `under_investigation` leave the finding in place, whatever `action_statement` or `status_notes` say.
2. **Only `justification` is carried into the output.** The third argument to `NewModifiedFinding` becomes the `Statement` field of the finding listed under `ExperimentalModifiedFindings` in Trivy's JSON report. A `not_affected` statement that explains itself only with `impact_statement` is valid, yet Trivy records an empty `Statement` for it. If an auditor reads Trivy's report rather than your VEX file, the reasoning is gone.

## Which statement wins: timestamp, not last_updated or version

The list Trivy indexes into is sorted by go-vex's `SortStatements` in [`pkg/vex/statement.go`](https://github.com/openvex/go-vex/blob/v0.2.9/pkg/vex/statement.go). For statements about the same vulnerability it compares `Timestamp`, and a statement with no timestamp of its own uses the document's:

```go
iTime := stmts[i].Timestamp
if iTime == nil || iTime.IsZero() {
    iTime = &documentTimestamp
}
// ...
return iTime.Before(*jTime)
```

`last_updated` is never compared, and statement `version` does not exist in the struct. The sort is stable, so two statements with equal timestamps stay in file order and the later one wins.

This follows the spec, which defines `timestamp` as "the time at which the information expressed in the Statement was known to be true" and says a statement "is useless without a timestamp as it cannot be related to others talking about the same subject." The trap is editing a statement in place. If you change an old `not_affected` statement's text and bump its `last_updated` and `version`, it keeps its old `timestamp` and still loses to any newer statement for the same product and CVE.

The spec's own update example shows the safe pattern: keep the old statement unchanged with its original timestamp, and add a new statement that carries the new status and a newer timestamp (its own, or the bumped document timestamp it inherits). `vexctl add` does this for you, as covered in our [vexctl guide](/posts/vexctl-create-add-merge-attest-openvex-documents/).

## Statement version and supplier are dropped on rewrite

The spec lists `version` on the statement as an "Optional integer representing the statement's version number. Defaults to zero, required when incremented", and `supplier` as the "Supplier of the product or subcomponent." The go-vex v0.2.9 `Statement` struct has fields for `@id`, `vulnerability`, `timestamp`, `last_updated`, `products`, `status`, `status_notes`, `justification`, `impact_statement`, `action_statement` and `action_statement_timestamp`, and nothing else. Go's `encoding/json` discards keys it has no field for.

We checked the effect with a stdlib-only Go 1.24.7 program whose `Statement` struct copies go-vex v0.2.9's field set and JSON tags (with `products` and `vulnerability` held as raw JSON). Input:

```json
{"version":2,"supplier":"Example Corp","vulnerability":{"name":"CVE-2024-32002"},
 "timestamp":"2026-11-01T10:00:00Z","last_updated":"2026-11-20T08:00:00Z",
 "products":[{"@id":"pkg:oci/app@sha256:abc"}],"status":"affected",
 "status_notes":"Reachable from the upload handler","action_statement":"Upgrade git to 2.45.1",
 "action_statement_timestamp":"2026-11-20T08:00:00Z"}
```

Output after `json.Unmarshal` and `json.Marshal`:

```json
{"vulnerability":{"name":"CVE-2024-32002"},"timestamp":"2026-11-01T10:00:00Z","last_updated":"2026-11-20T08:00:00Z","products":[{"@id":"pkg:oci/app@sha256:abc"}],"status":"affected","status_notes":"Reachable from the upload handler","action_statement":"Upgrade git to 2.45.1","action_statement_timestamp":"2026-11-20T08:00:00Z"}
```

`version` and `supplier` are gone. Any tool that loads a document through go-vex and writes it back, including `vexctl add` and `vexctl merge`, will do the same. If your process uses statement `version` as a change counter, keep that history somewhere go-vex does not touch, such as the document `version` (which go-vex does keep) or your Git history.

The spec and schema also disagree slightly here: the spec says statement `version` defaults to zero, while the schema sets `minimum: 1`. A statement with an explicit `"version": 0` fails schema validation.

The openvex/go-vex main branch has an unreleased validator (commit 42a83ee, November 19, 2026) whose field table carries the same warning for both fields: "go-vex does not decode it; it is dropped when the document is rewritten." The vexctl main branch already wires it into a `vexctl validate` command; the latest vexctl release, v0.4.4, does not include it.

## action_statement: required by the spec, not checked by Trivy

The spec says an `affected` statement "MUST include a statement that SHOULD describe actions to remediate or mitigate the vulnerability," and the JSON schema makes `action_statement` required when `status` is `affected`. go-vex enforces this in `Statement.Validate()`:

```go
// action statement is now required
if v := stmt.ActionStatement; v == "" {
    return fmt.Errorf("action statement must be set when using status %q", s)
}
```

Trivy never calls it. Its `decodeOpenVEX` in [`pkg/vex/document.go`](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/document.go) runs `json.NewDecoder(r).Decode(&openVEX)` and only checks that `@context` is not empty. go-vex's own `Parse` also just unmarshals. A non-conforming `affected` statement loads without complaint, and since Trivy does not suppress `affected` findings, the scan output looks identical either way.

On the producer side, vexctl (v0.4.4 and main) sets the `--action-statement` flag's default to the go-vex constant `NoActionStatementMsg`, which is the string `"No action statement provided"`. An `affected` statement created without `-a` therefore passes validation with a placeholder that tells a reader nothing. Search your VEX files for that string before publishing them.

## A pre-publish check you can run

The script below flags the cases above. It is plain Python 3 with no dependencies; we ran it with Python 3 against the sample document that follows. It checks fields, not purl matching, so pair it with schema validation.

```python
#!/usr/bin/env python3
"""Flag OpenVEX v0.2.0 statement fields that Trivy v0.76.2 / go-vex v0.2.9 will not act on."""
import json, sys
from datetime import datetime

def ts(v):
    return datetime.fromisoformat(v.replace("Z", "+00:00")) if v else None

doc = json.load(open(sys.argv[1]))
doc_ts = doc.get("timestamp")
for i, s in enumerate(doc.get("statements", [])):
    where = f"statements[{i}] {s.get('vulnerability', {}).get('name')} {s.get('status')}"
    st = s.get("status")
    if "version" in s:
        print(f"{where}: statement 'version' is dropped when go-vex tools rewrite the file")
    if "supplier" in s:
        print(f"{where}: statement 'supplier' is dropped when go-vex tools rewrite the file")
    if st == "affected" and not s.get("action_statement"):
        print(f"{where}: affected without action_statement (spec MUST; Trivy loads it anyway)")
    if st == "affected" and s.get("action_statement") == "No action statement provided":
        print(f"{where}: action_statement is the vexctl placeholder")
    if st == "not_affected" and not s.get("justification"):
        print(f"{where}: not_affected with impact_statement only; Trivy reports an empty Statement")
    eff = ts(s.get("timestamp") or doc_ts)
    lu = ts(s.get("last_updated"))
    if lu and eff and lu > eff:
        print(f"{where}: last_updated {s['last_updated']} is newer than the timestamp used for ordering ({eff.isoformat()})")
```

Sample document (illustrative names and digest). The author edited the second statement on November 19, bumping `last_updated` and `version`, and expects `not_affected` to win:

```json
{
  "@context": "https://openvex.dev/ns/v0.2.0",
  "@id": "https://example.com/vex/app-2026-11-20",
  "author": "Example Corp Product Security",
  "timestamp": "2026-11-20T08:00:00Z",
  "version": 3,
  "statements": [
    {
      "vulnerability": {"name": "CVE-2024-32002"},
      "products": [{"@id": "pkg:oci/app@sha256:abc"}],
      "status": "affected",
      "timestamp": "2026-11-01T10:00:00Z",
      "action_statement": "No action statement provided"
    },
    {
      "version": 2,
      "vulnerability": {"name": "CVE-2024-32002"},
      "products": [{"@id": "pkg:oci/app@sha256:abc"}],
      "status": "not_affected",
      "timestamp": "2026-10-15T10:00:00Z",
      "last_updated": "2026-11-19T12:00:00Z",
      "impact_statement": "The vulnerable clone path is never called"
    }
  ]
}
```

Output:

```text
statements[0] CVE-2024-32002 affected: action_statement is the vexctl placeholder
statements[1] CVE-2024-32002 not_affected: statement 'version' is dropped when go-vex tools rewrite the file
statements[1] CVE-2024-32002 not_affected: not_affected with impact_statement only; Trivy reports an empty Statement
statements[1] CVE-2024-32002 not_affected: last_updated 2026-11-19T12:00:00Z is newer than the timestamp used for ordering (2026-10-15T10:00:00+00:00)
```

By go-vex's sort, the `affected` statement (timestamp November 1) is newer than the `not_affected` one (October 15), so Trivy keeps reporting the CVE. The fix is a new `not_affected` statement with a current timestamp and a `justification` label, not an edit to the old one.

## What to do

- **Supersede, do not edit.** Add a new statement with a newer `timestamp` for every status change. Treat `last_updated` as a note for humans.
- **Always set `justification` on `not_affected`.** Use `impact_statement` as extra detail, not as the only explanation, if a scanner report is what auditors see.
- **Write real action statements.** Reject `"No action statement provided"` in CI. Trivy will not use the text, but customers and your own triage queue will.
- **Keep statement `version` and `supplier` out of go-vex round trips,** or accept that they will be lost. Put supplier data on the product or subcomponent purl instead.
- **Validate against the schema in CI.** Neither Trivy nor go-vex's `Parse` will reject a non-conforming file for you. The `openvex_json_schema.json` file catches the missing `action_statement` and a statement `version` of 0.

VEX is one input to the patch decision, alongside KEV, EPSS and SSVC. Our [vulnerability prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/) shows where a `not_affected` statement should close a ticket, and where it should not.

## Limits of this article

This describes Trivy v0.76.2 and go-vex v0.2.9 as of November 20, 2026, read from source; we did not run Trivy itself. Other consumers (Grype, Docker Scout, vendor platforms) may read `status_notes` or `action_statement`, or sort on different fields. The go-vex validator and `vexctl validate` mentioned above are unreleased and may change before a tagged release. The Go round-trip test used a copy of go-vex's struct definition, not the library itself.

## Sources and verification

| Important claim | Source | Status |
| --- | --- | --- |
| Statement field list, MUST/MAY wording, timestamp inheritance, update example | [OpenVEX spec v0.2.0](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md) | Verified |
| `action_statement` required for `affected`; statement `version` minimum 1 | [openvex_json_schema.json](https://github.com/openvex/spec/blob/main/openvex_json_schema.json) | Verified |
| Statement struct fields; `SortStatements` compares timestamps only; `Validate()` rules | [go-vex v0.2.9 statement.go](https://github.com/openvex/go-vex/blob/v0.2.9/pkg/vex/statement.go) | Verified |
| Trivy takes the last matching statement, suppresses only `not_affected`/`fixed`, passes `justification` as Statement | [Trivy v0.76.2 openvex.go](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/openvex.go), [finding.go](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/types/finding.go) | Verified |
| Trivy decodes OpenVEX without validation; pins go-vex v0.2.9 | [Trivy v0.76.2 document.go](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/document.go), [go.mod](https://github.com/aquasecurity/trivy/blob/v0.76.2/go.mod) | Verified |
| vexctl's default action statement placeholder | [vexctl options.go](https://github.com/openvex/vexctl/blob/v0.4.4/internal/cmd/options.go), [go-vex vex.go](https://github.com/openvex/go-vex/blob/v0.2.9/pkg/vex/vex.go) | Verified |
| Unreleased validator warns that statement `version` and `supplier` are dropped | [go-vex main pkg/validate/schema.go](https://github.com/openvex/go-vex/blob/main/pkg/validate/schema.go) | Qualified (unreleased) |
| `version` and `supplier` dropped on a JSON round trip | Our Go 1.24.7 test with a copy of the go-vex struct | Verified (reproduction, not the library) |
