+++
title = "OpenVEX Products and Subcomponents: purl Matching Rules"
date = 2026-11-06T04:40:00Z
tags = ["openvex", "vex", "purl", "sbom", "trivy", "supply chain", "vulnerability management"]
categories = ["appsec"]
summary = "An OpenVEX statement suppresses a finding only when its products, subcomponents and purls line up with what the scanner found. Here is how the go-vex library behind Trivy v0.76.2 matches them: versionless purls, qualifier subsets, subcomponent scoping, timestamp inheritance and which status wins, with a schema-valid example document and a tested Python port of the rules."
description = "OpenVEX products and subcomponents decide which findings a VEX statement suppresses. How go-vex and Trivy match purls, versions, qualifiers and timestamps."
author = "Craig Leslie"
imageAlt = "Three weathered wooden crates side by side on a white counter in front of a white brick wall"
imageCredit = "Photo by [Jonathan Kemper](https://unsplash.com/photos/a-couple-of-wooden-crates-sitting-on-top-of-a-counter-oy0P04JuhOM) on Unsplash"
takeaways = [
  "In OpenVEX v0.2.0 the product is the software the statement is about and subcomponents are where the vulnerability originates, usually its dependencies. Both are matched by @id, by the identifiers map (purl, cpe22, cpe23) or by hashes.",
  "go-vex v0.2.9, which Trivy v0.76.2 uses, treats the purl in the VEX document as the general pattern: no version matches every version, and every qualifier it lists must appear in the scanned purl with the same value. Extra qualifiers on the scanned side are ignored.",
  "A product with no subcomponents matches regardless of which package carries the CVE. Listing subcomponents narrows the statement to findings in those packages. That is the difference between suppressing a CVE across a whole image and suppressing it in one package.",
  "When several statements match, statements are sorted by timestamp, a statement without one inherits the document timestamp, and the newest wins. Trivy suppresses only when that winner is not_affected or fixed.",
  "Trivy walks from the vulnerable package up through every parent in its dependency graph. A statement on an intermediate module only suppresses the finding if every path to the root passes through a not-affected node."
]

[[faq]]
q = "What is a subcomponent in OpenVEX?"
a = "The OpenVEX spec defines subcomponents as any components possibly included in the product where the vulnerability originates. They are usually the product's dependencies, they should carry software identifiers such as purls, and they should also appear in the product's SBOM."

[[faq]]
q = "Does an OpenVEX purl without a version match all versions?"
a = "In go-vex v0.2.9 and Trivy v0.76.2, yes. If the purl in the VEX document has no version, it matches any version of the same type, namespace and name. If it has a version, the scanned purl must have exactly that version; there is no version-range support."

[[faq]]
q = "Why does Trivy ignore my OpenVEX statement?"
a = "The most common causes are a purl that differs in type, namespace or name; a qualifier in the VEX purl (such as arch or repository_url) that the scanned purl lacks or has with another value; a version in the VEX purl that differs from the installed one; or a newer matching statement whose status is affected or under_investigation."

[[faq]]
q = "Which statement wins when an OpenVEX document has several for the same CVE?"
a = "go-vex sorts matching statements by timestamp, using the document timestamp for statements that have none, and Trivy applies the last one. That is why a new statement added to an existing document should keep older statements' original timestamps, as the OpenVEX spec's update example shows."
+++

An OpenVEX statement only changes a scanner's output if its **product**, its **subcomponents** and the **purls** inside them match what the scanner found. In the go-vex library that Trivy v0.76.2 uses, the rules are short: the VEX purl is a pattern (no version means every version, and every qualifier it lists must be present), subcomponents narrow a statement to specific packages, and among matching statements the one with the newest timestamp wins. Most "VEX didn't work" tickets come down to one of those three.

This article is about the identifiers and the matching. For what the statuses and justifications mean, see [VEX explained](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/). For converting CycloneDX VEX to OpenVEX, see the [CycloneDX VEX mapping](/posts/cyclonedx-vex-analysis-state-justification-openvex-csaf-mapping/). For CSAF's product tree, see [CSAF VEX product_tree](/posts/csaf-vex-product-tree-product-status-purl-sbom-matching/).

