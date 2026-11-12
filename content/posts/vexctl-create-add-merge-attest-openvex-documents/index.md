+++
title = "vexctl: Create, Add, Merge and Attest OpenVEX Documents"
date = 2026-11-12T04:40:00Z
tags = ["vex", "openvex", "vexctl", "sigstore", "in-toto", "sbom", "supply chain security", "vulnerability management"]
categories = ["appsec"]
summary = "A source-checked guide to vexctl v0.4.4: the create, add, merge and attest commands, the validation rules they enforce, why merge keeps every statement instead of resolving them, and the defaults that quietly produce weak VEX documents."
description = "vexctl creates OpenVEX documents, appends statements with add, merges them as a timeline and wraps them in in-toto attestations. Flags and pitfalls in v0.4.4."
author = "Craig Leslie"
imageAlt = "Tall stacks of paper documents and green and brown file folders with yellow-edged pages on an office desk under ceiling lights"
imageCredit = "Photo by [Wesley Tingey](https://unsplash.com/photos/stacks-of-paper-documents-and-file-folders-snNHKZ-mGfE) on Unsplash"
takeaways = [
  "vexctl v0.4.4 (tagged June 2026) has four commands that matter for producers: create (one statement, new document), add (append a statement, bump version), merge (combine documents) and attest (wrap a document in an in-toto attestation).",
  "Set --author on every command. The default is the literal string \"Unknown Author\", and the OpenVEX spec says author must identify an individual or organization.",
  "For status affected, --action-statement defaults to \"No action statement provided\", which satisfies the validator but tells consumers nothing. Always pass -a with real remediation text.",
  "vexctl merge does not resolve conflicts. It copies every matching statement into one document, sorted by vulnerability name and then timestamp; consumers then take the latest statement per product and vulnerability.",
  "vexctl attest uses predicate type https://openvex.dev/ns/v0.2.0, takes subjects from oci purls or hashes in the document, and --attach always implies --sign."
]

[[faq]]
q = "What is vexctl used for?"
a = "vexctl is the OpenVEX project's command-line tool for creating VEX documents, appending statements to them, merging several documents, wrapping a document in a signed in-toto attestation and filtering SARIF scanner results with VEX data."

[[faq]]
q = "Does vexctl merge pick the newest status?"
a = "No. In v0.4.4 the merge command keeps every statement that matches the optional --product and --vuln filters and sorts them by vulnerability name, then timestamp. The newest statement wins only when a consumer applies the OpenVEX rule of reading the latest statement for a product and vulnerability."

[[faq]]
q = "How do I add a statement to an existing OpenVEX document?"
a = "Use vexctl add with the document path, product, vulnerability and status, for example vexctl add --in-place doc.vex.json pkg:... CVE-... fixed. It appends the statement, increments the document version, sets last_updated and refuses to add a statement dated earlier than existing ones."

[[faq]]
q = "Why does vexctl attest skip some products?"
a = "Attestation subjects need an image reference or a digest. vexctl converts oci purls to image references and keeps products with sha256 or sha512 hashes; other purls without hashes are skipped with a warning, or cause an error if you passed them explicitly as subjects."
+++

`vexctl` is the OpenVEX project's own tool for writing VEX (Vulnerability Exploitability eXchange) documents: `create` starts a document, `add` appends a statement and bumps the version, `merge` combines documents into one timeline, and `attest` wraps a document in an in-toto attestation you can sign and attach to an image. The commands are short. The defaults behind them are where weak VEX comes from: an anonymous author, a placeholder action statement, and a merge that resolves nothing.

