+++
title = "Verify Signed Container Images in Kubernetes with Sigstore policy-controller: Keyless Policy and Safe Rollout"
date = 2026-10-14T06:08:00Z
tags = ["supply chain", "cloud security"]
categories = ["cloud-security"]
summary = "Signing images only helps if something refuses the unsigned ones. This guide covers Sigstore's policy-controller admission webhook: opting namespaces in, writing a ClusterImagePolicy that pins a GitHub Actions workflow identity, rolling out in warn mode, and the failure-policy trade-off the Helm chart defaults create."
description = "How to enforce cosign signatures in Kubernetes with Sigstore policy-controller: namespace opt-in, a keyless ClusterImagePolicy pinned to a GitHub Actions workflow, warn-mode rollout, no-match-policy and webhook failure-policy risks."
author = "FirewallSync Editorial"
imageAlt = "A row of gray metal fare gates with orange tops and green indicator lights at a station entrance, with a blue directional sign above and glass barriers to the right"
imageCredit = "Photo by [Eric Prouzet](https://unsplash.com/photos/vSKnoJZr3m8) on Unsplash"
takeaways = [
  "Sigstore's policy-controller is a Kubernetes admission webhook that validates cosign signatures and attestations on container images. Per its documentation it only checks namespaces that carry the label policy.sigstore.dev/include: \"true\".",
  "A ClusterImagePolicy lists image globs and authorities. Every matching policy must pass, and within one policy any single passing authority is enough, so one permissive authority can undo a strict one.",
  "For keyless signatures the policy must pin an issuer and a subject. For GitHub Actions the issuer is https://token.actions.githubusercontent.com and, per Sigstore's CI quickstart, the signer identity looks like https://github.com/ORG/REPO/.github/workflows/FILE@refs/heads/BRANCH.",
  "Policy-controller's documentation says that an image matching no policy is rejected unless the no-match-policy setting says otherwise. Set that deliberately before enabling a namespace.",
  "The Helm chart's default values on its main branch set webhook.failurePolicy to Fail and replicaCount to 1. Under Kubernetes' Fail semantics, an unreachable webhook rejects matching requests, so plan replicas and test the failure case before enforcing."
]

[[faq]]
q = "Does policy-controller check every namespace by default?"
a = "No. Its documentation says the controller validates only namespaces that opt in with the label policy.sigstore.dev/include=true. It also describes switching to opt-out by editing the webhook configurations' matchExpressions, and warns that this may cause problems in system namespaces."

[[faq]]
q = "What happens to an image that no ClusterImagePolicy matches?"
a = "The documentation says the behavior is set by the no-match-policy key in the config-policy-controller ConfigMap, with values warn, allow or deny, and that an image matching no policy is rejected if the key is not configured."

[[faq]]
q = "Can I try a policy without blocking deployments?"
a = "Yes. The documentation says spec.mode set to warn admits a non-compliant image and returns a warning to the caller instead of blocking. The project also ships a policy-tester tool that evaluates a ClusterImagePolicy against an image without a cluster, per its README."

[[faq]]
q = "Does admission-time verification protect pods that are already running?"
a = "Admission webhooks are called when requests such as creates and updates reach the Kubernetes API server, according to Kubernetes' documentation on admission webhooks. We found nothing in policy-controller's documentation describing re-verification of running pods, so treat existing workloads as unchecked until they are redeployed."
+++

