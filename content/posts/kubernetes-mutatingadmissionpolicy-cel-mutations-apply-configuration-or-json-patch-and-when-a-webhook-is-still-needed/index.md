+++
title = "Kubernetes MutatingAdmissionPolicy: CEL Mutations with Apply Configuration or JSON Patch, and When a Webhook Is Still Needed"
date = 2026-10-18T06:05:00Z
tags = ["kubernetes", "process"]
categories = ["cloud-security"]
summary = "MutatingAdmissionPolicy lets the Kubernetes API server change incoming objects with CEL expressions instead of calling a webhook. This guide covers the three resources, the two patch types, reinvocation, failure behavior, what the docs do not say, and a cautious rollout."
description = "Kubernetes MutatingAdmissionPolicy explained: stable since v1.36, policy and binding resources, ApplyConfiguration versus JSONPatch mutations, reinvocationPolicy, failurePolicy, matchConditions, exempt kinds, how it differs from mutating webhooks, and a cautious rollout, based on the v1.37 documentation."
author = "John Marshall"
imageAlt = "A close-up of a red industrial valve with black solenoid connectors, an orange cable and silver pipework, with a blurred corridor behind"
imageCredit = "Photo by [Rose Galloway Green](https://unsplash.com/photos/o6asPZdUjUs) on Unsplash"
takeaways = [
  "MutatingAdmissionPolicy (MAP) is a Kubernetes API-server feature that rewrites incoming objects using expressions in the Common Expression Language (CEL), with no external webhook server. The Kubernetes documentation lists it as stable since v1.36 and enabled by default; it was first available in v1.30.",
  "A policy does nothing until a MutatingAdmissionPolicyBinding references it. Each policy needs at least one mutation, written either as an apply configuration (merged like server-side apply) or as a JSON Patch.",
  "reinvocationPolicy is a required field with two values, Never and IfNeeded. With IfNeeded the mutation can run more than once per request, so write it to be safe to repeat. The docs' own example guards against adding the same container twice.",
  "Unlike ValidatingAdmissionPolicyBinding, the MAP binding has no Warn or Audit action. Its three fields are policyName, paramRef and matchResources, so a cautious rollout relies on narrow scoping and a test cluster, not a warn-only mode.",
  "A webhook is still the tool when the decision needs data or logic that is not in the request, the parameter resource or CEL. The docs describe MAP as in-process and free of external HTTP callouts."
]

[[faq]]
q = "Is MutatingAdmissionPolicy enabled by default?"
a = "The Kubernetes documentation states that it is stable since v1.36 and enabled by default, and the Admission Controllers reference lists MutatingAdmissionPolicy among the plugins enabled by default in Kubernetes 1.37. The per-plugin text on that same page still mentions an older v1alpha1 prerequisite, so check your own cluster's version and the kube-apiserver settings before relying on it."
[[faq]]
q = "Should I use ApplyConfiguration or JSONPatch?"
a = "The documentation offers both and does not rank them. An apply configuration describes the fields you want, as a CEL object, and is merged using server-side apply rules. A JSON Patch is a list of positional operations such as add, replace and test. Apply configuration is usually easier to read for adding fields, but it cannot modify atomic structs, maps or arrays. Choose JSON Patch when you need a precondition such as a test operation."
[[faq]]
q = "Can a MutatingAdmissionPolicy mutate other policies?"
a = "Not through the REST API. The documentation exempts ValidatingAdmissionPolicies, ValidatingAdmissionPolicyBindings, MutatingAdmissionPolicies and MutatingAdmissionPolicyBindings from policies created that way, to prevent circular dependencies. Policies defined through manifest-based admission control can intercept them."
[[faq]]
q = "Does a mutating policy run before or after validating policies?"
a = "Before. The Kubernetes admission-control documentation says mutating controllers run in the first phase and validating controllers in the second, and that a rejection in either phase rejects the whole request. A validating rule therefore sees the object after mutations."
[[faq]]
q = "Does MutatingAdmissionPolicy replace mutating webhooks?"
a = "For mutations that can be expressed from the request object, the old object, the parameter resource and CEL, it is an alternative that removes the webhook server. It cannot make external calls, and the documentation says it is an in-process alternative without HTTP callouts. If your mutation needs outside data, keep the webhook."
+++