## Products and subcomponents in the spec

The [OpenVEX specification v0.2.0](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md) defines a product as "a logical unit representing a piece of software", broad enough that "anything that can be described in a Software Bill of Materials (SBOM) can be thought of as a product." A subcomponent is "any components possibly included in the product where the vulnerability originates." The spec adds that subcomponents "SHOULD also list software identifiers and they SHOULD also be listed in the product SBOM."

Products and subcomponents share one structure, which the spec calls `Component`:

| Field | Required | What it holds |
| --- | --- | --- |
| `@id` | No | An IRI for the component. A purl is a valid IRI, so `@id` can be a purl. |
| `identifiers` | No | A map of identifier type to value. The spec lists `purl`, `cpe22` and `cpe23`, and recommends purls. |
| `hashes` | No | A map of hash algorithm to digest, using IANA hash names. |
| `subcomponents` | No (products only) | A list of components the statement is scoped to. |

All three identifying fields are optional, but the spec says a valid statement "MUST identify a product." It also says the product should list "as many software identifiers as possible to help VEX processors when matching the product."

`products` itself is optional in a statement because it can be inherited from an encapsulating document, such as the subject of an in-toto attestation. Timestamps can be inherited too. The spec's inheritance rules are: a statement timestamp overrides the document timestamp, which overrides the encapsulating document's; a product ID in a statement overrides product data in the encapsulating document.

## How go-vex matches a statement

