+++
title = "Cosign Container Image Signing: Keyless Signing in CI and Why Verification Must Pin an Identity"
date = 2026-10-13T06:06:00Z
tags = ["supply chain", "appsec"]
categories = ["appsec"]
summary = "Signing a container image with Sigstore's cosign takes one command; the security comes from what the verifier insists on. Here is how keyless signing works in a GitHub Actions job, what to pin when verifying, and what an August 2026 cosign advisory shows about trusting the verifier."
description = "How to sign container images with cosign keyless signing in GitHub Actions and verify them with --certificate-identity and --certificate-oidc-issuer, plus what the August 2026 cosign verify-blob advisory (GHSA-fx35-mq7g-6g98) means for you."
author = "FirewallSync Editorial"
imageAlt = "Close-up of the double doors of a weathered blue shipping container, with a small padlock hanging from the latch on the right door"
imageCredit = "Photo by [Lee Milo](https://unsplash.com/photos/ajgOnWhzD1k) on Unsplash"
takeaways = [
  "Keyless signing with cosign uses a short-lived certificate from Sigstore's Fulcio certificate authority tied to an OpenID Connect (OIDC) identity, so a CI job can sign without a long-lived private key.",
  "In GitHub Actions the signing job needs the permission id-token: write; the official installer example signs image references of the form tag@digest, not bare tags.",
  "A signature proves little unless the verifier pins who must have signed. For keyless flows cosign requires you to set --certificate-identity (or its regexp variant) and --certificate-oidc-issuer (or its regexp variant).",
  "Advisory GHSA-fx35-mq7g-6g98 (published August 6, 2026, High, CVSS 7.4) affected cosign verify-blob and verify-blob-attestation with legacy JSON bundles, in cosign 2.6.4 and earlier and 3.1.2 and earlier. The advisory says OCI image verification is not affected.",
  "Signing and verifying prove who published an image, not that it is free of vulnerabilities. Pair them with scanning, SBOMs and provenance."
]

[[faq]]
q = "Do I need to manage a private key to sign container images with cosign?"
a = "Not with keyless signing. Cosign's documentation describes keyless signing as associating identities, rather than keys, with a signature: it uses an ephemeral key, the private key is destroyed shortly after signing, and Fulcio issues a short-lived certificate binding that key to an OIDC identity. Cosign also supports signing with your own key pair via the --key flag."

[[faq]]
q = "Where does cosign store the signature for a container image?"
a = "Cosign's signing documentation says signatures use the OCI 1.1 referrer specification, and you can inspect what is attached to an image with cosign tree. The page we read did not describe the older tag-based storage, so check the documentation for the version you run."

[[faq]]
q = "What must I pass to cosign verify for a keyless signature?"
a = "Cosign's command reference says that for keyless flows either --certificate-identity or --certificate-identity-regexp must be set, and either --certificate-oidc-issuer or --certificate-oidc-issuer-regexp must be set. For tokens issued to GitHub Actions jobs, the issuer is https://token.actions.githubusercontent.com."

[[faq]]
q = "Is my image-signing setup affected by the August 2026 cosign advisory?"
a = "Only if you used cosign verify-blob or verify-blob-attestation with a legacy JSON --bundle on cosign 2.6.4 or earlier, or 3.1.2 or earlier. The advisory states that the protobuf bundle format and OCI image verification are not affected. The fixed versions are 2.6.5 and 3.1.3."
+++

Signing a container image with **cosign**, the command-line client of the open-source Sigstore project, is a one-line command. Whether the signature protects anyone depends on the other end: the verifier has to say *who* must have signed the image and *which identity provider* must have vouched for them. This article walks through keyless signing in a GitHub Actions job, what to pin when verifying, and why an August 2026 advisory about cosign's own verification is a good reminder that the verifier is part of your trust chain.

We read the Sigstore documentation, the cosign command reference, the `sigstore/cosign-installer` README, GitHub's documentation on its OIDC tokens, the cosign release notes and the cosign security advisory on October 13, 2026. We did not run any of the commands for this article, so it is research-based explanation, not hands-on testing. Placeholders in angle brackets are for you to fill in.

## The short answer

- **Sign:** `cosign sign <image>@<digest>` in your release job. In keyless mode no key pair is stored: cosign gets a short-lived certificate for the job's OIDC identity.
- **Verify:** run `cosign verify` with `--certificate-identity` and `--certificate-oidc-issuer` set to the identity and issuer you expect, in the place where images are deployed or pulled.
- **Keep cosign patched** on both signing and verifying machines. The advisory below shows verification code can itself have bugs.

## What keyless signing does

