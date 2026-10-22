+++
title = "Kubernetes NetworkPolicy Default Deny: A Safe Rollout"
date = 2026-10-22T18:42:00Z
tags = ["kubernetes", "network security", "zero trust"]
categories = ["cloud-security"]
summary = "Kubernetes allows all pod traffic until a NetworkPolicy selects a pod. A default-deny policy flips that, but it also blocks DNS, needs allow rules on both ends of every connection and does nothing without a network plugin that enforces it. Here is how the rules combine and an order to roll it out without an outage."
description = "Kubernetes NetworkPolicy default deny explained: how isolation works, why DNS breaks, the both-ends rule, selector traps and a safe rollout order."
author = "John Marshall"
imageAlt = "Close-up of black Ethernet cables plugged into lit ports on the side of a grey network switch"
imageCredit = "Photo by [Manuel Luikenga](https://unsplash.com/photos/y4GHs9GEFdM) on Unsplash"
takeaways = [
  "By default every pod accepts and sends any traffic. A pod becomes isolated in a direction only when a NetworkPolicy selects it with that direction in policyTypes; after that, only traffic some policy allows gets through.",
  "Policies only add allowances; there is no deny rule. A connection between two pods needs the source's egress and the destination's ingress to allow it, so a namespace-wide default deny means writing allow rules for both ends.",
  "A default-deny egress policy also blocks DNS. Add an explicit allow to your cluster's DNS pods, on UDP and TCP port 53, in the same change.",
  "NetworkPolicy has no effect unless your network plugin enforces it, and it covers TCP, UDP and SCTP only. It cannot apply a default to all namespaces, log blocked connections or block traffic from a pod's own node.",
  "Roll out per namespace: inventory flows, apply allow rules first, then the default deny, then test, starting with egress-light namespaces. Also restrict who can relabel namespaces, because labels decide what the selectors match."
]

[[faq]]
q = "What does an empty podSelector mean in a NetworkPolicy?"
a = "An empty podSelector ({}) selects every pod in the policy's namespace. That is how the default-deny examples in the Kubernetes documentation apply to the whole namespace, including pods created later."
[[faq]]
q = "Why did my pods lose DNS after I applied default deny?"
a = "A policy with Egress in policyTypes and no egress rules blocks all outbound connections, including DNS queries to the cluster DNS service. The Kubernetes documentation says you must add a separate policy that allows egress to your DNS service."
[[faq]]
q = "Can I reference a namespace by name in a NetworkPolicy?"
a = "Not with a dedicated field, but the control plane sets an immutable label, kubernetes.io/metadata.name, on every namespace with the namespace's name as its value. You can match that label in a namespaceSelector."
[[faq]]
q = "Does NetworkPolicy encrypt traffic or work at layer 7?"
a = "No. The Kubernetes documentation says anything TLS-related, forcing traffic through a gateway and targeting Services by name are outside the NetworkPolicy API; it suggests a service mesh, ingress controller or other tools for those."
+++

In a Kubernetes cluster with no NetworkPolicies, every pod can talk to every other pod and to the internet. A default-deny policy changes that for one namespace: nothing gets in or out unless a policy allows it. It is one of the most effective controls against lateral movement after a pod is compromised, and one of the easiest to get wrong, because it silently depends on your network plugin, breaks DNS, and needs allow rules on both ends of every connection.

**Scope.** This guide is based on the Kubernetes documentation for v1.37 (the "Network Policies" concept page and its example manifests in the kubernetes/website repository, read on October 22, 2026). The manifests below passed schema validation with kubeconform 0.6.7 in strict mode against the Kubernetes 1.34 schema. We did not apply them to a running cluster, and behavior can vary by network plugin, as the documentation itself notes.

## How isolation works

The documentation describes two independent kinds of isolation for a pod, ingress and egress:

- **By default a pod is non-isolated** in both directions: all inbound and outbound connections are allowed.
- **A pod becomes isolated for a direction** when any NetworkPolicy both selects it and lists that direction (`Ingress` or `Egress`) in `policyTypes`.
- **Once isolated, only allowed traffic passes.** The allowed set is the union of what every applicable policy allows. Reply traffic for allowed connections is permitted automatically.
- **Policies are additive and don't conflict.** There is no deny rule and no ordering. The documentation lists explicit deny as something the API cannot do.
- **Both ends must agree.** For a connection from pod A to pod B, A's egress and B's ingress must both allow it.
- **Traffic from the pod's own node is always allowed** for ingress, and a pod cannot block access to itself.

Two practical consequences follow. First, the first policy that selects a pod for a direction is what isolates it, even if that policy was meant only to allow something. Second, "default deny" is not a special setting; it is a policy that selects all pods and allows nothing.

One more prerequisite: the documentation states that creating a NetworkPolicy without a network plugin that implements it "will have no effect". Check that your CNI plugin enforces NetworkPolicy before you rely on any of this.

## The default-deny manifests

The Kubernetes documentation provides three variants. This one denies both directions:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: shop
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

`podSelector: {}` selects every pod in the namespace, including pods created later. The ingress-only and egress-only versions list only one entry in `policyTypes`.

A detail that trips people up: if you omit `policyTypes`, the documentation says `Ingress` is always set and `Egress` is set only if the policy has egress rules. A policy with no egress rules and no `policyTypes` therefore does not isolate egress. Write `policyTypes` explicitly.

## Allow DNS in the same change

The documentation has a caution next to the egress example: a default-deny egress policy also blocks DNS. Add the allow before or with the deny:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: shop
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

The `k8s-app: kube-dns` label is the one the upstream documentation uses for CoreDNS, kept for backward compatibility with the older kube-dns. Managed clusters and node-local DNS caches can differ, so check with `kubectl get pods -n kube-system --show-labels` before applying. Allow TCP as well as UDP: DNS falls back to TCP for large responses.

## Writing the allow rules

### The selector indentation trap

The documentation highlights one YAML detail that changes meaning completely:

```yaml
# ONE peer: pods labelled role=client IN namespaces labelled user=alice
- from:
  - namespaceSelector:
      matchLabels:
        user: alice
    podSelector:
      matchLabels:
        role: client
```

```yaml
# TWO peers: role=client pods in THIS namespace, OR any pod in user=alice namespaces
- from:
  - namespaceSelector:
      matchLabels:
        user: alice
  - podSelector:
      matchLabels:
        role: client
```

The second form is far broader than it looks. The documentation suggests `kubectl describe networkpolicy` to see how Kubernetes interpreted a policy.

### Both ends of an internal connection