If your CI pipeline signs container images but your cluster will pull anything, the signatures protect nothing. The enforcement step is an admission controller that checks each image before Kubernetes starts it. **Sigstore policy-controller** is one such controller, built to verify signatures and attestations created with cosign (Sigstore's signing tool). This guide explains how it decides, how to write a keyless policy pinned to a specific GitHub Actions workflow, and how to roll it out without locking yourself out of your own cluster.

This is a follow-up to our article on [signing images with cosign and why verification must pin an identity](/posts/cosign-container-image-signing-keyless-signing-in-ci-and-why-verification-must-pin-an-identity/). We read the Sigstore policy-controller documentation, its README and Helm chart files, Sigstore's CI quickstart, GitHub's OIDC documentation and Kubernetes' admission webhook documentation on October 14, 2026. We did not install policy-controller or run any manifest below, so this is research-based explanation, not tested configuration. Placeholders in angle brackets are for you to fill in.

## The short answer

Install policy-controller, label the namespaces you want checked, and create a `ClusterImagePolicy` that names the image patterns to check and the identities allowed to have signed them. Start in `warn` mode, decide what happens to images that match no policy, and give the webhook more than one replica before you switch any production namespace to enforcement, because the chart's default failure policy rejects requests when the webhook is unreachable.

## What an admission controller does here

A Kubernetes admission webhook is an HTTPS service the API server calls when matching requests arrive, such as creating or updating a Deployment. A validating webhook can reject the request. Policy-controller's overview describes it as an admission controller that enforces policy using verifiable supply-chain metadata from cosign, and says it can validate signatures and attestations on container images and apply policies written in CUE or Rego against attestations. The same page notes the component is "still actively under development."

Two details from the documentation shape everything else:

- **It matches by digest.** Image patterns are matched against image digests, and the controller resolves tags to digests so the running image matches what was admitted. A tag like `:1.4` can move; a digest cannot.
- **It is opt-in per namespace.** Out of the box, only namespaces labelled `policy.sigstore.dev/include: "true"` are validated.

## Install and opt in

The installation page lists these steps, with Helm v3 and a cluster you can reach with `kubectl` as prerequisites:

```bash
helm repo add sigstore https://sigstore.github.io/helm-charts
helm repo update
kubectl create namespace cosign-system
helm install policy-controller -n cosign-system sigstore/policy-controller
kubectl get pods -n cosign-system
```

Then opt a namespace in, using the example command from the overview page:

```bash
kubectl label namespace <my-namespace> policy.sigstore.dev/include=true
```

The documentation does not give a minimum Kubernetes version. Pin the chart and image versions you deploy rather than relying on a floating install. When we read the chart's `Chart.yaml` on its main branch, it listed chart version 0.10.8 with `appVersion` 0.13.1, while the project's releases page listed v0.15.1 as the latest release and described v0.15.0 as upgrading cosign from v2 to v3. The release page shows dates without a year, so we do not date those releases. The practical point: check which controller version a chart install actually gives you, and read the release notes for cosign-version changes before you upgrade.

## Write a keyless policy pinned to one workflow

Policy-controller's documented structure is:

- `spec.images`: a list of `glob` patterns for the images the policy covers. Hosts default to `index.docker.io` and single-name images to `library`.
- `spec.authorities`: ways an image can pass. An authority is a `key` (public key, secret reference or KMS URI), a `keyless` block with Fulcio details and `identities`, or `static`, which passes or fails without checking a signature.
- `spec.mode`: set to `warn` to admit non-compliant images with a warning.
- `spec.match`: optionally limits the policy to resource kinds such as `deployments` or `jobs`.

For images signed by a GitHub Actions workflow with cosign keyless signing, the identity to pin has two parts. The issuer is the OIDC (OpenID Connect) token issuer, `https://token.actions.githubusercontent.com`, which GitHub's documentation lists. The subject is the signer identity in the certificate; Sigstore's CI quickstart shows it as `https://github.com/USERNAME/REPOSITORY_NAME/.github/workflows/WORKFLOW_NAME@refs/heads/BRANCH_NAME`.

A policy for images from your organization, accepting only the release workflow on version tags, would look like this, built from the documented fields:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: require-release-workflow-signature
spec:
  mode: warn
  images:
  - glob: "ghcr.io/<org>/**"
  authorities:
  - keyless:
      identities:
      - issuer: https://token.actions.githubusercontent.com
        subjectRegExp: https://github\.com/<org>/[^/]+/\.github/workflows/release\.yml@refs/tags/v.+
```

We have not applied this manifest. Before relying on it, test it with the project's `policy-tester` tool, which the README describes as checking a ClusterImagePolicy against an image. We also did not confirm whether the controller anchors regular expressions to the whole string or what Fulcio URL it uses when `url` is omitted, so check both for your version.

### A caution about the documentation's own regular-expression example

The overview page's GitHub Actions example uses this value for `subjectRegExp`:

```
https://github.com/mycompany/*/.github/workflows/*@*
```

Read as a regular expression, `*` repeats the preceding character instead of acting as a wildcard, and an unescaped `.` matches any character. We tested that string with Python's `re` module (the meanings of `.` and `*` are the same in Go's regular-expression syntax, but we did not run policy-controller itself). It did not match `https://github.com/mycompany/app/.github/workflows/build.yml@refs/heads/main`, and it did match the odd string `https://github.com/mycompany/.github/workflows@`. The example is probably shorthand, but copying it literally would either match nothing you intended or match things you did not. Write the expression the way the policy above does: escape dots, use `[^/]+` for one path segment, and name the workflow file and ref pattern you actually trust. We verified our own expression against three strings in Python: it matched a `release.yml` tag-ref identity under `mycompany/app`, and rejected both a branch-ref identity and a look-alike owner `mycompanyx`.

## How policies combine, and the traps

The overview says: every matching `ClusterImagePolicy` must pass, and within one policy any passing authority is enough.

- **Adding a second authority loosens a policy.** If one authority pins your release workflow and another accepts any signature from a public issuer, the second one wins. Keep authorities that mean the same trust level together and put different trust levels in different policies.
- **`static` authorities skip verification.** `action: pass` passes images with no signature check at all. Use only deliberately.
- **Overlapping globs stack.** An image matching two policies must satisfy both.

### Decide the no-match behavior first

Per the overview, an image that matches no policy is rejected unless the `config-policy-controller` ConfigMap in the release namespace sets `no-match-policy` to `warn`, `allow` or `deny`. With only your own registry covered by a policy, every third-party image, such as a sidecar or a base-image-derived job, in an opted-in namespace is a "no match". Choose between listing those registries in policies (with their own authorities), or setting `no-match-policy` explicitly. Release v0.15.0 notes say image references are now logged when no-match-policy is `warn` or `deny`, which helps you find what you forgot.

## Rolling out without an outage

1. **Run `policy-tester` against your real images** from CI, before touching the cluster.
2. **Label one non-critical namespace** and set `mode: warn`. Deploy normally and collect the warnings.
3. **Set `no-match-policy: warn`** for the pilot so third-party images surface as warnings, not failures.
4. **Fix identities you did not expect.** A warning on an image you thought was signed usually means the signing workflow or ref differs from your pattern.
5. **Switch the policy to enforce** (remove `mode: warn`, since by default an unsatisfied policy blocks admission) for that namespace only, then widen.

### The webhook is now in your deployment path

The Kubernetes documentation says `failurePolicy` controls what happens when calling the webhook fails: `Fail` means an error calling the webhook causes admission to fail and the request is rejected, `Ignore` lets the request continue; `Fail` is the default. Network errors, timeouts and bad responses are among the errors it covers. The timeout can be set between 1 and 30 seconds.

The policy-controller Helm chart's `values.yaml` on its main branch, which we read on October 14, 2026, sets `webhook.failurePolicy: Fail` and `webhook.replicaCount: 1`. We did not check which of the chart's webhook configurations that value feeds. Put together, and as our analysis rather than a tested result: a single webhook pod that is rescheduled, OOM-killed or unreachable could cause creates and updates in opted-in namespaces to be rejected until it returns. The opt-in label limits the blast radius to those namespaces, which is a reason to start small and to keep critical namespaces out until you have run the failure case in a test cluster: scale the webhook to zero and see what breaks. Raising the replica count is a chart value; whether you prefer fail-closed (safer against unsigned images, riskier for availability) or fail-open (the reverse) is a decision for your threat model, not a default to accept unread.

## What this does not prove

- **A signature is not a vulnerability assessment.** It shows which identity produced an image, not that the image is free of flaws. See our article on [what scanning still misses](/posts/container-image-scanning-what-ci-pipelines-still-miss/).
- **It checks requests, not running pods.** We found nothing in the documentation about re-verifying workloads that are already running.
- **Identity pins are only as good as your CI.** If an attacker can get a malicious change into the pinned workflow on the pinned ref, the signature will be valid. Pair this with locked-down workflow permissions and provenance checks from [SLSA attestations](/posts/slsa-build-levels-and-provenance-attestations-what-they-prove-and-what-they-dont/).
- **Documentation gaps remain.** The installation page does not describe webhook failure behavior, and the overview describes the project as under active development; check the release notes of the version you run.

## Sources and verification

| Important claim | Source | Verification |
|---|---|---|
| policy-controller validates cosign signatures and attestations; opt-in label policy.sigstore.dev/include; every matching policy must pass and any authority within one suffices; no-match-policy values and default rejection; ClusterImagePolicy fields; warn mode; tag-to-digest resolution; "still actively under development" | [Sigstore: Policy Controller overview](https://docs.sigstore.dev/policy-controller/overview/) | Verified: read October 14, 2026; project under active development |
| Helm install commands; prerequisites; no minimum Kubernetes version stated; webhook failure behavior not described | [Sigstore: policy-controller installation](https://docs.sigstore.dev/policy-controller/installation/) | Verified |
| policy-tester tool description | [policy-controller README](https://github.com/sigstore/policy-controller/blob/main/README.md) | Verified |
| v0.15.0 upgraded cosign v2 to v3 and logs image references under warn or deny no-match-policy; v0.15.1 latest listed | [policy-controller releases](https://github.com/sigstore/policy-controller/releases) | Qualified: page lists dates without a year; read October 14, 2026 |
| Chart main branch: chart 0.10.8, appVersion 0.13.1; webhook.failurePolicy Fail; replicaCount 1 | [Chart.yaml](https://github.com/sigstore/helm-charts/blob/main/charts/policy-controller/Chart.yaml) and [values.yaml](https://github.com/sigstore/helm-charts/blob/main/charts/policy-controller/values.yaml) | Qualified: main branch at time of reading; which webhook the value feeds not checked |
| failurePolicy semantics, Fail as default, timeout 1 to 30 seconds | [Kubernetes: dynamic admission control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) | Verified |
| GitHub Actions OIDC issuer URL | [GitHub Docs: OIDC reference](https://docs.github.com/en/actions/reference/security/oidc) | Verified |
| GitHub workflow signer identity format and verify flags | [Sigstore: CI quickstart](https://docs.sigstore.dev/quickstart/quickstart-ci/) | Verified |
| Docs example subjectRegExp does not match a typical repository path when read as a regular expression | Our test in Python's re module | Qualified: not run in policy-controller; Go regexp syntax for these characters is the same |
| Example policy and rollout order | Our analysis | Qualified: untested; editorial judgment |
