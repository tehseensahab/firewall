+++
title = "Trivy --vex oci: OpenVEX Attestations on OCI Images"
date = 2026-11-11T04:55:00Z
tags = ["vex", "openvex", "trivy", "cosign", "sigstore", "oci referrers", "container security", "supply chain security"]
categories = ["cloud-security"]
summary = "How Trivy's --vex oci finds an OpenVEX document attached to a container image: the three registry layouts it reads, the in-toto.io/predicate-type annotation, why it takes the first match, and the warning that matters most: Trivy does not verify the attestation's signature. Includes a verify-then-scan pattern with cosign verify-attestation."
description = "Trivy --vex oci reads OpenVEX attestations from OCI referrers or cosign .att tags but does not verify signatures. How discovery works and how to verify first."
author = "John Marshall"
imageAlt = "Stacked shipping containers"
imageCredit = "Photo by [CHUTTERSNAP](https://unsplash.com/photos/assorted-shipping-containers-in-dock-Q4bmoSPJM18) on Unsplash"
takeaways = [
  "cosign attest --predicate vex.json --type openvex <image> attaches an OpenVEX document to an image as an in-toto attestation with predicate type https://openvex.dev/ns (cosign v3.1.4 source). Since cosign v3 it is stored as an OCI 1.1 referrer by default.",
  "trivy image --vex oci <image> looks for OCI 1.1 referrers first (Sigstore bundle, DSSE envelope or bare in-toto statement), then falls back to the legacy cosign v2 sha256-<digest>.att tag. Referrer support arrived in Trivy v0.73.0; the feature is still marked experimental.",
  "Trivy's documentation warns that it does not verify the signature of a discovered VEX attestation: anyone who can push to the repository can attach one that suppresses findings.",
  "In Trivy v0.76.2 the first referrer that decodes to OpenVEX wins, in registry order; other VEX attestations on the same image are not merged. Keep one current VEX document per image digest.",
  "For anything that gates a release, verify with cosign verify-attestation --type openvex and a pinned identity, extract the predicate, and pass the file to trivy --vex <file> instead of --vex oci."
]

[[faq]]
q = "What does trivy --vex oci do?"
a = "It makes Trivy look in the image's registry for an OpenVEX attestation attached to the scanned image and apply its statements, so findings marked not_affected or fixed are suppressed. Trivy v0.76.2 checks OCI 1.1 referrers first and falls back to the legacy cosign .att tag. Add --show-suppressed to see what VEX filtered."

[[faq]]
q = "Does Trivy verify the signature on a VEX attestation?"
a = "No. Trivy's VEX attestation documentation says it 'does not verify the signature of the discovered VEX attestation' and that anyone able to push to the image's repository can attach one that suppresses findings. Use --vex oci only with registries you trust, or verify with cosign first and pass the extracted document as a local file."

[[faq]]
q = "Can an OpenVEX product ID target an image tag?"
a = "Not in Trivy at the moment. Its documentation says a product ID with a tag qualifier, such as pkg:oci/trivy?repository_url=ghcr.io/aquasecurity/trivy&tag=0.50.0, is not supported. Use the repository (all tags) or a specific digest as the purl version."

[[faq]]
q = "What predicate type does cosign use for --type openvex?"
a = "In cosign v3.1.4, --type openvex maps to https://openvex.dev/ns. Trivy accepts that exact value or any value that starts with https://openvex.dev/ns/, such as https://openvex.dev/ns/v0.2.0."
+++

A VEX (Vulnerability Exploitability eXchange) document is only useful if the scanner finds it. Trivy can pick one up from the registry: attach an OpenVEX document to an image with `cosign attest --type openvex`, scan with `trivy image --vex oci`, and findings you have declared `not_affected` drop out of the report.

The part that matters for anyone using this to gate a release: **Trivy does not verify the attestation's signature.** Its [documentation](https://github.com/aquasecurity/trivy/blob/v0.76.2/docs/guide/supply-chain/vex/oci.md) says so in a warning box: "Anyone able to push to the image's repository can attach a VEX attestation that suppresses findings, so use `--vex oci` only with registries you trust."

This article covers how discovery works in Trivy v0.76.2 (the current release on November 11, 2026), what cosign v3.1.4 writes, and a verify-then-scan pattern that closes the signature gap. It follows our [OpenVEX products and subcomponents guide](/posts/openvex-products-subcomponents-purl-matching-trivy/), which explains how Trivy matches statements to packages and explicitly left `--vex oci` out of scope.