With a namespace-wide default deny, a `web` to `api` call on port 9000 needs two policies:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-api-egress
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: api
    ports:
    - protocol: TCP
      port: 9000
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-from-web
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 9000
```

Traffic from your ingress controller is another namespace-to-pod rule. Use the immutable `kubernetes.io/metadata.name` label, which the control plane sets on every namespace, rather than a label someone can edit. The example below assumes the controller runs in a namespace called `ingress-nginx`; adjust it to yours.

```yaml
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
```

### Use ipBlock only for addresses outside the cluster

The documentation says `ipBlock` should be used for cluster-external addresses, because pod IPs are ephemeral. It also warns that source and destination rewriting by load balancers or Service implementations may happen before or after policy evaluation, so the source IP a policy sees for ingress could be a load balancer's or node's address. Test any `ipBlock` rule with your actual plugin.

## What NetworkPolicy does not do

From the documentation's own list, as of v1.37 the API cannot:

- Apply a default policy to all namespaces. You need a policy per namespace, or a third-party tool.
- Log blocked or allowed connections.
- Express explicit deny rules.
- Block traffic from the pod's node, or loopback.
- Do anything TLS-related, force traffic through a gateway, or target Services by name.

It is defined for TCP, UDP and SCTP. For other protocols such as ICMP, the documentation says behavior is undefined and varies by plugin. Policy behavior for `hostNetwork` pods is also undefined; most plugins treat their traffic as node traffic.

## A rollout order that avoids outages

These steps are our recommendations, not part of the Kubernetes documentation.

1. **Confirm enforcement.** Check that your CNI plugin enforces NetworkPolicy, and whether it supports `endPort` and SCTP if you need them.
2. **Find namespaces with no policy at all.** For example (illustrative, not run against a cluster):

   ```bash
   comm -23 \
     <(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort) \
     <(kubectl get netpol -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}' | sort -u)
   ```

3. **Inventory real flows** for one namespace: Services it exposes, what calls it, and every outbound dependency (databases, other namespaces, external APIs, metadata endpoints, DNS). Your plugin's flow logs, if it has them, are the best source.
4. **Apply the allow policies first, in complete sets.** Remember that any policy selecting a pod isolates it in that direction. The DNS policy above selects every pod for egress, so on its own it already blocks all egress except DNS. Apply it together with every other egress allow rule for the namespace, and each pod's ingress allows together. Start with low-risk namespaces.
5. **Apply the default deny,** ingress first, then egress. Egress is where unknown dependencies hide.
6. **Test from inside the pods** and watch error rates. The documentation notes that newly created pods may briefly start before policies are applied, and that a pod may start with no connectivity until allow rules arrive; make startup tolerant of that, for example with an init container that waits for dependencies.
7. **Lock down namespace labels.** Selectors depend on labels, and the Kubernetes RBAC good-practices page warns that users who can patch a Namespace can change labels to gain access an administrator did not intend. Our [RBAC audit guide](/posts/kubernetes-rbac-audit-11-permissions-that-escalate-access/) covers who holds that permission.

Changing policies under live traffic has one more caveat: the documentation says whether a change affects existing connections is implementation-defined.

NetworkPolicy pairs naturally with the admission controls we have covered. [Pod Security Admission](/posts/kubernetes-pod-security-admission-namespace-labels-modes-and-a-safe-rollout-from-warn-to-enforce/) is also driven by namespace labels, and a [ValidatingAdmissionPolicy](/posts/kubernetes-validatingadmissionpolicy-cel-rules-for-registry-allowlists-and-memory-limits-with-a-warn-first-rollout/) can require that every new namespace gets a default-deny policy through your deployment tooling.

## Limits of this article

We validated the manifests against the Kubernetes schema but did not apply them to a cluster or test them with a specific network plugin. The DNS label and the ingress-controller namespace are common defaults, not universal. Plugin-specific features such as cluster-wide policies, logging and layer 7 rules are outside this article.

## Sources and verification

Checked on October 22, 2026.

| Important claim | Source | Verification |
|---|---|---|
| Default non-isolation; isolation by policyTypes; additive union; both ends must allow; node traffic always allowed; no effect without an enforcing plugin | [Kubernetes: Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) (v1.37 docs, source in kubernetes/website) | Verified |
| Default-deny example manifests; DNS caution; policyTypes default when omitted; selector indentation example | Same page and its example files | Verified |
| `kubernetes.io/metadata.name` immutable label | Same page | Verified |
| ipBlock for external IPs; rewriting before or after policy is undefined; TCP/UDP/SCTP only; hostNetwork undefined; list of unsupported features; existing connections implementation-defined; pod startup timing | Same page | Verified |
| CoreDNS keeps the `k8s-app: kube-dns` label | [Kubernetes: Debugging DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/) | Verified |
| Namespace patch permission can change labels and widen NetworkPolicy access | [Kubernetes: RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/) | Verified |
| Manifests are schema-valid | kubeconform 0.6.7, `-strict`, Kubernetes 1.34 schema, run on October 22, 2026 | Verified; not applied to a cluster |
| Rollout order | Our recommendations | Qualified: not tested on a cluster |
