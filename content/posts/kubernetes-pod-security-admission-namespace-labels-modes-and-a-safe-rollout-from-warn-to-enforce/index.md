+++
title = "Kubernetes Pod Security Admission: Namespace Labels, Modes and a Safe Rollout from Warn to Enforce"
date = 2026-10-15T06:06:00Z
tags = ["cloud security", "process"]
categories = ["cloud-security"]
summary = "Pod Security Admission is the Kubernetes built-in that blocks risky pod settings per namespace. This guide explains the three levels, the three modes, the labels that control them, what it does not cover, and a rollout order that does not break running workloads."
description = "Kubernetes Pod Security Admission explained: privileged, baseline and restricted levels, enforce, audit and warn modes, namespace labels, exemptions, a dry-run rollout plan and a restricted-compliant pod example, based on the Kubernetes v1.37 documentation."
author = "FirewallSync Editorial"
imageAlt = "A silver combination padlock with a rusty shackle hanging on a black chain-link fence, with a blurred pale background"
imageCredit = "Photo by [Cody F](https://unsplash.com/photos/_H7IMLWa3n0) on Unsplash"
takeaways = [
  "Pod Security Admission (PSA) is a built-in Kubernetes admission controller that checks each new pod against one of three Pod Security Standards levels, privileged, baseline or restricted, chosen per namespace by labels. The Kubernetes documentation lists it as stable since v1.25.",
  "Each namespace can set three independent modes: enforce rejects the pod, audit adds an audit-log annotation, and warn returns a warning to the user. Each mode takes its own level and optionally its own pinned Kubernetes version.",
  "Enforce mode is applied to pods only, not to Deployments or Jobs. Audit and warn are applied to those workload objects too, which is why the documentation recommends turning them on first.",
  "A namespace with no PSA labels is not secure by default: unless the cluster administrator has configured different defaults, the documented default level for all three modes is privileged, which is unrestricted.",
  "Safe rollout order, from the Kubernetes docs: label namespaces with audit and warn first, test enforce changes with a server-side dry run, then set enforce. PSA checks pod fields only; it does not verify images, network paths or RBAC."
]

[[faq]]
q = "What is the difference between enforce, audit and warn in Pod Security Admission?"
a = "Per the Kubernetes documentation: enforce rejects a violating pod; audit allows it but adds an annotation to the audit-log event; warn allows it but shows the user a warning. A namespace can set any or all modes, at different levels."
[[faq]]
q = "Does Pod Security Admission replace PodSecurityPolicy?"
a = "The Kubernetes Enforcing Pod Security Standards page says the Pod Security Admission controller intends to replace the deprecated PodSecurityPolicies, and the PSA page links a migration guide for clusters moving off PodSecurityPolicy. It is not a one-to-one replacement: PSA offers three fixed levels and no custom policies."
[[faq]]
q = "Will enabling enforce kill my running pods?"
a = "The documentation describes PSA as applying restrictions when pods are created, and says that labelling a namespace with a new enforce level tests existing pods and returns violations to you as warnings. We did not test this on a cluster, so confirm with a server-side dry run before you label."
[[faq]]
q = "Do I need to install anything to use Pod Security Admission?"
a = "No separate install is needed on versions where it is enabled. The Kubernetes docs say it was available by default in v1.23 as a beta and has been generally available since v1.25. Managed Kubernetes services may differ in what you can configure, so check your provider's documentation."
+++

Many Kubernetes clusters run workloads that could mount the host filesystem, share the host network or run as root, simply because nothing told the API server not to allow it. **Pod Security Admission** (PSA) is the built-in answer: a check that runs when a pod is created and compares its settings with a named standard. This guide explains how it works and gives an order of operations that avoids breaking deployments.

