+++
title = "Kubernetes RBAC Audit: 11 Permissions That Escalate Access"
date = 2026-10-22T18:43:00Z
tags = ["kubernetes", "rbac", "least privilege", "service accounts"]
categories = ["identity-access"]
summary = "Some Kubernetes RBAC permissions look harmless but let the holder become someone more powerful: list on Secrets, create on Pods, get on nodes/proxy, and the escalate, bind and impersonate verbs among them. This guide lists the 11 the Kubernetes project flags and gives a tested script that finds them in your bindings."
description = "Kubernetes RBAC audit: the 11 permissions the Kubernetes docs flag as privilege-escalation risks, why each is dangerous, and a tested script to find them."
author = "Craig Leslie"
imageAlt = "A heap of old rusty iron and steel keys of many shapes and sizes in bright sunlight"
imageCredit = "Photo by [Ari Sha](https://unsplash.com/photos/sf89k55BMHU) on Unsplash"
takeaways = [
  "The Kubernetes RBAC Good Practices page lists permissions that let a user or service account escalate privileges: reading Secrets, creating workloads, creating PersistentVolumes, nodes/proxy, the escalate, bind and impersonate verbs, CSR approval, token requests, admission webhook control and namespace modification.",
  "Several are not what they look like. list and watch on Secrets reveal Secret contents; get on nodes/proxy reaches the kubelet API and can execute commands in pods while bypassing audit logging and admission control.",
  "Permission to create Pods in a namespace implicitly grants access to the Secrets, ConfigMaps and volumes that can be mounted there, and to the API rights of any service account in that namespace. The documentation calls boundaries inside a namespace weak.",
  "Wildcards grant rights to resource types that don't exist yet, and members of system:masters bypass RBAC entirely. Neither can be fixed by editing a RoleBinding.",
  "Our script reads kubectl's JSON output and prints each subject bound to a risky permission, separating cluster-wide from namespace grants. We tested it on a sample file, not a live cluster."
]

[[faq]]
q = "Is get on secrets the only dangerous Secret permission?"
a = "No. The Kubernetes RBAC Good Practices page says list and watch also effectively reveal Secret contents, because a list response includes the contents of every Secret returned."
[[faq]]
q = "What do the escalate and bind verbs do?"
a = "Normally RBAC stops you creating or updating a role with permissions you don't have, or binding a role whose permissions you don't have. The escalate verb on roles or clusterroles lifts the first restriction, and the bind verb on a role lifts the second. Both are documented as privilege-escalation risks."
[[faq]]
q = "Can a RoleBinding grant access to nodes or PersistentVolumes?"
a = "No. Nodes and PersistentVolumes are cluster-scoped, and the RBAC documentation says permissions on cluster-scoped resources must be in a ClusterRole bound with a ClusterRoleBinding to be effective. A RoleBinding to such a ClusterRole only grants its namespaced permissions."
[[faq]]
q = "How do I check what a specific service account can do?"
a = "Use kubectl auth can-i with impersonation, for example: kubectl auth can-i list pods --namespace target --as system:serviceaccount:dev:dev-sa. The Kubernetes authorization documentation shows this pattern. It requires that you have impersonation rights."
+++

Kubernetes RBAC is usually audited by looking for `cluster-admin` bindings. That misses the permissions that don't look like admin but lead there: a service account that can list Secrets, a CI identity that can create Pods, a monitoring agent with `get` on `nodes/proxy`. The Kubernetes project documents these escalation paths on its RBAC Good Practices page. This guide turns that list into an audit you can run.

**Scope.** Based on the Kubernetes v1.37 documentation pages "Role Based Access Control Good Practices", "Using RBAC Authorization" and "Authorization", read from the kubernetes/website repository on October 22, 2026. The audit script was tested with Python 3.13 on a sample JSON file we wrote; we did not run it against a live cluster.

## The 11 escalation risks

The RBAC Good Practices page lists these under "privilege escalation risks". The "why" column paraphrases the documentation.