This guide reads the [vexctl v0.4.4 source](https://github.com/openvex/vexctl/tree/v0.4.4) (the newest tag on November 12, 2026, committed June 16, 2026) and the [go-vex v0.2.8](https://github.com/openvex/go-vex/tree/v0.2.8) library it builds on. It fills the gap left by our [Trivy `--vex oci` guide](/posts/trivy-vex-oci-openvex-attestations-cosign-attest/): Trivy consumes VEX but does not write it. If you need the basics of what a statement asserts, start with [what a not_affected statement means](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/).

## Install and version check

The [README](https://github.com/openvex/vexctl/blob/v0.4.4/README.md) gives two install routes:

```bash
go install github.com/openvex/vexctl@latest   # or pin: @v0.4.4
brew install vexctl
```

v0.4.4's `go.mod` requires Go 1.26.4, `github.com/openvex/go-vex v0.2.8` and `github.com/sigstore/cosign/v2 v2.6.3`. Pin the version in CI: the behaviour below is read from that tag, and a few help texts in it are out of step with the code (covered under merge).

## vexctl create: one statement, new document

`create` takes positional arguments or flags (`create [flags] [product_id [vuln_id [status]]]`):

```bash
vexctl create \
  --author="Example Corp PSIRT <psirt@example.com>" \
  --product="pkg:oci/api-gateway@sha256:<digest>?repository_url=registry.example.com/team" \
  --vuln="CVE-2026-12345" \
  --status="not_affected" \
  --justification="vulnerable_code_not_in_execute_path" \
  --impact-statement="The parser that contains the flaw is never loaded by this image." \
  --file=api-gateway.vex.json
```

*Illustrative: the command and flag names are taken from the v0.4.4 source; we did not run the binary for this article.*

The flags that shape the statement, from `internal/cmd/options.go`:

| Flag | Short | Default | Notes |
|---|---|---|---|
| `--product` | `-p` | none | Repeatable. At least one is required. A purl or other IRI. |
| `--vuln` | `-v` | none | Required. |
| `--status` | `-s` | none | `not_affected`, `affected`, `fixed` or `under_investigation`. |
| `--justification` | `-j` | none | Only allowed with `not_affected`. `vexctl list` prints the valid labels. |
| `--impact-statement` | | none | Only allowed with `not_affected`. |
| `--action-statement` | `-a` | `No action statement provided` | Only kept when status is `affected`. |
| `--status-note` | | none | How the status was determined. |
| `--aliases` | | none | Other IDs (GHSA, GO-...). Duplicates, or an alias equal to `--vuln`, are rejected. |
| `--subcomponents` | | none | Rejected when more than one `--product` is given. |
| `--author` | | `Unknown Author` | Document author. |
| `--author-role` | | empty | Optional. |
| `--id` | | generated | Generated from the document's canonical hash when omitted. |
| `--file` | | stdout | Output path. |

Two validation layers apply. vexctl's own checks (above) run first; then go-vex's statement validator enforces the [OpenVEX spec](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md) rules: a `not_affected` statement needs a `justification` or an `impact_statement`, and an `affected` statement needs an `action_statement`. The spec words them as MUSTs: "For statements conveying a `not_affected` status, a VEX statement MUST include either a status justification or an impact_statement", and "For a statement with 'affected' status, a VEX statement MUST include a statement that SHOULD describe actions to remediate or mitigate the vulnerability."

### Two defaults to override every time

**The author.** go-vex sets `DefaultAuthor = "Unknown Author"`, and vexctl's validator only rejects a *blank* author, so the placeholder passes. The spec says `author` "MUST be an individual or organization". A consumer that weighs VEX by issuer cannot trust an anonymous statement, so pass `--author` on `create`, `add` and `merge`.

**The action statement.** The `-a` flag defaults to `No action statement provided`. For an `affected` statement that default fills the required field, so the validator is satisfied and the document carries no remediation advice. Write the real action (upgrade target, configuration change, compensating control) every time.

### Reproducible timestamps

`create` and `add` honour `SOURCE_DATE_EPOCH`; the help text says it may be "formatted in UNIX time or RFC3339". Set it in release pipelines so a rebuilt document gets the same timestamp and, with the default ID, the same `@id`. go-vex serializes statement timestamps in UTC.

## vexctl add: append and bump the version

The spec says a document's `version` "must be incremented when any content within the VEX document changes". `add` does that for you:

```bash
vexctl add --in-place api-gateway.vex.json \
  "pkg:oci/api-gateway@sha256:<digest>?repository_url=registry.example.com/team" \
  CVE-2026-23456 under_investigation
```

*Illustrative.* Per `internal/cmd/add.go`, `add`:

- reads the document from the first positional argument or `-d/--document`, and writes to stdout unless you pass `-i/--in-place` or `--file`;
- copies the document's `last_updated` (or `timestamp`) into any statement that has no timestamp of its own, so those statements keep their inherited date once the document changes;
- refuses the new statement if any existing statement's `timestamp` or `last_updated` is later than the new time ("date cannot be older than other statements");
- appends the statement, sets the document's `last_updated` and increments `version`.

The time check matters with `SOURCE_DATE_EPOCH`: an epoch older than the newest statement makes `add` fail rather than write an out-of-order history.

## vexctl merge: a timeline, not a verdict

`merge` exists for the case the README describes, "when more than one stakeholder is issuing VEX metadata about a piece of software":

```bash
vexctl merge --author="Example Corp PSIRT" \
  --product="pkg:apk/wolfi/bash@1.0.0" \
  examples/openvex/document1.vex.json examples/openvex/document2.vex.json > merged.vex.json
```

What it does, from `Merge()` in `pkg/ctl/implementation.go`:

1. **Filters, optionally.** With `--product` and/or `--vuln`, only matching statements are kept. Product matching is go-vex's, which compares purls rather than plain strings.
2. **Fills timestamps.** A statement without a timestamp takes its source document's timestamp. If both are missing, merge fails: "unable to cascade timestamp from doc to timeless statement".
3. **Keeps everything.** Every matching statement is copied. There is no deduplication and no conflict resolution.
4. **Sorts.** Statements are sorted by vulnerability name (string order), then by timestamp, oldest first.
5. **Names the result deterministically.** Without `--id`, the new `@id` is `merged-vex-` plus the SHA-256 of the input documents' `@id` values, sorted and joined with `:`. A document with no `@id` contributes `VEX-DOC-<position>`.
6. **Starts a fresh document.** Version 1, a new timestamp, and `Unknown Author` unless you pass `--author`.

Who wins? Not merge. go-vex's `EffectiveStatement()` returns the *last* matching statement after the same sort, so the newest statement for a product and vulnerability is the current status. That is how the README explains a merged history of `under_investigation` followed by `fixed`: tools "replay" the statements in order.

We ported steps 1 to 5 to Python (product matching simplified to exact strings) and ran the port on the two example documents in the vexctl repository:

```text
$ python3 -I merge_port.py document2.vex.json document1.vex.json
merged-vex-6b33f63783819578804350ba1cde277ddd8f90aa2bbcb706d19a61d211a8443f
2023-12-05T05:04:34.77929922Z CVE-1234-5678 under_investigation
2023-12-05T05:06:38.099731287Z CVE-1234-5678 fixed
effective: fixed
```

Passing the files in the other order produced the same `@id`, because the IDs are sorted before hashing. That is a property of the port matching the source; treat it as a reading aid, not a test of the vexctl binary.

### Merge pitfalls

- **Clock skew decides conflicts.** Two issuers stating different statuses for the same product rely on their timestamps alone. A supplier's `not_affected` with a later clock beats your own `affected`. Merge per issuer, or review conflicts before publishing.
- **Output is stdout only.** `merge` registers no `--file` flag in v0.4.4; redirect the output.
- **The flag is `--vuln`.** The command's own help example shows `--vulnerability=CVE-2022-3294`, but the flag registered in v0.4.4 is `--vuln` (constant `vulnLongFlag = "vuln"`). Use `--vuln`.
- **Merged documents grow.** History is kept, so a long-lived merged file accumulates every status change. That is by design; prune by publishing a new document rather than editing statements in place.

## vexctl attest: wrap, sign, attach

```bash
vexctl attest api-gateway.vex.json                      # unsigned in-toto statement to stdout
vexctl attest --sign api-gateway.vex.json               # sign with the sigstore flow
vexctl attest --attach api-gateway.vex.json             # sign and attach to each image subject
vexctl attest --attach api-gateway.vex.json registry.example.com/team/api-gateway@sha256:<digest>
```

*Illustrative.* From `internal/cmd/attest.go` and `pkg/ctl/ctl.go`:

- The predicate is the OpenVEX document; go-vex sets the predicate type to `https://openvex.dev/ns/v0.2.0`.
- Without positional image arguments, subjects come from the document's products. `pkg:oci` purls become image references (the help text's example: `pkg:oci/kube-apiserver?repository_url=registry.k8s.io&tag=v1.26.0` becomes `registry.k8s.io/kube-apiserver:v1.26.0`), and references without a digest "will trigger a network lookup to read the image digest from the registry".
- Products that are neither oci purls nor image references are kept only if they carry `sha256` or `sha512` hashes. Otherwise they are skipped with a warning, or rejected with an error if you named them explicitly.
- `--attach` (`-a`) "always implies --sign as sigstore does not support attaching unsigned attestations". `--refs` (`-r`) names the images to attach to when automatic attachment fails.

If your scanner reads the attestation from the registry, check the predicate type it accepts. Our [Trivy `--vex oci` guide](/posts/trivy-vex-oci-openvex-attestations-cosign-attest/) covers how Trivy matches OpenVEX predicate types and why you should verify the signature yourself before trusting what it finds.

## Where vexctl fits in a patch-decision flow

VEX is the last filter before a finding becomes work: a `not_affected` statement with a sound justification closes a scanner finding that KEV, EPSS or CVSS would otherwise push up the queue. Our [vulnerability prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/) shows where that step sits between the CVE record and the ticket. Product IDs are where most VEX fails in practice, so check the matching rules in our [OpenVEX products and subcomponents guide](/posts/openvex-products-subcomponents-purl-matching-trivy/) before you publish, and see the [CycloneDX VEX mapping](/posts/cyclonedx-vex-analysis-state-justification-openvex-csaf-mapping/) if your consumers expect CycloneDX.

Two more commands exist and are out of scope here: `vexctl filter` applies VEX to SARIF results (the README says "We support results files in SARIF for now"), and `vexctl generate` builds documents from "golden" template files (default directory `.openvex/templates`).

## Limits of this article

- We read the v0.4.4 source and README; we did not run the vexctl binary. Commands are marked illustrative. The merge output comes from a Python port of the merge and sort logic, not from vexctl.
- Behaviour may change after v0.4.4. Re-check flags with `vexctl <command> --help` against the version you install.
- vexctl writes OpenVEX only. CSAF and CycloneDX VEX producers follow their own formats.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| v0.4.4 is the newest tag; dependency versions | [vexctl v0.4.4 go.mod](https://github.com/openvex/vexctl/blob/v0.4.4/go.mod), git tags | Verified |
| Flags, defaults and validation rules | [internal/cmd/options.go](https://github.com/openvex/vexctl/blob/v0.4.4/internal/cmd/options.go), [go-vex vex.go](https://github.com/openvex/go-vex/blob/v0.2.8/pkg/vex/vex.go) | Verified |
| add version bump and time checks | [internal/cmd/add.go](https://github.com/openvex/vexctl/blob/v0.4.4/internal/cmd/add.go) | Verified |
| Merge filters, keeps, sorts and hashes IDs | [pkg/ctl/implementation.go](https://github.com/openvex/vexctl/blob/v0.4.4/pkg/ctl/implementation.go), [go-vex statement.go](https://github.com/openvex/go-vex/blob/v0.2.8/pkg/vex/statement.go) | Verified (source); example run via Python port |
| Latest statement is the effective one | [go-vex vex.go EffectiveStatement](https://github.com/openvex/go-vex/blob/v0.2.8/pkg/vex/vex.go) | Verified |
| Attest predicate type and subject rules | [internal/cmd/attest.go](https://github.com/openvex/vexctl/blob/v0.4.4/internal/cmd/attest.go), [pkg/ctl/ctl.go](https://github.com/openvex/vexctl/blob/v0.4.4/pkg/ctl/ctl.go), [go-vex attestation](https://github.com/openvex/go-vex/tree/v0.2.8/pkg/attestation) | Verified |
| Spec MUSTs for author, version, justification, action statement | [OpenVEX specification](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md) | Verified |