**Scope.** This is research-based analysis of the official Kubernetes documentation as published for v1.37 on October 15, 2026 (the site's configured latest version). We did not run a cluster for this article; the manifests and commands below are taken from, or built from, the documentation and are untested by us. If you run an older Kubernetes version, read that version's docs: some controls carry version markers, such as host probes, which the docs tag "v1.34+".

## What PSA is and where it sits

The [Pod Security Admission documentation](https://kubernetes.io/docs/concepts/security/pod-security-admission/) describes a built-in *admission controller*, a component that inspects API requests after authentication and authorization and before objects are stored, and enforces the [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/). Restrictions are applied at the *namespace* level when pods are created. The [admission controllers reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#podsecurity) lists it as a validating controller, meaning it can accept or reject a request but not modify it.

Two practical consequences follow:

- It looks only at the **pod specification**. It does not check which image is running, whether the image is signed (see our guide to [verifying signed images with policy-controller](/posts/verify-signed-container-images-in-kubernetes-sigstore-policy-controller-keyless-policy-and-rollout/)), whether the image is vulnerable ([what scanning misses](/posts/container-image-scanning-what-ci-pipelines-still-miss/)), or what network and RBAC permissions the pod has.
- It offers **three fixed levels and no custom rules**. If you need, for instance, an allowlist of registries, the Kubernetes docs point to third-party tools such as Kubewarden, Kyverno and OPA Gatekeeper, and say that using any of them is better than doing nothing.

## The three levels

The standards are cumulative, from permissive to restrictive:

| Level | What the docs say it is for | Practical meaning |
|---|---|---|
| `privileged` | Unrestricted; "purposely-open"; aimed at system and infrastructure workloads run by privileged, trusted users | Pods may bypass normal container isolation, for example use the node's host network |
| `baseline` | Minimally restrictive; prevents known privilege escalations; allows the default, minimally specified pod | Blocks, for example, privileged containers, host namespaces (`hostNetwork`, `hostPID`, `hostIPC`), hostPath volumes and added capabilities outside a short allowed list |
| `restricted` | Heavily restricted; follows current pod hardening best practices | Everything in baseline, plus the controls in the next section |

### What `restricted` adds on top of baseline

From the Pod Security Standards page for this version:

| Control | Requirement |
|---|---|
| Volume types | Only `configMap`, `csi`, `downwardAPI`, `emptyDir`, `ephemeral`, `persistentVolumeClaim`, `projected` and `secret` volumes |
| Privilege escalation | `allowPrivilegeEscalation` must be `false` (Linux pods only) |
| Run as non-root | `runAsNonRoot` must be `true` (may be set at pod level) |
| Non-root user | `runAsUser` must not be `0` (undefined is allowed) |
| Seccomp | Profile type must be set to `RuntimeDefault` or `Localhost`; unset and `Unconfined` are not allowed (Linux pods only) |
| Capabilities | Containers must drop `ALL`; only `NET_BIND_SERVICE` may be added back (Linux pods only) |

Baseline itself also restricts, among other things, `hostPort` (the built-in controller does not support the docs' "known list" option, so effectively no host ports), the SELinux type and the AppArmor profile type. Read the [full tables](https://kubernetes.io/docs/concepts/security/pod-security-standards/) before choosing a level for workloads such as node agents or ingress controllers, which often need exceptions.

## The three modes and the labels that control them

A namespace opts in with labels. The [docs](https://kubernetes.io/docs/concepts/security/pod-security-admission/) define the modes this way:

| Mode | Effect on a violating pod |
|---|---|
| `enforce` | The pod is rejected |
| `audit` | Allowed, but an annotation is added to the event in the [audit log](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/) |
| `warn` | Allowed, but the user sees a warning |

For each mode there are two labels:

```yaml
pod-security.kubernetes.io/<MODE>: <LEVEL>          # privileged | baseline | restricted
pod-security.kubernetes.io/<MODE>-version: <VERSION> # a Kubernetes minor version such as v1.37, or latest
```

A namespace may set any or all modes, at different levels. The version label pins the rules to those that shipped with a given Kubernetes minor version. The docs' own example pins to the current version, v1.37. Pinning avoids a surprise when a cluster upgrade tightens a level, while `latest` always tracks the running version. The docs suggest a useful pattern: keep `enforce` pinned and set `audit` and `warn` to the same level at `latest`, which surfaces settings that older rules allowed but current best practice does not.

Here is the docs' example, which blocks pods failing `baseline` and warns about, and audits, anything failing `restricted`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-baseline-namespace
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/enforce-version: v1.37
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: v1.37
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: v1.37
```

### Unlabeled namespaces default to privileged

This is the most common misunderstanding. The [admission controller configuration page](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-admission-controller/) shows cluster-wide defaults applied "when a mode label is not set," and lists `privileged` as the default level for each mode and `latest` as the default version. So a namespace with no labels is, by default, unrestricted, unless an administrator changed it. The "Enforcing Pod Security Standards" page calls namespaces lacking any configuration "significant gaps in your cluster security model" and suggests treating them as "yet to be evaluated."

Cluster defaults and exemptions are set through an `AdmissionConfiguration` file passed to the API server with `--admission-control-config-file`. On managed Kubernetes services you may not control API server flags; we did not check any provider's options.

## Pods versus Deployments: where enforcement happens

Pods are usually created indirectly, by a controller acting on a Deployment or Job template. The docs state that audit and warn modes apply to those workload resources too, "to help catch violations early," but that **enforce mode is not applied to workload resources, only to the resulting pod objects**.

Our reading, which we have not tested: a Deployment that violates an enforced level can be accepted by the API server while its pods are then refused, so the failure appears as missing pods rather than a rejected `kubectl apply`. If you see a Deployment with zero ready replicas after labeling a namespace, look at the events on its ReplicaSet. Having `warn` set at the same level gives the person applying the manifest an immediate message.

## Exemptions, and the one that backfires

PSA can skip checks by exempting usernames, runtime class names or entire namespaces. Exempted requests are ignored entirely, with all three modes skipped. The documentation adds a caution: most pods are created by controllers, so exempting an end user exempts them only when creating pods directly, not when creating workload resources; and controller service accounts such as `system:serviceaccount:kube-system:replicaset-controller` "should generally not be exempted," because that would implicitly exempt anyone who can create the corresponding workload.

Separately, updates that change only certain fields are not rechecked, so an already-running violating pod can still receive those updates: metadata changes (except seccomp or AppArmor annotations), valid updates to `.spec.activeDeadlineSeconds`, and valid updates to `.spec.tolerations`.

## A rollout that follows the Kubernetes guidance

Apply this order, adapted from the [namespace labels task](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/) and the [enforcement best practices](https://kubernetes.io/docs/setup/best-practices/enforcing-pod-security-standards/):

1. **Inventory.** Find namespaces with no `enforce` label (the docs' command):
   ```bash
   kubectl get namespaces --selector='!pod-security.kubernetes.io/enforce'
   ```
2. **Turn on visibility, not blocking.** The docs' suggested first step for all namespaces:
   ```bash
   kubectl label --overwrite ns --all \
     pod-security.kubernetes.io/audit=baseline \
     pod-security.kubernetes.io/warn=baseline
   ```
   The docs deliberately leave `enforce` unset so that unevaluated namespaces remain distinguishable. Collect the warnings and audit annotations, then set the target level per namespace. In the docs' words: "set to the desired level and version you would eventually like to enforce."
3. **Dry-run the enforce label.** The docs' server-side dry run shows how the new level would treat existing pods without changing anything:
   ```bash
   kubectl label --dry-run=server --overwrite ns --all \
     pod-security.kubernetes.io/enforce=baseline
   ```
   The docs note that when an enforce label is added or changed, the admission plugin tests every pod in the namespace and returns violations as warnings.
4. **Enforce namespace by namespace**, pinned to a version:
   ```bash
   kubectl label --overwrite ns my-existing-namespace \
     pod-security.kubernetes.io/enforce=restricted \
     pod-security.kubernetes.io/enforce-version=v1.37
   ```
5. **Keep `warn` and `audit` on** at the same level as enforce so authors get feedback.
6. **Put privileged workloads in their own namespaces** and document why, as the docs advise: namespaces allowing `privileged` workloads "should establish and enforce appropriate access controls."

Also consider monitoring. The kube-apiserver exposes `pod_security_evaluations_total`, `pod_security_exemptions_total` and `pod_security_errors_total`. The docs warn that non-fatal evaluation errors "may result in the latest restricted profile being used for enforcement," so a rise in errors is worth an alert.

## An example pod that should satisfy `restricted`

We built this from the controls above; we have not run it against a cluster. The image name is a placeholder, and your image must really be able to run as a non-root user, otherwise the container will start and then fail.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-example
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: registry.example.com/team/app:1.0.0   # placeholder
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

Check against the table: `emptyDir` is an allowed volume type; `allowPrivilegeEscalation` is `false`; `runAsNonRoot` is `true` at pod level, which the docs permit in place of per-container values; seccomp is `RuntimeDefault` at pod level; `ALL` capabilities are dropped and none are added. The usual failure causes when you move an existing workload to `restricted` are a missing seccomp profile, a missing `drop: ["ALL"]`, an image whose default user is root, and a volume type outside the allowed list such as `hostPath`.

## Where PSA is not enough

- **Windows pods.** Several restricted controls (privilege escalation, seccomp, Linux capabilities) apply only when `spec.os.name` is not `windows`, and the docs warn that clusters containing nodes older than v1.24 should pin restricted policies to a version before v1.25.
- **Policy beyond pod fields.** Registry allowlists, required labels, resource limits and image signatures need another policy engine.
- **Pods that need privilege.** Node-level agents and some storage or networking components legitimately need `privileged`; isolate them rather than weakening everything.
- **Detection.** PSA reduces what can be created; it does not tell you what already runs. Pair it with the practices in our [cloud misconfiguration guide](/posts/cloud-misconfiguration-checklists-dont-work-heres-what-does/) and identity hygiene from [least privilege without slowing teams](/posts/least-privilege-access-controls-that-dont-slow-teams-down/).

## Limits of this article

We did not run any of the commands or manifests. We read the Kubernetes documentation source for the v1.37 site on October 15, 2026; older and newer versions may differ, and we did not check any managed Kubernetes provider's behavior. The statement about where enforce failures surface for Deployments is our inference from the documented scope of enforce mode.

## Sources and verification

Checked on October 15, 2026, against the Kubernetes documentation source (kubernetes/website, main branch; site latest version v1.37).

| Important claim | Source | Verification |
|---|---|---|
| PSA enforces Pod Security Standards per namespace at pod creation; stable v1.25; levels; modes and labels; version label; workload-resource behavior; exemptions and caution; field-update exemptions; metrics | [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) | Verified |
| Level definitions; baseline and restricted controls; Windows/OS-specific controls; alternatives (Kubewarden, Kyverno, OPA Gatekeeper) | [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) | Verified |
| Example labels, `kubectl` commands, enforce-label warning behavior, dry run | [Enforce Pod Security Standards with Namespace Labels](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/) | Verified; commands not run by us |
| Default level privileged and version latest; AdmissionConfiguration; `--admission-control-config-file`; beta in v1.23, GA from v1.25 | [Enforce Pod Security Standards by Configuring the Built-in Admission Controller](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-admission-controller/) | Verified |
| Unlabeled namespaces as gaps; multi-mode strategy; least privilege; intent to replace PodSecurityPolicies | [Enforcing Pod Security Standards](https://kubernetes.io/docs/setup/best-practices/enforcing-pod-security-standards/) | Verified |
| PSA is a validating admission controller | [Admission Controllers reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#podsecurity) | Verified |
| Existing running pods are not terminated by an enforce label | Inferred from "applied when pods are created" and the warning behavior | Qualified: not tested |
| Failure for Deployments shows as missing pods / ReplicaSet events | Our inference from documented enforce scope | Qualified: not tested |
| Example restricted pod compliance | Our check against the restricted control table | Qualified: not run on a cluster |