A mutating admission policy answers a narrow question: when a request to create or update an object reaches the Kubernetes API server, should something in that object be changed before it is stored? Until recently the usual answer was a mutating webhook, which means running and securing a separate HTTPS service in the request path. **MutatingAdmissionPolicy** (MAP) moves the logic into the API server as declarative CEL expressions. This guide explains how it is built, what the documentation guarantees, and where you should still be careful.

**Scope and method.** This is research-based analysis of the Kubernetes v1.37 documentation, read on October 18, 2026: the Mutating Admission Policy page (last modified September 28, 2026), the MutatingAdmissionPolicy and MutatingAdmissionPolicyBinding API references (both last modified August 26, 2026), the Admission Controllers reference (last modified September 28, 2026) and the Dynamic Admission Control page. We did not run a Kubernetes cluster and did not test any policy against an API server. The only thing we ran ourselves is a check of generic JSON Patch behavior, described in the JSON Patch section and labelled there.

## The short answer

- **What it is.** A declarative, in-process alternative to mutating admission webhooks. Mutations are written in the Common Expression Language (CEL), the small expression language Kubernetes uses for admission rules.
- **Status.** The Kubernetes documentation says it is stable since v1.36 and enabled by default, and first became available in v1.30.
- **What you create.** A `MutatingAdmissionPolicy` (the logic), a `MutatingAdmissionPolicyBinding` (the scope), and optionally a parameter resource (the values). At least a policy and a matching binding must exist for anything to happen.
- **Where it runs.** In the mutating phase of admission, before the validating phase.
- **The catch.** It is part of the control plane. The documentation says to write and deploy these policies "with great caution".

## The three resources

| Resource | What it does | Notes from the documentation |
|---|---|---|
| MutatingAdmissionPolicy | The abstract logic: what to match, which mutations to apply | `matchConstraints` and `mutations` are required; `mutations` cannot be an empty list |
| Parameter resource (optional) | Concrete values, for example from a ConfigMap or a custom resource | Referenced by `spec.paramKind` in the policy and `paramRef` in the binding |
| MutatingAdmissionPolicyBinding | Links a policy to parameters and scopes it | Has three fields: `policyName`, `paramRef` and `matchResources` |

Two details are easy to miss. If a binding names a policy that does not exist, the API reference says the binding is "considered invalid and will be ignored". If the policy declares a `paramKind` and the binding's `paramRef` points to a resource that does not exist, the binding is treated as misconfigured and the policy's `failurePolicy` applies. Also, per binding, the policy is evaluated once, or once per selected parameter object if parameters are used, and each evaluation has a runtime cost budget.

## Which requests a policy sees

Matching is layered, and each layer can only narrow the previous one:

1. **`matchConstraints`** on the policy (required) selects resources and operations. The API reference says the operations CREATE, UPDATE and CONNECT are allowed and DELETE may not be matched.
2. **`matchResources`** on the binding narrows further. If it is unset, it does not constrain matching.
3. **`matchConditions`** on the policy are CEL expressions evaluated last. If any condition is false the policy is skipped; if none is false but one errors, `failurePolicy` decides. A policy may have at most 64 match conditions.

The documentation notes that `namespaceObject` is always null in match conditions and that `variables` cannot be used there, because match conditions are evaluated before the rest of the policy. To select by namespace labels, use a `namespaceSelector` in `matchConstraints` or in the binding's `matchResources`.

One more limit that affects design: the documentation says that only `apiVersion`, `kind`, `metadata.name`, `metadata.generateName` and `metadata.labels` are accessible from the root of the object, and that no other metadata properties are accessible. A rule that depends on an annotation, for example, cannot read it through `object`. This is the documented behavior; we have not tested workarounds.

## Two ways to express a mutation