Trivy loads OpenVEX documents with [openvex/go-vex](https://github.com/openvex/go-vex), pinned to v0.2.9 in Trivy v0.76.2's `go.mod`. Its matching code is small enough to read in full. For a finding (CVE, product, optional subcomponent), a statement matches when all of these hold:

1. **Vulnerability.** The CVE ID equals the statement's `vulnerability.name`, its `@id`, or one of its `aliases`.
2. **Product.** One entry in `products` matches the product identifier. A component matches if its `@id` equals the identifier exactly, or its `@id` is a purl that matches by the purl rules below, or any value in `identifiers` equals it (with purl matching for the `purl` key), or any value in `hashes` equals it.
3. **Subcomponent.** If that product entry has no `subcomponents`, or the caller passed no subcomponent, the product match is enough. Otherwise one listed subcomponent must match the subcomponent identifier by the same component rules.

### The purl rules

go-vex's `PurlMatches(purl1, purl2)` treats the VEX purl as the general one and the scanned purl as the specific one:

| VEX purl | Scanned purl | Match? | Rule |
| --- | --- | --- | --- |
| `pkg:apk/alpine/git` | `pkg:apk/alpine/git@2.43.0-r0?arch=x86_64` | Yes | No version in the VEX purl matches any version |
| `pkg:apk/alpine/git@2.43.0-r0` | `pkg:apk/alpine/git@2.43.0-r1` | No | Versions must be equal when both are set |
| `pkg:apk/alpine/git@2.43.0-r0` | `pkg:apk/alpine/git` | No | A versioned VEX purl never matches a versionless scan result |
| `pkg:oci/app?repository_url=ghcr.io%2Facme%2Fapp` | `pkg:oci/app?repository_url=ghcr.io%2Facme%2Fapp&tag=v2` | Yes | Extra qualifiers on the scanned side are ignored |
| `pkg:oci/app?repository_url=ghcr.io%2Facme%2Fapp` | `pkg:oci/app` | No | Every VEX qualifier must be present with the same value |
| `pkg:apk/alpine/git` | `pkg:apk/alpine/git-daemon@2.43.0-r0` | No | Type, namespace and name must be equal |

The function's own comment says "Purl version ranges are not supported yet." A statement covering versions 1.0 to 1.4 needs either one purl per version or no version at all. Leaving the version off is the broadest possible statement, so use it only when you mean every version. Trivy's documentation notes that these matching rules come from a community discussion, not from the purl specification.

### Which statement wins

go-vex collects every matching statement and sorts them by timestamp, using the document `timestamp` for any statement without its own. Trivy takes the last one. It removes the finding only if that statement's status is `not_affected` or `fixed`; `affected` and `under_investigation` leave the finding in the report.

This is why the spec's update example keeps the original document timestamp on the first statement when a second one is added. If you edit a document, bump `timestamp` and `version` at the document level, and the old statements lose their original time, the ordering of statements for the same CVE can change.

## A tested example

The document below has two statements for CVE-2024-32002 on a container image (the first `under_investigation` with its own timestamp, the second `not_affected` inheriting the newer document timestamp) and one statement for a Go service. It validates against the OpenVEX JSON schema (`openvex_json_schema.json` from the spec repository, checked with Python `jsonschema`).

```json
{
  "@context": "https://openvex.dev/ns/v0.2.0",
  "@id": "https://example.com/vex/app-2026-11-06",
  "author": "Example Security Team <security@example.com>",
  "timestamp": "2026-11-06T09:00:00Z",
  "version": 2,
  "statements": [
    {
      "vulnerability": {"name": "CVE-2024-32002"},
      "timestamp": "2026-11-01T10:00:00Z",
      "products": [
        {
          "@id": "pkg:oci/app?repository_url=ghcr.io%2Facme%2Fapp",
          "subcomponents": [{"@id": "pkg:apk/alpine/git"}]
        }
      ],
      "status": "under_investigation"
    },
    {
      "vulnerability": {"name": "CVE-2024-32002"},
      "products": [
        {
          "@id": "pkg:oci/app?repository_url=ghcr.io%2Facme%2Fapp",
          "subcomponents": [{"@id": "pkg:apk/alpine/git"}]
        }
      ],
      "status": "not_affected",
      "justification": "vulnerable_code_not_in_execute_path",
      "status_notes": "git is installed for build-time use only; the runtime entrypoint never invokes git clone."
    },
    {
      "vulnerability": {"name": "CVE-2023-0001"},
      "products": [
        {
          "@id": "pkg:golang/example.com/svc@v1.4.0",
          "subcomponents": [{"@id": "pkg:golang/golang.org/x/net@v0.17.0"}]
        }
      ],
      "status": "not_affected",
      "justification": "vulnerable_code_not_present"
    }
  ]
}
```

The image, service names and CVE-2023-0001 statement are illustrative. To check the matching without a registry or a real image, we wrote a Python port of go-vex v0.2.9's `PurlMatches`, `Component.Matches`, `Product.Matches`, `Statement.Matches` and timestamp sort, using the `packageurl-python` parser, and ran it with Python 3 against the document. It is a port, not the Go library itself, so treat it as a reading aid. Output, with long purls shortened:

```text
product                                    subcomponent                          result
pkg:oci/app?repository_url=…%2Fapp         pkg:apk/alpine/git@2.43.0-r0?arch=…   2 matches, effective=not_affected
pkg:oci/app?repository_url=…%2Fapp         pkg:apk/alpine/git-daemon@2.43.0-r0   no match
pkg:oci/app?repository_url=…%2Fapp         (none)                                2 matches, effective=not_affected
pkg:oci/app                                pkg:apk/alpine/git@2.43.0-r0          no match
pkg:oci/app?repository_url=…%2Fapp&tag=v2  pkg:apk/alpine/git@2.43.0-r0          2 matches, effective=not_affected
pkg:golang/example.com/svc@v1.4.0          pkg:golang/golang.org/x/net@v0.17.0   1 match,  effective=not_affected
pkg:golang/example.com/svc@v1.5.0          pkg:golang/golang.org/x/net@v0.17.0   no match
pkg:golang/example.com/svc@v1.4.0          pkg:golang/golang.org/x/net@v0.18.0   no match
```

What the rows show:

- **Row 1:** the versionless `pkg:apk/alpine/git` subcomponent covers the installed `git@2.43.0-r0`. Both statements match, and the `not_affected` one wins because it inherits the later document timestamp.
- **Row 2:** `git-daemon` is a different package name, so the statement does not cover it, even though it ships from the same source.
- **Row 3:** with no subcomponent passed, the product match alone is enough. Trivy does not hit this case for an image root (see below), but other consumers of go-vex may.
- **Rows 4 and 5:** the `repository_url` qualifier on the VEX side must be present on the scanned side. A scan purl without it fails; one with an extra `tag` qualifier passes.
- **Rows 6 to 8:** pinned versions on both product and subcomponent mean a new service release (v1.5.0) or a dependency bump (x/net v0.18.0) silently drops the statement. That is often what you want, since the reachability analysis was for that build, but it means the document needs updating each release.

## How Trivy applies it to a dependency tree

Trivy's VEX guide and its `filterVulnerabilities` code show how it feeds this matcher. For each finding it first asks whether the vulnerable package itself is a not-affected product (no subcomponent). If not, it walks up the dependency graph from the vulnerable package and asks, for each parent, whether "parent as product, vulnerable package as subcomponent" is not affected. The finding is removed only if no path reaches the root without passing a not-affected node.

Two consequences:

- **A statement on an intermediate dependency can suppress a finding, but only if every path goes through it.** Trivy's documentation gives the example of Module C reached through both B and D: a VEX statement for B does not suppress the finding, because D might still be affected.
- **A statement on the image with no subcomponents suppresses the CVE in every package in that image.** Trivy's docs call this out and recommend subcomponents for "reducing the risk of incorrect filtering."

Trivy needs a purl on the scanned side. Its OpenVEX matcher returns nothing when the product has no purl, so cpe-only or hash-only VEX products are not matched by Trivy even though the spec allows them. Use the purls Trivy prints in its JSON report.

## Writing statements that match

These are our recommendations, based on the rules above:

1. **Copy purls from the scanner or SBOM output.** Do not type them by hand; the type, namespace and name must match exactly. Our guide to [CVE packageURL and SBOM purls](/posts/cve-packageurl-purl-cve-json-5-2-affected-sbom-matching/) covers common purl pitfalls.
2. **Always add subcomponents for image-level or application-level products.** A product with no subcomponents is a blanket statement.
3. **Add a version only when the claim depends on the build.** Reachability claims (`vulnerable_code_not_in_execute_path`) usually do. "This package never ships the vulnerable file" claims may not.
4. **Be sparing with qualifiers in the VEX purl.** Each one is a requirement. `arch` is useful if only one architecture is unaffected; otherwise leave it out.
5. **Keep timestamps on old statements when you append new ones,** and bump the document `version`. Use `status_notes` to record how the status was determined. Trivy does not read it, but reviewers do.
6. **Track the result.** Our [prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/) shows where a VEX decision sits between the CVE record and the ticket.

## Limits of this article

- Matching behaviour is from go-vex v0.2.9 and Trivy v0.76.2 source and docs. Grype, vexctl and commercial scanners have their own matchers and may differ.
- Our test used a Python port of the go-vex rules, not the Go library or a Trivy scan. The port follows the source shown in the references; differences in purl parsing between `packageurl-python` and `packageurl-go` are possible for unusual purls.
- We did not cover OpenVEX attestations attached to OCI images (`--vex oci`) or VEX repositories.

## Sources and verification

| Important claim | Source | Status |
| --- | --- | --- |
| Product, subcomponent, Component fields, identifier types, inheritance and update rules | [OpenVEX specification v0.2.0](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md) | Verified |
| Example document is schema-valid | [openvex_json_schema.json](https://github.com/openvex/spec/blob/main/openvex_json_schema.json), checked with Python jsonschema | Verified (tested) |
| Trivy v0.76.2 uses go-vex v0.2.9; applies only not_affected and fixed; latest statement wins; requires a product purl | [Trivy pkg/vex/openvex.go](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/openvex.go) and go.mod | Verified |
| Component, product, statement, vulnerability and purl matching rules; no version-range support; timestamp sort | [go-vex v0.2.9 pkg/vex](https://github.com/openvex/go-vex/tree/v0.2.9/pkg/vex) | Verified |
| Dependency-tree traversal and the multiple-paths rule | [Trivy local VEX files guide](https://github.com/aquasecurity/trivy/blob/v0.76.2/docs/guide/supply-chain/vex/file.md) and pkg/vex/vex.go | Verified |
| Match results in the example table | Python port of go-vex v0.2.9 rules, run against the example document | Qualified: port, not the Go library |