## The three commands

From Trivy's VEX attestation page, the end-to-end flow is:

```bash
# 1. Write an OpenVEX document (by hand or with a tool such as vexctl)
# 2. Attach it to the image as a signed in-toto attestation
cosign attest --predicate oci.openvex.json --type openvex <IMAGE>

# 3. Scan, letting Trivy discover the attestation
trivy image --vex oci <IMAGE>
trivy image --vex oci --show-suppressed <IMAGE>   # list what VEX filtered
```

Trivy's page marks the feature **EXPERIMENTAL**: "This feature might change without preserving backwards compatibility." It also notes the `cosign attest` command "attaches the attestation only to the specified image tag. If needed, repeat the process for other tags and digests," and that the image you scan "must be the same as the one to which you attached the VEX attestation."

## Writing the OpenVEX document for an image

The statement's product is the image itself, written as an `oci` package URL (purl). The [purl `oci` type definition](https://github.com/package-url/purl-spec/blob/main/types/oci-definition.json) says the name is "the last fragment of the repository name", the namespace is prohibited, and the version "is the sha256:hex_encoded_lowercase_digest of the artifact". The registry location goes in the `repository_url` qualifier.

Trivy's documentation gives two forms:

| Product `@id` | Applies to |
|---|---|
| `pkg:oci/trivy?repository_url=ghcr.io/aquasecurity/trivy` | All tags of that repository |
| `pkg:oci/trivy@sha256:5bd5…d159?repository_url=ghcr.io/aquasecurity/trivy` | One digest only |
| `…&tag=0.50.0` | **Not supported** in the product ID "at the moment" |

The vulnerable packages go in `subcomponents`, for example `pkg:apk/alpine/busybox`, optionally with version and qualifiers such as `arch` to narrow the statement. The matching rules (which qualifiers must match, what happens with no subcomponents) are in our [purl matching guide](/posts/openvex-products-subcomponents-purl-matching-trivy/).

