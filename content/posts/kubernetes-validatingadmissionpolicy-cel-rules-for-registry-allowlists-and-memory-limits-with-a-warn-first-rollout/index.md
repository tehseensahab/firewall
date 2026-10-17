+++
title = "Kubernetes ValidatingAdmissionPolicy: CEL Rules for Registry Allowlists and Memory Limits, with a Warn-First Rollout"
date = 2026-10-17T06:05:00Z
tags = ["cloud security", "process"]
categories = ["cloud-security"]
summary = "ValidatingAdmissionPolicy lets the Kubernetes API server enforce custom rules written in CEL, with no webhook to run. This guide shows the policy, binding and parameter model, two worked rules that Pod Security Admission cannot express, and a rollout order that goes from Warn and Audit to Deny."
description = "Kubernetes ValidatingAdmissionPolicy explained: policy and binding resources, CEL expressions, Deny, Warn and Audit actions, failurePolicy, matchConditions, an image-registry allowlist and a memory-limit rule, and a warn-first rollout, based on the Kubernetes v1.37 documentation."
author = "John Marshall"
imageAlt = "Large architectural floor-plan drawings printed on white paper and spread overlapping across a table"
imageCredit = "Photo by [Marina Zvada](https://unsplash.com/photos/fNxmdlYHRm8) on Unsplash"
takeaways = [
  "ValidatingAdmissionPolicy (VAP) is a Kubernetes API-server feature that evaluates rules written in the Common Expression Language (CEL) at admission time, in-process, as an alternative to validating admission webhooks. The Kubernetes documentation lists it as stable since v1.30.",
  "A policy has no effect on its own: you need a ValidatingAdmissionPolicy (the logic) and a ValidatingAdmissionPolicyBinding (the scope and the action). Optional parameter resources let one policy carry different values per binding.",
  "Each binding chooses one or more actions: Deny, Warn or Audit. The docs say Deny and Warn cannot be combined, so a safe rollout is Warn plus Audit first, then Deny.",
  "failurePolicy decides what happens when the policy itself errors. It defaults to Fail (reject the request); Ignore lets the request through. A policy that errors silently under Ignore enforces nothing.",
  "VAP checks fields of the object in the request. Our two example rules, an image-registry prefix allowlist and required memory limits, cover gaps that Pod Security Admission does not address. Neither verifies image contents or signatures."
]

[[faq]]
q = "Is ValidatingAdmissionPolicy a replacement for Pod Security Admission?"
a = "No. Pod Security Admission offers three fixed levels and no custom rules. ValidatingAdmissionPolicy lets you write your own rules in CEL. They are complementary: the Kubernetes docs describe both as validating admission mechanisms, and nothing in them says to use one instead of the other."
[[faq]]
q = "Do I need to install a webhook server to use it?"
a = "No. The Kubernetes documentation describes validating admission policies as a declarative, in-process alternative to validating admission webhooks: the expressions run inside the API server. On v1.37 the ValidatingAdmissionPolicy admission controller appears in the documented list of plugins enabled by default. Managed Kubernetes services may differ, so check your provider."
[[faq]]
q = "Can Deny and Warn be used together in one binding?"
a = "No. The documentation says Deny and Warn may not be used together because the combination would duplicate the failure in the API response body and in the HTTP warning headers. Deny with Audit, or Warn with Audit, are allowed combinations."
[[faq]]
q = "What happens if my CEL expression has a bug?"
a = "Syntax errors are rejected when you create the policy. Type errors are reported in status.typeChecking but, per the docs, do not change the policy's behavior. Errors at evaluation time follow failurePolicy: Fail rejects the request, Ignore lets it through."
[[faq]]
q = "Does a registry allowlist prove an image is safe?"
a = "No. A prefix check only tells you where the image reference points. It does not check what is in the image, whether it is vulnerable, or whether it is signed. See our guides to image scanning and to verifying signed images."
+++

Kubernetes has a built-in way to reject a workload for breaking *your* rules, not just the generic ones: **ValidatingAdmissionPolicy** (VAP). You write a rule such as "every container image must start with `registry.example.com/`" in the Common Expression Language (CEL), and the API server evaluates it whenever a matching object is created or updated. There is no webhook server to run, patch or keep available. This guide explains the three resources involved, shows two worked rules, and gives a rollout order that does not break deployments on day one.