Each entry in `spec.mutations` has a `patchType`, either `ApplyConfiguration` or `JSONPatch`.

### ApplyConfiguration

The expression must evaluate to a CEL object created with `Object{...}`, and the result is merged using the server-side apply merge strategy. This is the Kubernetes documentation's own example, which adds a `mesh-proxy` init container to new Pods that do not already have one:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionPolicy
metadata:
  name: "sidecar-policy.example.com"
spec:
  paramKind:
    kind: Sidecar
    apiVersion: mutations.example.com/v1
  matchConstraints:
    resourceRules:
    - apiGroups:   [""]
      apiVersions: ["v1"]
      operations:  ["CREATE"]
      resources:   ["pods"]
  matchConditions:
    - name: does-not-already-have-sidecar
      expression: "!object.spec.initContainers.exists(ic, ic.name == \"mesh-proxy\")"
  failurePolicy: Fail
  reinvocationPolicy: IfNeeded
  mutations:
    - patchType: "ApplyConfiguration"
      applyConfiguration:
        expression: >
          Object{
            spec: Object.spec{
              initContainers: [
                Object.spec.initContainers{
                  name: "mesh-proxy",
                  image: "mesh/proxy:v1.0.0",
                  args: ["proxy", "sidecar"],
                  restartPolicy: "Always"
                }
              ]
            }
          }
