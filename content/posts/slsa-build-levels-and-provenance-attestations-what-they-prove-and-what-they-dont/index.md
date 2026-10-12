+++
title = "SLSA Build Levels and Provenance Attestations: What They Prove and What They Don't"
date = 2026-10-12T06:10:00Z
tags = ["supply chain", "appsec"]
categories = ["appsec"]
summary = "SLSA Build Level 1, 2 and 3 describe how trustworthy a build's provenance is, not whether the code is safe. Here is what each level promises, how Sigstore and GitHub artifact attestations fit in, and how to verify an attestation with the GitHub CLI."
description = "SLSA Build L1, L2 and L3 explained: what provenance attestations prove, what they cannot, how Sigstore signing works, and how to verify GitHub artifact attestations with gh attestation verify."
author = "FirewallSync Editorial"
imageAlt = "Three cream envelopes, each closed with a bronze wax seal stamped with a tree design, on a white surface"
imageCredit = "Photo by [Diana Light](https://unsplash.com/photos/Fcd6LJ4HDNk) on Unsplash"
takeaways = [
  "SLSA (Supply-chain Levels for Software Artifacts) Build levels L1 to L3 describe how much you can trust a build's provenance record: L1 provenance exists, L2 a hosted platform signs it, L3 the platform is hardened against tampering during the build.",
  "Provenance says where and how an artifact was built. It does not say the source code is free of vulnerabilities or malicious changes.",
  "SLSA v1.2 is the current version and adds a Source track; the Build track levels described here are unchanged in outline from v1.1.",
  "GitHub states that artifact attestations alone provide SLSA v1.0 Build Level 2, and that Build Level 3 requires building in a reusable workflow.",
  "An attestation only protects you if the consumer verifies it against an expected identity, for example with gh attestation verify and a pinned repository or signer workflow."
]

[[faq]]
q = "What is the difference between SLSA and an SBOM?"
a = "An SBOM lists what is inside a piece of software. SLSA provenance records how and where a specific artifact was built. They answer different questions and are often published together. Our article on the 2026 SBOM minimum elements covers the inventory side."

[[faq]]
q = "Does SLSA Build Level 3 mean software is secure?"
a = "No. SLSA says Build L3 focuses on tampering during the build and requires a hardened build platform. It does not assess the source code, its dependencies' vulnerabilities, or whether the people who wrote it are trustworthy."

[[faq]]
q = "What is keyless signing?"
a = "In Sigstore's keyless flow, the signing client generates a new key pair for each signing, a certificate authority called Fulcio issues a short-lived certificate tied to the signer's OpenID Connect identity, and the private key is discarded after signing. The signature and certificate are recorded in the Rekor transparency log."

[[faq]]
q = "Are GitHub artifact attestations available for private repositories?"
a = "GitHub's documentation says attestations for private repositories use GitHub's own Sigstore instance, which has no public transparency log, while public repositories use the Sigstore Public Good Instance. The page we read does not state plan requirements, so check GitHub's current documentation for your plan."
+++

SLSA, pronounced "salsa" and short for Supply-chain Levels for Software Artifacts, is a framework for describing how much you can trust the way a software artifact was built. A SLSA **Build level** (L1, L2 or L3) is a statement about the build platform and the **provenance** it produces: a signed record of what was built, from what inputs, by which builder. It is not a statement that the software is free of bugs or backdoors. This article explains what each level means, how Sigstore signing and GitHub artifact attestations produce provenance, and what a consumer has to check for any of it to matter.

We read the SLSA specification pages (v1.2 and the retired v1.1), the Sigstore overview, GitHub's attestation documentation and the GitHub CLI manual on October 12, 2026. We did not build or sign any artifacts for this article; it is research-based explanation, not hands-on testing.

## The short answer

- **Build L1:** provenance exists. It records how the package was built, but the specification says it "can be used to prevent mistakes but is trivial to bypass or forge."
- **Build L2:** the build runs on a hosted platform that generates and signs the provenance. This addresses tampering after the build. Forging the provenance requires an explicit attack, which the specification notes may still be easy.
- **Build L3:** the platform is hardened so that runs cannot influence one another and the signing secret is unreachable from user-defined build steps. This addresses tampering during the build.