A minimal document, which we validated against the [OpenVEX JSON schema](https://github.com/openvex/spec/blob/main/openvex_json_schema.json) (Python 3.13, `jsonschema` 4.26.0):

```json
{
  "@context": "https://openvex.dev/ns/v0.2.0",
  "@id": "https://example.com/vex/app-2026-11-11-1",
  "author": "Example Platform Team <security@example.com>",
  "timestamp": "2026-11-11T05:00:00Z",
  "version": 1,
  "statements": [
    {
      "vulnerability": { "name": "CVE-2023-42363" },
      "products": [
        {
          "@id": "pkg:oci/app?repository_url=ghcr.io/example/app",
          "subcomponents": [ { "@id": "pkg:apk/alpine/busybox" } ]
        }
      ],
      "status": "not_affected",
      "justification": "vulnerable_code_not_in_execute_path",
      "impact_statement": "The image never invokes busybox awk."
    }
  ]
}
```

The repository, author and justification here are illustrative. What a `not_affected` status and its justification commit you to is covered in [VEX explained](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/).

## What cosign writes to the registry

In the cosign v3.1.4 source, `--type openvex` maps to the predicate type `https://openvex.dev/ns` (`OpenVexNamespace` in `pkg/cosign/attestation`). Other accepted shorthands are `slsaprovenance`, `spdx`, `cyclonedx`, `vuln`, `link` and `custom`, or a full URI.

Where it lands depends on the cosign major version. Cosign's v3.0.0 changelog says v3 turns on by default "the standardized bundle format", plus "container signatures stored as an OCI Image 1.1 referring artifact". In v3.1.4 the `attest` flag `--new-bundle-format` defaults to `true` with the help text "attach a Sigstore bundle using OCI referrers API". Cosign v2 instead stored attestations under a tag derived from the image digest.

| Writer | Registry layout | Artifact type Trivy matches |
|---|---|---|
| cosign v3 (default) | OCI 1.1 referrer holding a Sigstore bundle | `application/vnd.dev.sigstore.bundle.v0.3+json` |
| Tools publishing a DSSE envelope as a referrer | OCI 1.1 referrer | `application/vnd.dsse.envelope.v1+json` |
| Tools publishing a bare in-toto statement, "such as Docker Scout" (Trivy docs) | OCI 1.1 referrer | `application/vnd.in-toto+json` |
| cosign v2 (default) | Tag `sha256-<hex>.att`, one layer per `cosign attest` call | n/a (legacy tag) |

The artifact type strings are the constants in Trivy v0.76.2 `pkg/oci/artifact.go`.

## How Trivy discovers the VEX attestation

We read Trivy v0.76.2's `pkg/vex/oci/oci.go` alongside the docs. The sequence:

1. **Resolve the digest.** Trivy builds an `oci` purl for the scanned image. If the purl has a version, that is the digest; otherwise it resolves the reference (tag) to a digest with a registry lookup.
2. **List referrers** of that digest whose artifact type is one of the three in the table.
3. **Filter by annotation.** All three artifact types are shared with SBOM and provenance attestations, so Trivy reads the optional `in-toto.io/predicate-type` annotation on each referrer descriptor. If any referrer is annotated as OpenVEX, only those are considered, "even when none of them can be fetched or decoded" (docs). Referrers annotated as something else are dropped without download. Unannotated referrers are downloaded and inspected only when nothing is annotated as OpenVEX.
4. **Take the first OpenVEX document.** Trivy decodes candidates in registry order and returns the first one whose predicate is OpenVEX. A referrer it cannot download or decode is skipped with a warning.
5. **Fall back to the legacy tag** `sha256-<hex>.att` if no referrer yielded a VEX document, again returning the first layer that decodes to OpenVEX.

A predicate type counts as OpenVEX if it equals `https://openvex.dev/ns` or starts with `https://openvex.dev/ns/`, so both cosign's value and a versioned URI match.

Two limits are hard-coded as defences against a hostile registry: at most **100** attestations are processed per image ("cosign caps the number of attestations per image at 100; mirror that", per the source comment), and each attestation is capped at **20 MiB** uncompressed. An oversized attestation fails the discovery instead of being skipped.

Version note: discovery from OCI 1.1 referrers was added in July 2026 (Trivy pull requests #10932 and #10986); the first release tag containing both commits is **v0.73.0**. Earlier Trivy releases read only the legacy `.att` tag, so they will not see attestations written by cosign v3 with default settings.

## What this means in practice

**Old VEX attestations are not merged, and the newest does not automatically win.** Because step 4 returns the first match in registry order, attaching a corrected VEX document next to an older one does not guarantee Trivy uses the correction. The safest pattern is one VEX attestation per image digest, rebuilt and re-attached when statements change, or the verify-then-scan approach below where you choose the document.

**Tags drift; digests don't.** A repository-wide product ID applies the statement to every tag, including images built after the analysis was done. Use the digest form when the justification depends on what is inside one build.

**The attestation is signed, but the scanner doesn't check it.** Cosign signs the attestation and logs it in Rekor, but `--vex oci` reads the predicate without checking who signed it. In a registry where CI service accounts, contractors or a compromised token can push, that is a path to silently hide findings.

## Verify first, then scan with a local file

Trivy also accepts a local VEX file (`--vex /path/to/vex.json`), and multiple `--vex` sources can be combined; the order you give them sets priority. That allows a pipeline to verify the attestation with cosign and hand Trivy only a document that passed.

`cosign verify-attestation` takes `--type` (same shorthands as `attest`) and, for keyless signing, requires `--certificate-identity` (or `-regexp`) and `--certificate-oidc-issuer` (or `-regexp`), per the v3.1.4 command reference. Pinning those values is the same discipline as in our [cosign keyless signing guide](/posts/cosign-container-image-signing-keyless-signing-in-ci-and-why-verification-must-pin-an-identity/).

```bash
IMAGE=ghcr.io/example/app@sha256:...   # scan and verify the same digest

cosign verify-attestation --type openvex \
  --certificate-identity "https://github.com/example/app/.github/workflows/release.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  "$IMAGE" > verified.jsonl

python3 extract_openvex.py < verified.jsonl > vex.json
trivy image --vex vex.json --show-suppressed "$IMAGE"
```

The identity and issuer values are illustrative; use the workflow that actually produces your attestations. `extract_openvex.py` assumes the output format shown in the [Sigstore attestation docs](https://docs.sigstore.dev/cosign/verifying/attestation/), where each verified attestation is printed as JSON whose `payload` is a base64-encoded in-toto statement (`jq -r .payload | base64 -d`). Check that against the cosign version you run.

```python
#!/usr/bin/env python3
"""Read `cosign verify-attestation` output on stdin (one JSON object per line,
each a DSSE envelope with a base64 `payload`), keep in-toto statements whose
predicateType is OpenVEX, and write the predicate to stdout."""
import base64, json, sys

OPENVEX = "https://openvex.dev/ns"
found = []
for line in sys.stdin:
    line = line.strip()
    if not line.startswith("{"):
        continue
    env = json.loads(line)
    stmt = json.loads(base64.b64decode(env["payload"]))
    pt = stmt.get("predicateType", "")
    if pt == OPENVEX or pt.startswith(OPENVEX + "/"):
        found.append(stmt["predicate"])
if len(found) != 1:
    sys.exit(f"expected exactly 1 verified OpenVEX attestation, got {len(found)}")
json.dump(found[0], sys.stdout, indent=2)
```

We ran the script with Python 3.13 against a synthetic two-line input (an SBOM statement and an OpenVEX statement, built locally); it skipped the SBOM and wrote the VEX document. We did not run it against a live registry. Failing when there is not exactly one verified VEX attestation is deliberate: it surfaces the multiple-attestation ambiguity instead of guessing.

Where VEX fits in the wider patch decision (after KEV, EPSS and SSVC have told you what is urgent) is covered in our [vulnerability prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/).

## Common mistakes

- **Scanning a tag you didn't attest.** The attestation is bound to a digest; a rebuilt `:latest` has a new digest and no VEX.
- **Running an older Trivy against cosign v3 attestations.** Before v0.73.0 Trivy did not read OCI 1.1 referrers.
- **Using `&tag=` in the product ID.** Trivy does not support it; the statement won't apply.
- **Treating `--vex oci` output as a signed decision.** It is whatever was attached last by anyone with push rights, read in registry order.

## Limits of this article

- Behaviour described is Trivy v0.76.2 and cosign v3.1.4, from their documentation and source. The Trivy feature is experimental and may change.
- We did not run Trivy or cosign against a registry. The JSON document and the Python script were run locally as described; the shell commands are illustrative.
- Registry support for the OCI 1.1 referrers API varies; check yours.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| `--vex oci` flow, three layouts, referrer precedence, annotation behaviour, tag not supported, experimental, signatures not verified | [Trivy docs: Discover VEX Attestation in OCI Registry](https://github.com/aquasecurity/trivy/blob/v0.76.2/docs/guide/supply-chain/vex/oci.md) | Verified |
| First match wins, 100-attestation and 20 MiB caps, digest resolution, OpenVEX predicate check | [Trivy v0.76.2 `pkg/vex/oci/oci.go`](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/oci/oci.go) | Verified (source reading) |
| Artifact type strings | [Trivy v0.76.2 `pkg/oci/artifact.go`](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/oci/artifact.go) | Verified |
| Referrer discovery first released in v0.73.0 | Trivy git history, PRs [#10932](https://github.com/aquasecurity/trivy/pull/10932) and [#10986](https://github.com/aquasecurity/trivy/pull/10986) | Verified (git tag containment) |
| Local file and multiple `--vex` sources, order sets priority | [Trivy docs: VEX overview](https://github.com/aquasecurity/trivy/blob/v0.76.2/docs/guide/supply-chain/vex/index.md) | Verified |
| `--type openvex` → `https://openvex.dev/ns`; `--new-bundle-format` default true | [cosign v3.1.4 source](https://github.com/sigstore/cosign/tree/v3.1.4/cmd/cosign/cli/options) | Verified |
| Cosign v3 defaults to bundles and OCI 1.1 referrers | [cosign CHANGELOG, v3.0.0](https://github.com/sigstore/cosign/blob/v3.1.4/CHANGELOG.md) | Verified |
| `verify-attestation` flags | [cosign verify-attestation reference](https://github.com/sigstore/cosign/blob/v3.1.4/doc/cosign_verify-attestation.md) | Verified |
| `verify-attestation` output shape | [Sigstore docs: verifying attestations](https://docs.sigstore.dev/cosign/verifying/attestation/) | Qualified: docs example, not tested on v3.1.4 |
| `oci` purl version is the digest | [purl-spec oci type definition](https://github.com/package-url/purl-spec/blob/main/types/oci-definition.json) | Verified |