| # | Permission | Why it escalates |
|---|---|---|
| 1 | `get`, `list` or `watch` on `secrets` | All three reveal Secret contents; a list response includes every Secret's data |
| 2 | Creating Pods or workload resources (Deployments, Jobs and so on) | Pods can mount the namespace's Secrets, ConfigMaps and volumes and run as any service account in the namespace; privileged Pods can reach the node |
| 3 | `create` on `persistentvolumes` | Allows `hostPath` volumes, which expose the node's file system |
| 4 | Any access to `nodes/proxy` | Reaches the kubelet API, which can execute commands in every pod on the node, bypassing audit logging and admission control. `get` alone is enough |
| 5 | `escalate` on `roles` or `clusterroles` | Lets the holder write roles with permissions it does not have |
| 6 | `bind` on roles | Lets the holder bind roles with permissions it does not have |
| 7 | `impersonate` | Lets the holder act as other users, groups or service accounts |
| 8 | `create` on `certificatesigningrequests` plus `update` on `certificatesigningrequests/approval` | With the `kubernetes.io/kube-apiserver-client` signer, can mint client certificates with arbitrary names, including system component names |
| 9 | `create` on `serviceaccounts/token` | Issues tokens for existing service accounts |
| 10 | Control of `validatingwebhookconfigurations` or `mutatingwebhookconfigurations` | Webhooks can read every admitted object; mutating webhooks can change them |
| 11 | `patch` on `namespaces` | Can relabel a namespace, which can loosen Pod Security Admission or widen NetworkPolicy access |

Two points deserve emphasis.

**Read is not always read-only.** The documentation states plainly that `get` on `nodes/proxy` "is not a read-only permission", because the kubelet APIs can be reached with websocket `GET` requests. Monitoring tools sometimes request it. If one of yours does, find out exactly why. There is often a narrower option. The kubelet maps `/metrics`, `/stats` and `/logs` to their own subresources (`nodes/metrics`, `nodes/stats`, `nodes/log`), so a collector that only reads those needs no `nodes/proxy`. On recent versions, kubelet fine-grained authorization (the `KubeletFineGrainedAuthz` feature, beta and on by default from v1.33, stable in v1.36) adds the same for `/pods`, `/runningPods`, `/healthz` and `/configz`, checking `nodes/pods`, `nodes/healthz` or `nodes/configz` before falling back to `nodes/proxy`.

**Pod creation is a namespace-wide grant.** Anyone who can create a Pod can choose which service account it runs as and which Secrets it mounts. The documentation concludes that "boundaries within a namespace should be considered weak" and recommends enforcing the Baseline or Restricted Pod Security Standard where you don't fully trust the creator. See [our Pod Security Admission rollout guide](/posts/kubernetes-pod-security-admission-namespace-labels-modes-and-a-safe-rollout-from-warn-to-enforce/).

## Two problems a RoleBinding review won't catch