Source: [SLSA v1.2, Build track basics](https://slsa.dev/spec/v1.2/build-track-basics).

## What "provenance" contains

Provenance is a document (in SLSA's case an *attestation*, a signed statement about an artifact) linking an artifact's cryptographic digest to a description of how it was built. The SLSA provenance format uses the predicate type `https://slsa.dev/provenance/v1`. For Build L1, the specification requires the following fields:

| Field | What it holds | Notes from the specification |
|---|---|---|
| `buildDefinition.buildType` | A URI naming the build template | Should resolve to a human-readable specification |
| `buildDefinition.externalParameters` | Inputs the user controls | Must be complete at L3; consumers should reject unexpected fields |
| `runDetails.builder.id` | A URI identifying the trusted build platform | Intended to determine the SLSA Build level the consumer assigns |

Optional fields include `resolvedDependencies` (for example, the exact git commit a repository reference resolved to), `internalParameters` set by the platform, and run metadata such as start and finish times. These field requirements are from the v1.1 provenance page; that page is marked retired in favour of v1.2, and the v1.2 pages we read did not mention changes to the provenance format.

## Why the levels differ

The levels are not about better paperwork. Each answers a different attacker.

| Level | Who produces the provenance | Main threat addressed | What it does not stop |
|---|---|---|---|
| L1 | Build platform, possibly unsigned and incomplete | Mistakes; missing documentation | Anyone who simply edits or forges the record |
| L2 | Hosted build platform, which signs it | Tampering after the build | A build run that is itself manipulated; a tenant who can reach the signing key |
| L3 | Hardened hosted platform | Tampering during the build, including by other tenants or insiders | Malicious or vulnerable source; compromised dependencies |

Level descriptions are from the SLSA [v1.2 build track basics](https://slsa.dev/spec/v1.2/build-track-basics) and [build requirements](https://slsa.dev/spec/v1.2/build-requirements). The "does not stop" column is our reading of what each level's requirements leave out; the specification itself defines the levels by what they require. The L3 requirements include that it "MUST NOT be possible for one build to persist or influence the build environment of a subsequent build," and that provenance be "strongly resistant to forgery by tenants."

## What changed in SLSA v1.2

SLSA v1.0 removed source-code requirements to focus on the Build track. According to the v1.2 "What's new" page, v1.2 adds a **Source track** that helps organizations secure their source development process, updates the threat model, and reorganizes the specification to support multiple tracks. The page gives no release date. This article covers the Build track only; we did not review the Source track requirements. The v1.1 pages are marked "Retired" and point to v1.2 as current.

## How Sigstore produces the signature

Sigstore is an open project for signing and verifying software. In its keyless flow, according to the [Sigstore overview](https://docs.sigstore.dev/about/overview/):

1. **Cosign**, the client, generates a new key pair.
2. It sends the public key and an OpenID Connect (OIDC) identity token to **Fulcio**, the certificate authority.
3. Fulcio checks the token and issues a short-lived certificate binding the identity to the public key. (The page does not give a lifetime.)
4. Cosign signs the artifact, then discards the private key.
5. The artifact digest, signature and certificate are recorded in **Rekor**, an append-only transparency log.
6. A verifier checks the signature, confirms the certificate's identity is the one it expects, validates the certificate against Sigstore's root of trust, and verifies Rekor's proof of inclusion.

For CI signing, the identity in the certificate can describe the workflow rather than a person. The practical point: no long-lived signing key exists to steal, but the signature is only meaningful if the verifier decides *which identity* is acceptable.

## GitHub artifact attestations and the SLSA level

GitHub's [documentation](https://docs.github.com/en/actions/concepts/security/artifact-attestations) says artifact attestations are signed claims about where and how software was built, including links to the workflow, repository, organization, environment, commit SHA and triggering event, and that they can include an SBOM. It states:

- Attestations alone provide **SLSA v1.0 Build Level 2**. Build Level 3 requires builds to run in a **reusable workflow** shared across repositories, which isolates the build from the calling workflow.
- Public repositories use the Sigstore Public Good Instance, with the bundle written to a publicly readable transparency log. Private repositories use GitHub's own Sigstore instance, with no transparency log, federating only with GitHub Actions.
- Attestations are not a guarantee that an artifact is secure; you still need to define and evaluate a policy.
- Sign released software people will run or download, not frequent test builds or individual source files.

Note the version: GitHub's page refers to SLSA v1.0 levels. We did not check whether GitHub has published a mapping to v1.2.

## Verifying: the step most teams skip

Provenance nobody checks protects nobody. The GitHub CLI's [`gh attestation verify`](https://cli.github.com/manual/gh_attestation_verify) takes an artifact and requires at least one of `--owner` or `--repo`; the manual says that "the more precisely you specify the actor's identity, the stronger the verification guarantees." It checks the actor identity against the certificate and the predicate type, which defaults to `https://slsa.dev/provenance/v1`.

```
gh attestation verify example.bin --repo github/example
gh attestation verify example.bin --owner github --signer-repo actions/example
```

(Both are examples from the manual; `github/example` is a placeholder.) Useful flags documented in the manual:

- `--signer-workflow` or `--signer-repo`: needed when a reusable workflow produced the attestation.
- `--deny-self-hosted-runners`: fails verification for attestations generated on self-hosted runners.
- `--bundle`: verify offline from stored attestations.
- `--format json`: machine-readable output. The manual warns that only `signature.certificate` and `verifiedTimestamps` are tamper-resistant, and that `statement.predicate` can be falsified if an attacker controls the workflow, so policies should not rely on it alone.

That last warning is worth sitting with. If an attacker controls the build workflow, the provenance they get signed is truthful about *which workflow ran*, not about the workflow being benign. This is why pinning the expected signer workflow matters more than reading the contents.

## What provenance does not prove

These are our conclusions from the framework's definitions, not claims the specification makes in these words:

- **That the source is trustworthy.** Provenance links an artifact to a commit; it says nothing about whether the commit is malicious. Source controls are what the Source track is for.
- **That dependencies are safe.** Provenance records inputs; it does not vet them. See our guides to [dependency audits without slowing releases](/posts/dependency-audits-without-slowing-down-releases/) and to what [container image scanning still misses](/posts/container-image-scanning-what-ci-pipelines-still-miss/).
- **That the software has no known vulnerabilities.** For that you need an inventory ([SBOM](/posts/sbom-minimum-elements-2026-what-cisa-and-partners-changed-from-the-2021-ntia-baseline/)) and prioritization ([CVSS, EPSS and KEV](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/)).
- **That the build platform itself is uncompromised.** The level is only as good as the platform's isolation.

## A practical adoption order (our suggestion)

1. Produce attestations for released artifacts only, on a hosted builder (this reaches L2 on GitHub per its documentation).
2. Write down the expected identity for each artifact: repository, and signer workflow if you use a reusable workflow.
3. Verify in the place where artifacts are consumed (deployment pipeline or admission step), failing closed on mismatch.
4. Move high-value artifacts to a reusable workflow to target L3, and test that your verification command pins that workflow.
5. Treat provenance as one control alongside SBOMs, dependency review and source protections.

## Limits of this article

We did not run signing or verification ourselves. We did not read the SLSA Source track requirements, GitHub plan requirements, the Sigstore certificate lifetime, or any mapping of GitHub's attestations to SLSA v1.2. The SLSA v1.1 pages we used for the provenance fields are retired.

## Sources and verification

Checked on October 12, 2026.

| Important claim | Source | Verification |
|---|---|---|
| Build L0 to L3 definitions, focus and quoted phrases | [SLSA v1.2 Build track basics](https://slsa.dev/spec/v1.2/build-track-basics) | Verified |
| L3 isolation and unforgeability requirements | [SLSA v1.2 Build requirements](https://slsa.dev/spec/v1.2/build-requirements) | Verified |
| v1.2 adds a Source track, updates the threat model; no date given | [SLSA v1.2 What's new](https://slsa.dev/spec/v1.2/whats-new) | Qualified: page gives no release date |
| Provenance predicate type and L1-required fields | [SLSA v1.1 Provenance](https://slsa.dev/spec/v1.1/provenance) | Qualified: v1.1 page, marked retired; no format change noted in v1.2 pages |
| Sigstore keyless flow and component roles | [Sigstore overview](https://docs.sigstore.dev/about/overview/) | Verified; certificate lifetime not stated |
| GitHub attestations: SLSA v1.0 Build L2 alone, L3 with reusable workflows; public vs private Sigstore instances | [GitHub Docs, artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) | Qualified: refers to SLSA v1.0 |
| `gh attestation verify` options and JSON caveat | [GitHub CLI manual](https://cli.github.com/manual/gh_attestation_verify) | Verified |
| What provenance does not prove; adoption order | Our analysis | Qualified: editorial judgment |