```

The documented restriction to remember: apply configurations may not modify atomic structs, maps or arrays, because of the risk of accidentally deleting values the configuration does not mention.

### JSONPatch

The expression must return an array of `JSONPatch{op, path, value}` values, following the [JSON Patch](https://jsonpatch.com/) format. The documentation's examples include a conditional change using a `test` operation before a `replace`, and a helper, `jsonpatch.escapeKey()`, for path keys that contain `/` or `~`. It escapes `~` as `~0` and `/` as `~1`, so a label such as `example.com/environment` can be addressed.

**Read the documentation's two sidecar examples side by side.** The page says the JSON Patch version writes "the same mutation", but the two examples are not identical: the apply-configuration example uses the image `mesh/proxy:v1.0.0` and sets `args`, while the JSON Patch example uses the image string `mesh-proxy/v1.0.0` and no `args`. Treat them as illustrations of syntax, not as a verified equivalence, and do not copy the image reference from either.

### What we tested about JSON Patch

On October 18, 2026 we ran a generic JSON Patch library (Python `jsonpatch` 1.35, an implementation of the RFC 6902 patch format) on small sample documents. This does not run the Kubernetes API server's implementation, so it shows how the format behaves, not how your cluster will.

| Patch | Document | Result |
|---|---|---|
| `add` to `/spec/initContainers/-` | Pod with an existing `initContainers` list | Appended the new item |
| Same `add` | Pod with no `initContainers` field | Error: member `initContainers` not found |
| `add` to `/metadata/labels/example.com~1environment` | Empty `labels` map | Added the key `example.com/environment` |
| `add` to `/metadata/labels/example.com/environment` (unescaped) | Empty `labels` map | Error: member `example.com` not found |
| `test` of `/spec/example` equal to `"Red"`, then `replace` with `"Green"` | `example` is `"Red"` | Replaced with `"Green"` |
| Same pair | `example` is `"Blue"` | Error: the test failed, nothing replaced |

The practical lesson is that a positional JSON Patch needs the parent path to exist and the key to be escaped. The documentation's sidecar example uses a match condition that reads `object.spec.initContainers`; whether that expression behaves well when the field is absent is something we did not verify and you should test. The Kubernetes documentation we read does not say what the API server does when a JSON Patch fails to apply, so do not assume it is silently skipped.

## Reinvocation: why your mutation must be safe to repeat

`reinvocationPolicy` is a required field on the policy, with two values:

- **Never:** the mutations are not called more than once per binding in a single admission evaluation.
- **IfNeeded:** they may be called more than once per binding for a single admission request, only when other mutations changed the object after this one ran. The API reference states there is no guarantee of order relative to other admission plugins, webhooks, bindings of this policy and other admission policies.

The reason is explained on the Dynamic Admission Control page: no single ordering of mutating plugins works for every case, so mutating plugins can be re-run so that they see changes made by others. That page also states that mutating webhooks must be idempotent, meaning able to process an object they have already modified. Our reading is that the same discipline applies to a policy using `IfNeeded`, which is why the documentation's example begins with a match condition that skips Pods that already have the `mesh-proxy` container. For comparison, the webhook field `reinvocationPolicy` defaults to `Never`.

## Failure behavior

`failurePolicy` accepts `Fail` or `Ignore` and defaults to `Fail`. The API reference says failures can come from CEL parse errors, type-check errors, runtime errors, and invalid or misconfigured policy definitions or bindings, such as a `paramKind` that refers to a non-existent kind. It does not define how validations that evaluate to false are handled; that is a validation concept, not a mutation one.

For a control-plane component, the difference matters. With `Fail`, an error in your expression can reject writes to every object you matched. With `Ignore`, the same error means the mutation is silently not applied, and anything that depended on it, such as a validating rule that expects the label to be there, may then reject the object or let a bad one through. The Admission Controllers page says that if any MutatingAdmissionPolicy fails, the request fails.

## How it fits with other admission mechanisms

The Admission Controllers reference says admission runs in two phases: mutating controllers first, then validating ones, and a rejection in either phase rejects the whole request.

- **With Pod Security Admission.** The reference lists the `PodSecurity` plugin as validating. Pods are therefore checked after mutation. See our guide to [Pod Security Admission](/posts/kubernetes-pod-security-admission-namespace-labels-modes-and-a-safe-rollout-from-warn-to-enforce/).
- **With ValidatingAdmissionPolicy.** A mutating policy can set a value that a validating policy then checks. Our [ValidatingAdmissionPolicy guide](/posts/kubernetes-validatingadmissionpolicy-cel-rules-for-registry-allowlists-and-memory-limits-with-a-warn-first-rollout/) covers the validating side, which has Deny, Warn and Audit actions that the MAP binding does not.
- **With webhooks.** Built-in mutating plugins are re-run if a mutating webhook modifies an object, per the Dynamic Admission Control page.

### Exempt kinds

Policies created through the REST API cannot mutate ValidatingAdmissionPolicies, their bindings, MutatingAdmissionPolicies or their bindings. The documentation says a policy loaded through manifest-based admission control can intercept those kinds. Separately, the non-persisted authentication and authorization review kinds (TokenReviews, SelfSubjectReviews, LocalSubjectAccessReviews, SelfSubjectAccessReviews, SelfSubjectRulesReviews and SubjectAccessReviews) are exempt from all admission policies, and the page says that starting with Kubernetes v1.37 admission webhooks also exclude them by default.

## MAP, VAP or webhook: a decision guide

| Your need | Fits | Why (from the documentation) |
|---|---|---|
| Reject requests that break a rule | ValidatingAdmissionPolicy | The MAP page calls it "a simpler and more effective alternative" for prevention-only rules |
| Add or default fields from the request, an existing object field or a parameter | MutatingAdmissionPolicy | Declarative, in-process, CEL-based, parameterizable |
| Decision needs an outside system or data not in the request or parameters | Mutating webhook | MAP is described as free of external HTTP callouts |

This table is our summary of the documented capabilities, not a benchmark. We did not measure latency or reliability differences between policies and webhooks, and we make no claim about them.

## A cautious rollout

The MAP binding has no Warn or Audit action, so you cannot trial a policy in a non-enforcing mode the way you can with a validating binding. Our suggestions, all untested by us:

1. **Start in a throwaway cluster** on the Kubernetes minor version you run, because the feature became stable in v1.36 and your cluster may be older.
2. **Scope the binding narrowly** with `matchResources` and a `namespaceSelector`. The `kubernetes.io/metadata.name` label that the API server sets on namespaces, as covered in our ValidatingAdmissionPolicy guide, gives you a name-based selector without labelling anything.
3. **Make the mutation idempotent** and put the "already done" check in `matchConditions`.
4. **Decide on `failurePolicy` deliberately.** Use `Ignore` while developing so a typo does not block writes, then switch to `Fail` once you have shown the mutation applies.
5. **Re-read the resulting object**, and verify that your validating rules and Pod Security levels still accept it.

## Limits of this article

- We did not run a Kubernetes cluster, so no policy in this article was tested against an API server.
- The JSON Patch results come from a generic Python library, not from Kubernetes.
- We did not find, in the pages we read, statements about what happens when a JSON Patch fails to apply, or about the ordering of several mutating policies; we have not claimed any.
- The Admission Controllers page still describes the MutatingAdmissionPolicy plugin as needing the `mutatingadmissionpolicy` feature gate and the `admissionregistration.k8s.io/v1alpha1` API group, while its default-plugin list for 1.37 includes it and the MAP page says stable and enabled by default. We follow the latter two and flag the inconsistency.
- Documentation changes. Re-check the pages below for your Kubernetes version.

## Sources and verification

Documentation read October 18, 2026 (site version v1.37).

| Important claim | Source | Verification |
|---|---|---|
| MAP is a declarative, in-process CEL alternative to mutating webhooks; stable since v1.36, enabled by default, first available in v1.30 | [Mutating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/mutating-admission-policy/) (last modified Sep 28, 2026) | Verified |
| Policy, binding and optional parameter resource; a policy and a matching binding are required; `.spec.mutations` cannot be empty; names ending `.static.k8s.io` are reserved | [Mutating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/mutating-admission-policy/) | Verified |
| ApplyConfiguration must evaluate to a CEL object and may not modify atomic structs, maps or arrays; `jsonpatch.escapeKey` escapes `~` and `/`; only apiVersion, kind, metadata.name, metadata.generateName and metadata.labels are accessible from the object root | [Mutating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/mutating-admission-policy/) | Verified |
| matchConditions semantics, maximum of 64, `namespaceObject` and `variables` not usable there | [MutatingAdmissionPolicy API reference](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/mutating-admission-policy-v1/) and the MAP page (last modified Aug 26, 2026) | Verified |
| `failurePolicy` Fail or Ignore, default Fail; `reinvocationPolicy` required, Never or IfNeeded with the stated semantics; CREATE, UPDATE, CONNECT allowed, DELETE not | [MutatingAdmissionPolicy API reference](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/mutating-admission-policy-v1/) | Verified |
| Binding fields (`policyName`, `paramRef`, `matchResources`); missing policy means binding ignored; evaluation per parameter; cost budget | [MutatingAdmissionPolicyBinding API reference](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/mutating-admission-policy-binding-v1/) (last modified Aug 26, 2026) | Verified |
| Two-phase admission, mutating then validating; rejection in either phase rejects the request; PodSecurity is validating; any failing MutatingAdmissionPolicy fails the request | [Admission Controllers reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) | Verified |
| MutatingAdmissionPolicy appears in the Kubernetes 1.37 default-enabled plugin list | [Admission Controllers reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) | Qualified: the per-plugin text on the same page still mentions v1alpha1 prerequisites |
| Built-in mutating plugins are re-run if a webhook modifies the object; webhooks must be idempotent; webhook `reinvocationPolicy` defaults to Never | [Dynamic Admission Control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#reinvocation-policy) | Verified |
| Exempt kinds, including virtual authentication and authorization kinds, and the v1.37 webhook default exclusion | [Mutating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/mutating-admission-policy/) | Verified |
| The documentation's JSON Patch sidecar example differs from its apply-configuration example in image string and `args` | [Mutating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/mutating-admission-policy/) | Verified (our comparison of the two published examples) |
| JSON Patch behaviors in the test table | Our run of Python `jsonpatch` 1.35, October 18, 2026 | Qualified: generic RFC 6902 library, not the Kubernetes API server |
| Rollout suggestions and the reading that `IfNeeded` calls for idempotent mutations | Our analysis | Qualified: untested on a cluster |