- **`system:masters`.** Members of this group bypass all RBAC checks, and that cannot be revoked by removing RoleBindings or ClusterRoleBindings. If an authorization webhook is in use, they bypass that too. Membership comes from the credential itself (for example a client certificate's organization field), so look at how credentials are issued, not at bindings.
- **Wildcards.** `*` in resources or verbs grants rights not only to every resource type that exists now but to every type created in the future, for example by a new CRD (CustomResourceDefinition).

The documentation also warns about deleted users: if an attacker can create an account with the same name as a deleted user, they inherit any bindings that still name it. Remove bindings when you remove people.

## How the built-in guardrails work

RBAC does have an anti-escalation check. Per the RBAC reference, you can only create or update a role if you already hold all of its permissions at the same scope, or have `escalate` on roles. You can only create or update a role binding if you already hold all of the referenced role's permissions, or have `bind` on that role. That is why `escalate` and `bind` are on the list: they are the switches that turn the guardrail off.

The documentation shows a legitimate, narrow use of `bind`: letting a team lead grant only the built-in `admin`, `edit` and `view` ClusterRoles, by listing them in `resourceNames`. Without `resourceNames`, `bind` covers every role.

## A script to find risky grants

The script below reads the JSON that kubectl produces for roles and bindings, and prints one line per subject per risky finding. It reports wildcards once instead of listing every risk they imply, and it skips cluster-scoped resources (such as `nodes/proxy` or `persistentvolumes`) when the grant comes through a RoleBinding, because the RBAC reference says those permissions only take effect through a ClusterRoleBinding.

Export the data first:

```bash
kubectl get clusterroles,clusterrolebindings,roles,rolebindings -A -o json > rbac.json
python3 rbac_audit.py rbac.json
```

```python
import json, sys

# (resource, verbs, why) - from the Kubernetes "RBAC Good Practices" page
RISKY = [
    ("secrets", {"get", "list", "watch"}, "reads Secret contents"),
    ("pods", {"create"}, "workload creation: mounts Secrets, runs as any ServiceAccount in the namespace"),
    ("deployments", {"create", "update", "patch"}, "workload creation"),
    ("daemonsets", {"create", "update", "patch"}, "workload creation"),
    ("statefulsets", {"create", "update", "patch"}, "workload creation"),
    ("jobs", {"create"}, "workload creation"),
    ("cronjobs", {"create"}, "workload creation"),
    ("persistentvolumes", {"create"}, "hostPath volumes give node filesystem access"),
    ("nodes/proxy", {"get", "create"}, "kubelet API: exec into pods, bypasses audit and admission"),
    ("roles", {"escalate"}, "can write roles with rights it does not hold"),
    ("clusterroles", {"escalate"}, "can write roles with rights it does not hold"),
    ("roles", {"bind"}, "can bind roles with rights it does not hold"),
    ("clusterroles", {"bind"}, "can bind roles with rights it does not hold"),
    ("users", {"impersonate"}, "acts as other users"),
    ("groups", {"impersonate"}, "acts as other groups"),
    ("serviceaccounts", {"impersonate"}, "acts as service accounts"),
    ("certificatesigningrequests/approval", {"update"}, "with CSR create, can mint client certificates"),
    ("serviceaccounts/token", {"create"}, "issues tokens for existing service accounts"),
    ("validatingwebhookconfigurations", {"create", "update", "patch"}, "sees every admitted object"),
    ("mutatingwebhookconfigurations", {"create", "update", "patch"}, "sees and changes every admitted object"),
    ("namespaces", {"patch", "update"}, "can relabel namespaces (Pod Security, NetworkPolicy selectors)"),
]

# A RoleBinding cannot grant access to cluster-scoped resources.
CLUSTER_SCOPED = {"persistentvolumes", "nodes/proxy", "clusterroles",
                  "certificatesigningrequests/approval", "users", "groups",
                  "validatingwebhookconfigurations",
                  "mutatingwebhookconfigurations", "namespaces"}

def findings(rule, namespaced_binding):
    res, verbs = set(rule.get("resources", [])), set(rule.get("verbs", []))
    out = []
    if "*" in res or "*" in verbs:
        return [f"wildcard resources={sorted(res)} verbs={sorted(verbs)}: "
                "covers current and future resource types"]
    for r, risky_verbs, why in RISKY:
        if namespaced_binding and r in CLUSTER_SCOPED:
            continue
        if r in res and verbs & risky_verbs:
            out.append(f"{r} {sorted(verbs & risky_verbs)}: {why}")
    return out

def main(path):
    items = json.load(open(path))["items"]
    roles = {}
    for o in items:
        if o["kind"] in ("Role", "ClusterRole"):
            ns = o["metadata"].get("namespace", "")
            roles[(o["kind"], ns, o["metadata"]["name"])] = o.get("rules") or []
    for b in items:
        if b["kind"] not in ("RoleBinding", "ClusterRoleBinding"):
            continue
        ref = b["roleRef"]
        bns = b["metadata"].get("namespace", "")
        key = (ref["kind"], bns if ref["kind"] == "Role" else "", ref["name"])
        nsb = b["kind"] == "RoleBinding"
        hits = sorted({f for rule in roles.get(key, []) for f in findings(rule, nsb)})
        if not hits:
            continue
        scope = "cluster-wide" if b["kind"] == "ClusterRoleBinding" else f"namespace {bns}"
        for s in b.get("subjects") or []:
            who = f'{s["kind"]} {s.get("namespace", "") + "/" if s.get("namespace") else ""}{s["name"]}'
            for h in hits:
                print(f"{who} | {ref['kind']} {ref['name']} | {scope} | {h}")

if __name__ == "__main__":
    main(sys.argv[1])
```

We ran it on a sample file with five bindings: a CI service account with a ClusterRole that can patch Deployments and list Secrets cluster-wide; a namespaced "release" Role with Pod creation and `bind`; a read-only debug Role; a monitoring agent bound through a RoleBinding to a ClusterRole with `get` on `nodes/proxy`; and a user with a full wildcard ClusterRole. Output:

```
ServiceAccount build/ci | ClusterRole ci-deployer | cluster-wide | deployments ['patch']: workload creation
ServiceAccount build/ci | ClusterRole ci-deployer | cluster-wide | secrets ['list']: reads Secret contents
ServiceAccount payments/release-bot | Role release | namespace payments | pods ['create']: workload creation: mounts Secrets, runs as any ServiceAccount in the namespace
ServiceAccount payments/release-bot | Role release | namespace payments | roles ['bind']: can bind roles with rights it does not hold
User alice@example.com | ClusterRole platform-admin | cluster-wide | wildcard resources=['*'] verbs=['*']: covers current and future resource types
```

The read-only debug Role produced nothing, as intended, and the `nodes/proxy` grant was correctly skipped because a RoleBinding cannot grant a cluster-scoped resource. Had it been a ClusterRoleBinding, it would have been reported.

**Known limits of the script.** It ignores `apiGroups` (a CRD that reuses a name like `jobs` would be flagged), does not evaluate `resourceNames` restrictions, flags `update` and `patch` on workloads as well as `create`, does not cover every workload type (for example ReplicaSets), and does not see `system:masters` membership or permissions granted by authorizers other than RBAC. Treat its output as a review list, not a verdict.

## Confirming a finding

For any subject the script flags, check what it can actually do. The Kubernetes authorization documentation shows `kubectl auth can-i` combined with impersonation:

```bash
kubectl auth can-i list secrets --namespace payments \
  --as system:serviceaccount:build:ci
```

You need impersonation rights to run that, which is itself item 7 on the list. Keep those rights with a small group of administrators.

## Fixing what you find

From the Good Practices page, plus our notes:

- **Prefer RoleBindings to ClusterRoleBindings,** so rights stay inside one namespace.
- **Replace wildcards** with explicit resources and verbs.
- **Give powerful service accounts to as few Pods as possible,** and keep those Pods off nodes that run untrusted or internet-facing workloads, using taints and tolerations or affinity rules.
- **Turn off token automounting** where a workload doesn't call the API, with `automountServiceAccountToken: false` on the ServiceAccount or Pod; the Pod setting takes precedence.
- **Review bindings for `system:unauthenticated`,** which give access to anyone who can reach the API server.
- **Use `resourceNames`** to limit `bind` and `impersonate` to specific roles or identities.
- **Review periodically,** and remove bindings for departed users and retired service accounts.

The same least-privilege thinking applies to cloud IAM; [our guide to finding overprivileged AWS IAM users and roles](/posts/how-to-find-overprivileged-aws-iam-users-and-roles/) covers that side. Namespace labels also drive network isolation, which is why item 11 matters for [NetworkPolicy default deny](/posts/kubernetes-networkpolicy-default-deny-safe-rollout/).

## Limits of this article

The list of risks is the Kubernetes project's; it is not exhaustive for every add-on or CRD in your cluster, many of which define their own sensitive resources. The script was tested on sample data only. Managed Kubernetes services add their own identity layers (for example cloud IAM mappings) that are outside this article.

## Sources and verification

Checked on October 22, 2026.

| Important claim | Source | Verification |
|---|---|---|
| The 11 privilege-escalation risks and their explanations; nodes/proxy get is not read-only; namespace boundaries are weak; system:masters bypasses RBAC; wildcard and deleted-user warnings; hardening advice | [Kubernetes: RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/) | Verified |
| Role creation and binding restrictions; escalate and bind; resourceNames example; cluster-scoped resources need a ClusterRoleBinding | [Kubernetes: Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) | Verified |
| Kubelet path-to-subresource mapping; fine-grained authorization endpoints; feature stages (beta default-on from v1.33, stable v1.36) | [Kubernetes: Kubelet authentication/authorization](https://kubernetes.io/docs/reference/access-authn-authz/kubelet-authn-authz/) and the KubeletFineGrainedAuthz feature-gate page | Verified |
| Client certificates can carry group memberships in their organization fields | [Kubernetes: Authenticating](https://kubernetes.io/docs/reference/access-authn-authz/authentication/) | Verified |
| `kubectl auth can-i` with `--as` for service accounts | [Kubernetes: Authorization](https://kubernetes.io/docs/reference/access-authn-authz/authorization/) | Verified |
| `automountServiceAccountToken: false`; Pod setting takes precedence | [Kubernetes: Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) | Verified |
| Script output | Run by us on October 22, 2026 with Python 3.13 on a five-binding sample file | Verified on sample data; not run on a live cluster |