Per the [Sigstore cosign documentation](https://docs.sigstore.dev/cosign/signing/overview/), keyless signing "associates identities, rather than keys, with an artifact signature." Cosign uses an ephemeral key; the page notes the private key is destroyed shortly after signing. **Fulcio**, Sigstore's certificate authority, "issues short-lived certificates binding an ephemeral key to an OpenID Connect identity." The signing event is logged in **Rekor**, a signature transparency log, "providing an auditable record." Our article on [SLSA build levels and provenance](/posts/slsa-build-levels-and-provenance-attestations-what-they-prove-and-what-they-dont/) describes the same flow in the context of attestations.

In an automated environment cosign can take an OIDC token directly via `--identity-token`; the documentation says the token's audiences claim must contain `sigstore`. In GitHub Actions, the cosign installer's example relies on the job's GitHub OIDC token instead.

## Signing in GitHub Actions

The [`sigstore/cosign-installer` README](https://github.com/sigstore/cosign-installer) provides an example workflow. The elements that matter for security are:

- **Permissions.** The job needs `id-token: write` (annotated in the example as "needed for signing the images with GitHub OIDC Token"). GitHub's [OIDC documentation](https://docs.github.com/en/actions/reference/security/oidc) states that without `id-token: write` the OIDC JWT ID token cannot be requested. The example also grants `packages: write` for pushing to `ghcr.io` and `contents: read`.
- **Sign by digest.** The example builds and pushes the image, takes the digest from the build step's output and signs `tag@digest` references. We read this as the reason the digest matters: a tag can later be re-pointed to a different image, while a digest identifies specific content. (The cosign signing page we read does not itself state a digest recommendation; this is our reading of the example.)
- **No secret for keyless.** The README's keyless step runs `cosign sign --yes ${images}` with no key. Its other example signs with a key held in repository secrets, which brings back the problem of protecting a long-lived key.
- **Untrusted values in shell.** The example passes values through environment variables rather than inline expressions, following GitHub's guidance on script injection.
- **Pin the installer.** The README says the `cosign-release` input pins a specific cosign version and that you then maintain that version yourself. Pinning also applies to the installer action: the example references `sigstore/cosign-installer@v4.1.0`; for stronger protection against a moved tag you can pin actions to a full commit SHA (our suggestion, not from the README).

The signature is stored with the image in the registry. The signing documentation says signatures use the OCI 1.1 referrer specification, and `cosign tree <image>` shows what is attached. Your registry must support what cosign pushes; we did not test registry compatibility.

## Verifying: pin the identity and the issuer

This is the step that turns a signature into a control. For keyless signatures, the [cosign command reference](https://github.com/sigstore/cosign/blob/main/doc/cosign_verify.md) says the identity flags are mandatory:

```
cosign verify <registry>/<repo>@<digest> \
  --certificate-identity=<expected signer identity> \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

What each flag means, per the reference:

| Flag | Meaning in the reference | What to put there |
|---|---|---|
| `--certificate-identity` | The identity expected in a valid Fulcio certificate; valid values include email addresses, DNS names, IP addresses and URIs. One of this or `--certificate-identity-regexp` must be set for keyless flows | The identity of your release workflow (see below) |
| `--certificate-oidc-issuer` | The OIDC issuer expected in the certificate; the reference gives `https://token.actions.githubusercontent.com` as an example. One of this or `--certificate-oidc-issuer-regexp` must be set | For GitHub Actions: `https://token.actions.githubusercontent.com` |

**Exact vs regexp.** The regexp variants accept Go regular expressions. A loose pattern (for example one that matches any repository in an organization, or any branch) widens who can satisfy your policy. Prefer exact values where you can; if you must use a pattern, anchor it. This is our recommendation.

**What identity string to expect.** We did not verify, from the sources above, the exact format of the identity that appears in a certificate issued to a GitHub Actions job, so we do not state one here. GitHub's OIDC documentation defines claims in the *token* (for example the `sub` claim, formatted like `repo:ORG/REPO:ref:refs/heads/BRANCH` in its examples, and `job_workflow_ref` for reusable workflows), but how those claims map into the Fulcio certificate identity is not something we confirmed. A reasonable procedure (our suggestion): sign a test image from your real release workflow, inspect the certificate on that signature, record the identity and issuer you see there, and then pin those exact values.

**What a passing check tells you.** That the image content matches the signed digest and that a signer with the pinned identity signed it, with the signing recorded in the transparency log. It does not tell you the image is free of vulnerabilities or malicious code, or that the workflow that signed it was itself uncompromised. For vulnerability status, see our articles on [VEX statements](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/) and [what container image scanning still misses](/posts/container-image-scanning-what-ci-pipelines-still-miss/).

Where to run it: at the point of consumption, such as a deploy job or an admission step in your cluster, failing the deployment on mismatch. The cosign reference documents the command-line flags; we did not review Kubernetes admission tooling, so that part is outside this article.

## A reminder that the verifier needs patching too

On August 6, 2026, the cosign project published advisory [GHSA-fx35-mq7g-6g98](https://github.com/sigstore/cosign/security/advisories/GHSA-fx35-mq7g-6g98), "Verification bypass via public key in legacy bundle." The facts as stated in the advisory:

| Item | Detail |
|---|---|
| Severity | High, CVSS 7.4 (vector CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:N/I:H/A:N) |
| CVE | None assigned ("No known CVE") |
| Affected commands | `cosign verify-blob` and `cosign verify-blob-attestation`, when given a legacy JSON `--bundle` |
| Affected versions | cosign v2.6.4 and earlier; cosign v3.1.2 and earlier |
| Patched versions | v2.6.5 and v3.1.3 |
| Mechanism | If the bundle's `cert` field is not a valid X.509 certificate, cosign treated it as a raw public key; certificate chain and identity checks were skipped, so `--certificate-identity` and `--certificate-oidc-issuer` were ignored |
| Not affected | The protobuf bundle format and OCI image verification, per the advisory |
| Workaround | Upgrade; or migrate to the standardized protobuf bundle format (`--new-bundle-format`); `cosign bundle create` can convert existing bundles |

**What this means for container image signing.** The advisory says OCI image verification is not affected, so a pipeline that only runs `cosign verify` on images in a registry is outside the described bug. It matters if you also sign and verify **blobs**, such as release binaries, tarballs or SBOM files, using separate bundle files. The general lesson is practical: identity pinning only helps if the verifier actually enforces it, so track cosign releases on every machine that verifies. The cosign [releases page](https://github.com/sigstore/cosign/releases) lists v3.1.3 and v2.6.5 as the August 6, 2026 releases that carry the fix. The same page records a bundle-format change in the 2.6 line: its notes say the default for signing is now the bundle format, and that `--new-bundle-format=false` signs in the old format; verification in 3.1.x accepts both formats. Check the release notes for your version before changing flags.

## A rollout checklist (our suggestion)

1. Sign only release images from a protected workflow, by digest.
2. Give the signing job only the permissions it needs: `id-token: write`, plus whatever the registry push requires.
3. Sign a test image, inspect the certificate, and record the exact identity and issuer to pin.
4. Verify wherever the image is deployed, with exact identity and issuer flags, and fail closed.
5. Pin and update cosign deliberately on signing and verifying hosts; subscribe to the project's security advisories.
6. If you also use blob signatures, confirm none depend on legacy JSON bundles on affected versions.
7. Remember what signing does not cover: see our [SBOM minimum-elements](/posts/sbom-minimum-elements-2026-what-cisa-and-partners-changed-from-the-2021-ntia-baseline/) article for the inventory side.

## Limits of this article

We did not run cosign, sign or verify anything, or test any registry. The cosign command reference we cite is the `main` branch of the project's repository, which may differ from the version you run; the Sigstore signing page we read did not discuss differences between cosign v2 and v3. We did not confirm the exact certificate-identity format for GitHub Actions jobs, did not review the Sigstore Public Good Instance's operational policies or Kubernetes admission tooling, and did not independently re-score the advisory's CVSS vector.

## Sources and verification

Checked on October 13, 2026.

| Important claim | Source | Verification |
|---|---|---|
| Keyless signing associates identities rather than keys; ephemeral key destroyed; Fulcio issues short-lived certificates; Rekor logs signing; `--identity-token` audience must contain `sigstore` | [Sigstore, cosign signing overview](https://docs.sigstore.dev/cosign/signing/overview/) | Verified |
| `cosign sign <image>` (keyless) and `--key` signing; signatures use the OCI 1.1 referrer specification; `cosign tree` | [Sigstore, signing containers](https://docs.sigstore.dev/cosign/signing/signing_with_containers/) | Verified |
| Workflow needs `id-token: write`; example signs `tag@digest` with `cosign sign --yes`; `cosign-release` pinning; installer example version v4.1.0 | [sigstore/cosign-installer README](https://github.com/sigstore/cosign-installer) | Verified: example versions may change |
| Without `id-token: write` the OIDC token cannot be requested; GitHub issuer URL | [GitHub Docs, OIDC reference](https://docs.github.com/en/actions/reference/security/oidc) | Verified |
| Keyless verification requires `--certificate-identity` or its regexp form and `--certificate-oidc-issuer` or its regexp form | [cosign verify reference](https://github.com/sigstore/cosign/blob/main/doc/cosign_verify.md) | Qualified: `main` branch documentation |
| Advisory GHSA-fx35-mq7g-6g98: published August 6, 2026; High, CVSS 7.4; no CVE; affected and patched versions; affected commands; OCI image verification not affected | [GitHub advisory](https://github.com/sigstore/cosign/security/advisories/GHSA-fx35-mq7g-6g98) | Verified: score as published by the project |
| v3.1.3 and v2.6.5 released August 6, 2026 with the fix; bundle-format default note | [cosign releases](https://github.com/sigstore/cosign/releases) | Qualified: page shows month and day only; year inferred from asset timestamps |
| Digest rationale, exact-vs-regexp advice, certificate-inspection procedure, rollout checklist | Our analysis | Qualified: editorial judgment, labelled as such |