**Scope.** This is research-based analysis of the Kubernetes documentation pages listed under Sources and verification, read on October 17, 2026 (the site's latest version is v1.37). We did not run a cluster. We did evaluate the CEL expressions below against sample Pod objects with the open-source `cel-go` library (version 0.32.0), which confirms the logic but is not the Kubernetes API server's own CEL environment. Treat the manifests as untested drafts and try them in a non-production cluster first.

## What VAP is, and where it sits

The Kubernetes [Validating Admission Policy page](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) describes validating admission policies as "a declarative, in-process alternative to validating admission webhooks", using CEL to declare validation rules. The page marks the feature "Stable since Kubernetes v1.30". An *admission controller* is a component that intercepts API requests after authentication and authorization and before the object is stored; the [admission controllers reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) lists `ValidatingAdmissionPolicy` among the plugins enabled by default in Kubernetes 1.37.

How it compares with the options you may already know:

| | Pod Security Admission | ValidatingAdmissionPolicy | Validating webhook |
|---|---|---|---|
| Rules | Three fixed levels | Your own CEL expressions | Your own code |
| Runs | In the API server | In the API server | In a separate service the API server calls over HTTP |
| Can modify the object | No | No (validating only; mutation is a separate feature, MutatingAdmissionPolicy) | No (mutating webhooks are a separate type) |
| Best for | Pod hardening baseline | Field-level rules on any resource | Logic CEL cannot express, or external lookups |

PSA's own documentation points to third-party engines for rules such as registry allowlists; see our [Pod Security Admission guide](/posts/kubernetes-pod-security-admission-namespace-labels-modes-and-a-safe-rollout-from-warn-to-enforce/). VAP is the built-in route for many of those rules.

## The three resources

Per the docs, a policy generally has three parts:

- **ValidatingAdmissionPolicy**: the abstract logic and the resource types it applies to (`matchConstraints`).
- **ValidatingAdmissionPolicyBinding**: links a policy to a scope and chooses what happens on failure (`validationActions`). "At least a ValidatingAdmissionPolicy and a corresponding ValidatingAdmissionPolicyBinding must be defined for a policy to have an effect."
- **A parameter resource** (optional): a ConfigMap or custom resource that supplies concrete values. The docs' example is a `ReplicaLimit` resource with `maxReplicas: 3` for test namespaces and another with `maxReplicas: 100` for the rest, both used by the same policy through two bindings.

If you use no parameters, leave `spec.paramKind` unset.

## Worked rule 1: image registry allowlist for Pods

**Goal.** Reject Pods in which any container or init container uses an image outside `registry.example.com/`. The registry name is a placeholder.

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: allowed-registry.example.com
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups:   [""]
      apiVersions: ["v1"]
      operations:  ["CREATE", "UPDATE"]
      resources:   ["pods"]
  variables:
  - name: allContainers
    expression: >-
      object.spec.containers +
      (has(object.spec.initContainers) ? object.spec.initContainers : [])
  validations:
  - expression: "variables.allContainers.all(c, c.image.startsWith('registry.example.com/'))"
    messageExpression: >-
      'images not from registry.example.com: ' +
      variables.allContainers.filter(c, !c.image.startsWith('registry.example.com/'))
        .map(c, c.image).join(', ')
    reason: Forbidden
```

How to read it:

- `variables` are named sub-expressions, evaluated lazily, that later expressions reference as `variables.<name>`. The docs recommend them when an expression gets complicated or is reused.
- `has(object.spec.initContainers)` guards the optional field. The docs explain that CEL's `has()` checks whether a field is present before the expression reads it.
- The trailing `/` in the prefix matters. `registry.example.com.evil.net/app` does not start with `registry.example.com/`, so a look-alike hostname fails the check. We confirmed this case in our `cel-go` run.
- `messageExpression` builds the denial message from the offending images. Per the docs, if the message expression fails to evaluate, the static `message` is used instead, and a multi-line result is discarded.
- `reason: Forbidden` is one of the four documented values (`Unauthorized`, `Forbidden`, `Invalid`, `RequestEntityTooLarge`). It sets the machine-readable reason and HTTP status of the first failing validation.

**Our `cel-go` results** (sample Pods, expression result): a Pod with only registry-prefixed images, with and without init containers, evaluated `true`; a Pod using `docker.io/library/nginx:1` evaluated `false`; a Pod with a bad image only in an init container evaluated `false`; the look-alike hostname evaluated `false`.

**What this rule does not cover:**

- *Ephemeral containers.* They are added through a different API subresource that `resources: ["pods"]` does not match. We did not test how the API server handles them.
- *Digest pinning and signatures.* A prefix does not stop someone pushing a malicious image to your own registry. For that, see [verifying signed images with policy-controller](/posts/verify-signed-container-images-in-kubernetes-sigstore-policy-controller-keyless-policy-and-rollout/) and [what image scanning misses](/posts/container-image-scanning-what-ci-pipelines-still-miss/).
- *Existing Pods on UPDATE.* Because the policy matches `UPDATE` as well as `CREATE`, our reading (untested) is that editing an already-running Pod that violates the rule would also be evaluated. Drop `UPDATE` if you only want to gate new Pods.

## Worked rule 2: every container needs a memory limit

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-memory-limit.example.com
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups:   [""]
      apiVersions: ["v1"]
      operations:  ["CREATE"]
      resources:   ["pods"]
  validations:
  - expression: >-
      object.spec.containers.all(c,
        has(c.resources) && has(c.resources.limits) && 'memory' in c.resources.limits)
    message: "every container must set resources.limits.memory"
    reason: Invalid
```

The docs' advice for maps is to use the `in` operator to test whether a key exists, which is what `'memory' in c.resources.limits` does. In our `cel-go` run, a container with a memory limit evaluated `true`; one with no `resources` block and one with only a CPU limit both evaluated `false`. This rule checks init containers only if you extend it the same way as rule 1. Be aware that a cluster may apply default limits through a LimitRange, in which case Pods may already carry limits by the time admission policies see them. We did not verify the ordering of those two mechanisms, so test this in your own cluster.

## Bindings: scope and actions

A binding says where the policy applies and what a failure does. This one excludes the `kube-system` namespace and starts in observation mode:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: allowed-registry-binding.example.com
spec:
  policyName: allowed-registry.example.com
  validationActions: [Warn, Audit]
  matchResources:
    namespaceSelector:
      matchExpressions:
      - key: kubernetes.io/metadata.name
        operator: NotIn
        values: ["kube-system"]
```

The Kubernetes [well-known labels page](https://kubernetes.io/docs/reference/labels-annotations-taints/) says the API server sets `kubernetes.io/metadata.name` on all namespaces, with the namespace's name as the value, and that it cannot be changed. That makes it a dependable selector. Whether `kube-system` should be excluded at all is your call; system components may use images from other registries.

The three actions, per the docs:

| Action | What a failure does |
|---|---|
| `Deny` | The request is rejected |
| `Warn` | The request is allowed and the client receives a warning |
| `Audit` | The request is allowed and the failure is recorded in the audit event for the request |

Deny and Warn "may not be used together". Deny with Audit is therefore the production end state, and Warn with Audit is the observation state.

## What happens when several policies or bindings apply

For each request, the API server evaluates every matching (policy, binding, parameter) combination, and the request is admitted only if all of them pass. The docs state that a policy may be evaluated several times if multiple bindings match, and that overlapping bindings are allowed. The practical effect: adding a second, stricter binding never loosens an existing one.

## `failurePolicy`: the setting that can silently disable a rule

`failurePolicy` is set on the policy and governs errors in the policy itself, such as a misconfiguration or a CEL expression that errors at runtime. `Fail` (the default) rejects the request; `Ignore` lets it continue. Two consequences:

- Under `Ignore`, a broken expression enforces nothing and nobody is told. If you choose `Ignore` to avoid blocking deployments, watch for errors another way.
- Under `Fail`, a policy that errors on a field you did not guard with `has()` can block every matching request. This is why the Warn-first rollout below matters.

The docs also say a validation that simply evaluates to false is always enforced according to the binding's actions, whatever `failurePolicy` says.

## Catch mistakes before they run

- **Type checking.** When a policy is created or updated, expressions are parsed and syntax errors cause rejection. Referenced fields are then type-checked against the matched resource types, with results in `status.typeChecking`. Per the docs, type checking does not affect behavior, does not apply to custom resources, skips wildcard matches, and covers at most 10 matched types. Inspect it with `kubectl get validatingadmissionpolicy <name> -o yaml` after creation.
- **Cost limits.** The [CEL in Kubernetes page](https://kubernetes.io/docs/reference/using-api/cel/) says all expressions run under a runtime cost budget, and that the API server may reject expressions whose worst-case estimated cost is too high when they are written. Deeply nested `all`/`filter` loops over large lists are where you would run into this.
- **`matchConditions`** filter requests with CEL before the policy runs. Per the docs, `namespaceObject` is null in match conditions, so use a `namespaceSelector` to select by namespace labels. If any match condition is false, the policy is skipped; if a match condition errors and none is false, `failurePolicy` decides.

## A rollout order

Our suggested order, built on the documented actions. We have not run it on a cluster.

1. **Write the policy and a binding with `[Warn, Audit]`**, scoped to one non-production namespace.
2. **Check `status.typeChecking`** for the policy and fix any warnings.
3. **Apply a known-good and a known-bad manifest** in that namespace and confirm the client sees a warning for the bad one only. Look in the API server audit log for the validation-failure annotation (see the docs' [audit annotations](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#audit-annotations) section). Audit-log availability depends on your cluster's audit policy.
4. **Widen the namespace selector** and let real deployments generate warnings for a period you choose. Fix or exempt what shows up.
5. **Switch the binding to `[Deny, Audit]`**, one namespace group at a time.
6. **Keep the policy in version control.** The docs warn that "Validating Admission Policy is part of the cluster control-plane. You should write and deploy them with great caution."

One more documented limit: policies created through the REST API cannot intercept ValidatingAdmissionPolicy or binding objects themselves, nor TokenReview-style authentication and authorization review kinds, which are exempt to avoid lock-out. So a user who can edit bindings can switch a policy off; guard that with RBAC.

## Limits of this article

We did not run a Kubernetes cluster. The `cel-go` check uses generic dynamic types, not Kubernetes' typed objects or its CEL environment, so a policy can pass our check and still draw a type-checking warning in a real cluster. We did not test how LimitRange defaults, ephemeral containers or `UPDATE` operations interact with these rules. Behavior may differ by Kubernetes version and by managed-service provider; the documented feature state is for v1.30 and later.

## Sources and verification

Documentation read October 17, 2026. The Validating Admission Policy page shows "Last modified September 28, 2026"; the CEL page shows August 13, 2026.

| Important claim | Source | Verification |
|---|---|---|
| VAP is a declarative, in-process alternative to validating webhooks using CEL; stable since v1.30 | [Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) | Verified |
| Policy plus binding required; optional parameter resources; example `ReplicaLimit` bindings | [Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) | Verified |
| Actions Deny, Warn, Audit; Deny and Warn cannot be combined | [Validating Admission Policy: validation actions](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#validation-actions) | Verified |
| `failurePolicy` values Fail (default) and Ignore; failing validations always follow binding actions | [Validating Admission Policy: failure policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#failure-policy) | Verified |
| All matching policy/binding/parameter combinations must pass | [Validating Admission Policy: parameter resources](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#parameter-resources) | Verified |
| `has()`, `in` for map keys; variables; messageExpression behavior; reason values | [Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) | Verified |
| matchConditions semantics; `namespaceObject` null in match conditions | [Validating Admission Policy: matchConditions](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#matching-requests-matchconditions) | Verified |
| Type-checking behavior and limits | [Validating Admission Policy: type checking](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#type-checking) | Verified |
| Exempt kinds for REST-created policies | [Validating Admission Policy: exempt kinds](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#api-kinds-exempt-from-admission-validation) | Verified |
| ValidatingAdmissionPolicy is in the default-enabled plugin list for Kubernetes 1.37 | [Admission Controllers reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) | Qualified: the same page's per-plugin text still mentions v1alpha1 prerequisites; we rely on the default list |
| API server sets immutable `kubernetes.io/metadata.name` label on all namespaces | [Well-Known Labels, Annotations and Taints](https://kubernetes.io/docs/reference/labels-annotations-taints/) | Verified |
| Runtime cost budget; estimated-cost rejection at write time | [CEL in Kubernetes](https://kubernetes.io/docs/reference/using-api/cel/) | Verified |
| The two example expressions give the stated true/false results on sample Pods | Our run of `cel-go` v0.32.0, October 17, 2026 | Qualified: not the Kubernetes CEL environment; not run on a cluster |
| Ephemeral containers, LimitRange ordering and UPDATE effects | Our inference | Qualified: not tested |
