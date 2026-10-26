+++
title = "Kubernetes Audit Log Detections: 8 Rules We Tested"
date = 2026-10-26T04:45:00Z
tags = ["kubernetes", "audit logging", "detection engineering", "threat hunting"]
categories = ["cloud-security"]
summary = "Eight detection rules for the Kubernetes audit log, written as jq filters and mapped to MITRE ATT&CK: exec and debug sessions, pods asking for host access, cluster-admin bindings, Secret sweeps, minted tokens, impersonation, permission discovery and anonymous calls. We ran them against a scripted attack on kube-apiserver v1.34.1 and report what each caught, what it missed and how to tune it."
description = "Kubernetes audit log detections for exec, host-access pods, cluster-admin bindings, Secret sweeps, tokens and impersonation, tested on kube-apiserver v1.34.1."
author = "Craig Leslie"
imageAlt = "A single white surveillance camera on a short bracket, mounted on a plain pale grey textured wall crossed by a diagonal band of light"
imageCredit = "Photo by [Siarhei Horbach](https://unsplash.com/photos/xJc--frJbuw) on Unsplash"
takeaways = [
  "Most Kubernetes attack techniques have to go through kube-apiserver, so a handful of audit log rules covers a lot: exec and ephemeral containers, pods that request host access, bindings to cluster-admin, Secret reads across namespaces or in kube-system, service account tokens minted by people, impersonation, permission discovery and anonymous requests.",
  "Long-running requests such as exec are logged twice, at ResponseStarted and ResponseComplete, and one kubectl exec produced both a get and a create. Filter on ResponseComplete or every exec counts double.",
  "Rejected requests are evidence too. A privileged Pod with a hostPath mount of / that the API server refused (HTTP 422) was still logged with its full spec. A detection that only looks at successful creates misses the attempt.",
  "Several rules need request bodies: host-access pods, cluster-admin bindings and ephemeral container images are only visible at Request or RequestResponse level. Secrets and tokens should stay at Metadata, which is still enough to detect who touched them.",
  "Exclude control-plane identities by name, not with a blanket 'system:' filter. Service accounts are system: identities too, and a stolen service account token is one of the most common ways in."
]

[[faq]]
q = "What should I alert on in Kubernetes audit logs?"
a = "Start with actions that change who can do what or that reach into workloads and nodes: exec, attach and ephemeral containers; Pods requesting privileged mode, host namespaces or hostPath volumes; bindings to cluster-admin; Secret reads across all namespaces or in kube-system; service account tokens created by anything other than the kubelet; impersonation; and bursts of denied requests from one identity."
[[faq]]
q = "How do I detect kubectl exec in Kubernetes audit logs?"
a = "Match events whose objectRef.resource is pods and objectRef.subresource is exec, and keep only the ResponseComplete stage. In our kube-apiserver v1.34.1 test, one kubectl exec produced a get and a create event, each logged at two stages, and the command was in requestURI as command= query parameters."
[[faq]]
q = "Does the audit log record requests the API server rejected?"
a = "Yes. Authorization denials are logged with the authorization.k8s.io/decision annotation set to forbid and response code 403, and requests that fail validation or admission are logged with their error code. In our test a privileged Pod rejected with HTTP 422 was logged at Request level with its full spec."
[[faq]]
q = "How do I map Kubernetes audit events to MITRE ATT&CK?"
a = "The containers techniques line up with API actions: exec maps to Container Administration Command (T1609), new Pods to Deploy Container (T1610) and, with host access, Escape to Host (T1611), new cluster role bindings to Additional Container Cluster Roles (T1098.006), Secret reads to Container API (T1552.007), and permission or resource enumeration to Container and Resource Discovery (T1613)."
+++

Kubernetes audit log detections work because most attack techniques against a cluster have to go through kube-apiserver. Getting a shell in a Pod, starting a container that mounts the node's filesystem, granting yourself cluster-admin, sweeping Secrets, minting a token: each is an API request, and each leaves an audit event with the identity, the verb, the resource and the result. The eight rules below turn those events into alerts.

We wrote them as `jq` filters so you can run them against a log file today, then ran them against kube-apiserver v1.34.1 while we played out a small attack: a stolen CI credential probing what it can do, a compromised administrator setting up persistence, and an anonymous caller. This article shows what each rule caught, what it would miss, and how to tune it before you port it to a SIEM.

The rules assume an audit policy that logs everything at `Metadata` or above and keeps request bodies for writes. If you do not have one yet, start with our [Kubernetes audit policy guide](/posts/kubernetes-audit-policy-what-to-log-and-at-what-level/); we used the same six-rule policy here.

## The eight rules

| Rule | What it looks for | MITRE ATT&CK | Level needed |
|---|---|---|---|
| D1 | `exec`, `attach` and `ephemeralcontainers` on Pods | T1609 Container Administration Command | Metadata (Request to see debug images) |
| D2 | Pod creates asking for `privileged`, `hostPID`, `hostNetwork`, `hostIPC` or a `hostPath` volume, allowed or rejected | T1610 Deploy Container, T1611 Escape to Host | Request |
| D3 | Bindings whose `roleRef` is `cluster-admin` | T1098.006 Additional Container Cluster Roles | Request |
| D4 | Secret `get`, `list` or `watch` across all namespaces or in `kube-system` | T1552.007 Container API | Metadata |
| D5 | `serviceaccounts/token` creates by anything other than a kubelet | T1528 Steal Application Access Token | Metadata |
| D6 | Any request carrying `impersonatedUser` | Context for every other rule | Metadata |
| D7 | `selfsubjectrulesreviews` (`kubectl auth can-i --list`) and bursts of `forbid` decisions | T1613 Container and Resource Discovery | Metadata |
| D8 | Requests from `system:anonymous` | Context: exposure check | Metadata |

The ATT&CK IDs and names are from MITRE's STIX data (enterprise collection version 20.0). The mapping is ours: ATT&CK describes techniques, not audit fields.

## The test

We ran kube-apiserver v1.34.1 and etcd 3.6.4 (the controller-runtime envtest binaries) with RBAC authorization, static bearer tokens for three users and the audit policy linked above, writing JSON lines to a file. There were no nodes, kubelets, controller manager or scheduler, so Pods were never scheduled. That keeps the log readable, but a real cluster's log is far noisier; see the limits section.

The scenario, in order:

1. **Benign:** `dev-bob`, in the `developers` group, creates a Pod in `dev`, reads a Secret in his own namespace and runs `kubectl exec`.
2. **Stolen CI token:** `ci-deployer`, which can create Pods and exec in `prod`, runs `kubectl auth can-i --list`, tries to list Secrets, nodes, namespaces, ClusterRoles, ConfigMaps and ServiceAccounts cluster-wide, tries Secrets in `kube-system`, then tries to create a privileged Pod with `hostPID`, `hostNetwork` and a `hostPath` mount of `/`. The API server rejected that one (it was running with the default `--allow-privileged=false`), so the attacker dropped the privileged flags and created a Pod that only mounts `/` from the host. That one succeeded.
3. **Compromised admin:** `alice` binds `cluster-admin` to the `prod/default` service account, mints a 24-hour token for it with `kubectl create token`, reads `kube-system` Secrets while impersonating it, and attaches a debug container to a running Pod with `kubectl debug`.
4. **Anonymous:** an unauthenticated `curl` to `/api/v1/namespaces/kube-system/secrets`.

The resulting log had 574 events. 532 came from `system:apiserver` itself; the other 42 were ours (alice 18, ci-deployer 15, dev-bob 8, anonymous 1).

## The rules as a script

Save this as `detections.sh` and run `sh detections.sh audit.log`. It needs jq 1.6 or later for `IN`; we ran it with jq 1.7.

```bash
#!/bin/sh
# Kubernetes audit log detections. Usage: ./detections.sh audit.log
# Input: kube-apiserver JSON-lines audit log (audit.k8s.io/v1 Event objects).
LOG="$1"

# Control-plane identities to ignore. Extend this for your distribution.
NOT_CP='(.user.username | IN("system:apiserver","system:kube-controller-manager","system:kube-scheduler") | not)'
# Count each request once: long-running calls such as exec also emit ResponseStarted.
DONE='.stage=="ResponseComplete"'

echo "D1 exec, attach and ephemeral containers"
jq -c "select($DONE)"' | select(.objectRef.resource=="pods"
      and (.objectRef.subresource | IN("exec","attach","ephemeralcontainers")))
  | {user:.user.username, sub:.objectRef.subresource, verb, ns:.objectRef.namespace,
     pod:.objectRef.name, code:.responseStatus.code, uri:.requestURI}' "$LOG"

echo "D2 pods requesting host access (allowed or rejected)"
jq -c 'select(.objectRef.resource=="pods" and .verb=="create" and .objectRef.subresource==null)
  | select(.requestObject.spec.hostPID or .requestObject.spec.hostNetwork or .requestObject.spec.hostIPC
      or any(.requestObject.spec.volumes[]?; .hostPath)
      or any(.requestObject.spec.containers[]?; .securityContext.privileged))
  | {user:.user.username, ns:.objectRef.namespace, pod:.objectRef.name, code:.responseStatus.code,
     hostPaths:[.requestObject.spec.volumes[]?.hostPath.path | select(.)]}' "$LOG"

echo "D3 bindings that grant cluster-admin"
jq -c "select($NOT_CP)"' | select(.objectRef.apiGroup=="rbac.authorization.k8s.io"
      and (.objectRef.resource | IN("clusterrolebindings","rolebindings"))
      and (.verb | IN("create","update","patch"))
      and .requestObject.roleRef.name=="cluster-admin")
  | {user:.user.username, binding:.objectRef.name, subjects:.requestObject.subjects,
     code:.responseStatus.code}' "$LOG"

echo "D4 Secret reads across all namespaces or in kube-system"
jq -c "select($NOT_CP)"' | select(.objectRef.resource=="secrets" and (.verb | IN("get","list","watch")))
  | select(.objectRef.namespace==null or .objectRef.namespace=="kube-system")
  | {user:.user.username, as:.impersonatedUser.username, verb, ns:.objectRef.namespace,
     code:.responseStatus.code}' "$LOG"

echo "D5 service account tokens minted outside the kubelet"
jq -c "select($NOT_CP)"' | select(.objectRef.resource=="serviceaccounts"
      and .objectRef.subresource=="token" and .verb=="create")
  | select(.user.username | startswith("system:node:") | not)
  | {user:.user.username, sa:(.objectRef.namespace + "/" + .objectRef.name),
     code:.responseStatus.code}' "$LOG"

echo "D6 impersonated requests"
jq -c 'select(.impersonatedUser)
  | {user:.user.username, as:.impersonatedUser.username, verb, res:.objectRef.resource,
     ns:.objectRef.namespace, code:.responseStatus.code}' "$LOG"

echo "D7a permission listing (kubectl auth can-i --list)"
jq -c 'select(.objectRef.resource=="selfsubjectrulesreviews")
  | {user:.user.username, ns:.objectRef.namespace, ip:.sourceIPs[0]}' "$LOG"

echo "D7b identities with 5 or more denied requests in the file"
jq -sc '[.[] | select(.annotations["authorization.k8s.io/decision"]=="forbid")]
  | group_by(.user.username)
  | map({user:.[0].user.username, denied:length,
         resources:([.[].objectRef.resource] | unique)})
  | map(select(.denied >= 5))' "$LOG"

echo "D8 anonymous requests"
jq -c 'select(.user.username=="system:anonymous")
  | {uri:.requestURI, ip:.sourceIPs[0], code:.responseStatus.code}' "$LOG"
```

## What each rule caught

All 15 hits from the run, condensed:

| Rule | Hits | What fired |
|---|---|---|
| D1 | 3 | dev-bob's exec (one `get`, one `create`, both 400 because the Pod had no node); alice's `patch` to `pods/ephemeralcontainers` (200) |
| D2 | 2 | ci-deployer's privileged Pod, rejected with 422; ci-deployer's hostPath Pod, created with 201. Both show `hostPaths: ["/"]` |
| D3 | 1 | alice's `backup-sync` ClusterRoleBinding of `cluster-admin` to `prod/default` |
| D4 | 4 | ci-deployer's cluster-wide list and `kube-system` list (both 403); alice's `kube-system` list as `prod/default` (200); the anonymous call (403) |
| D5 | 1 | alice minting a token for `prod/default` |
| D6 | 1 | alice listing `kube-system` Secrets as `system:serviceaccount:prod:default` (200) |
| D7 | 2 | ci-deployer's `selfsubjectrulesreviews`; ci-deployer with 8 denials across 6 resource types |
| D8 | 1 | the anonymous request (403) |

Every step of both attack paths fired at least one rule. The only benign activity that fired was dev-bob's exec, which is the false positive you would expect: D1 is a "who is in our workloads" feed, not a high-severity alert on its own.

### D1: exec, attach and debug sessions

Two details matter. First, `exec` is a long-running request, and the Kubernetes docs say `ResponseStarted` "is only generated for long-running requests". Our first version of the rule returned every exec event twice, once per stage; filtering on `ResponseComplete` fixed it. Second, one `kubectl exec` produced both a `get` and a `create` on `pods/exec`, so count sessions by `auditID` or by time window, not by event.

`kubectl debug` does not use `exec` at all. It sends a `patch` to the `pods/ephemeralcontainers` subresource, which is why the rule matches that subresource explicitly. Because it is a write, our policy logged it at `Request` level, and the event carried the debug container's image (`busybox:1.36`). A debug container running an image you have never seen in the cluster is worth a look.

To tune: alert on exec into `kube-system` and other platform namespaces, exec by service accounts (people run exec, workloads rarely should), and exec whose `requestURI` contains shells or tools you do not expect. Route the rest to a lower-severity feed.

### D2: Pods asking for the host

The fields come from the Pod Security Standards' Baseline profile, which disallows host namespaces (`spec.hostNetwork`, `spec.hostPID`, `spec.hostIPC`), privileged containers and hostPath volumes. If you enforce those with [Pod Security Admission](/posts/kubernetes-pod-security-admission-namespace-labels-modes-and-a-safe-rollout-from-warn-to-enforce/), D2 tells you who keeps trying.

The useful finding from our run is that the rejected request was logged in full. The privileged Pod failed validation with HTTP 422 ("disallowed by cluster policy"), and the audit event still held the complete `requestObject`, including the `hostPath` of `/`. That is why D2 does not filter on success. An attacker's first attempt is often the one that fails.

D2 needs `Request` level on Pod creates; at `Metadata` the spec is not there. It also only sees Pods. Deployments, DaemonSets, Jobs and CronJobs create Pods through controllers, so the Pod create event's user is the controller's identity. Add the same `select` on `.requestObject.spec.template.spec` for workload resources to see the person who submitted the template.

### D3: bindings to cluster-admin

Without the control-plane exclusion, this rule fired on startup: `system:apiserver` creates the `cluster-admin` ClusterRoleBinding to `system:masters` when it bootstraps RBAC. After excluding it, the only hit was the persistence binding.

The binding name `backup-sync` is deliberately bland; do not rely on names. The rule matches `roleRef.name`, which our policy logs because RBAC writes are kept at `RequestResponse`. Extend it with the other roles that are as good as cluster-admin in your cluster, and with writes to ClusterRoles that add `*` verbs or `escalate`, `bind` or `impersonate`. Our [RBAC permission audit](/posts/kubernetes-rbac-audit-11-permissions-that-escalate-access/) lists them.

### D4: Secret sweeps

A cluster-wide list has no namespace in `objectRef`, which is how D4 finds it. Our policy logs Secrets at `Metadata`, so none of these events contain Secret values, and the rule does not need them: who, which verb, which scope and the response code are enough.

The 403s are as interesting as the 200. Two of the four hits were the stolen CI token being denied, which tells you someone is trying the credential well outside its job. Do not exclude every `system:` user here. `system:serviceaccount:...` identities are `system:` users too: had the attacker used the minted token directly instead of impersonating, the read would have been logged as `system:serviceaccount:prod:default` and a blanket filter would have dropped it. That is why the script excludes control-plane components by exact name. Some distributions run controllers under `kube-system` service accounts; add those by name after you have looked at your own log.

### D5: minted tokens

`kubectl create token` is a `create` on the `serviceaccounts/token` subresource. Our policy logs that subresource at `Metadata`, so the event recorded who asked and for which service account, but not the token. Keep it that way: at `RequestResponse` the response would contain a usable token.

The kubelet requests tokens on behalf of Pods that use projected service account tokens, so in a real cluster most of these events come from `system:node:<name>` identities. The rule drops those. What is left, a person or a workload minting a token for another service account, is rare and worth reviewing. Our [service account token guide](/posts/kubernetes-service-account-tokens-bound-vs-legacy-secrets/) covers why bound tokens are still worth watching.

### D6: impersonation

When a request uses impersonation, the audit event keeps the real caller in `user` and adds `impersonatedUser`. Here alice read `kube-system` Secrets as the service account she had just made cluster-admin. D4 fired on that read too, but only D6 tells you the request ran with the service account's permissions, which is what links the read back to the binding created minutes earlier. Treat D6 as context: join it to every other rule so each alert shows both the real caller and the identity whose permissions were used.

### D7: permission discovery

`kubectl auth can-i --list` sends a `SelfSubjectRulesReview`, which is logged as a create on `selfsubjectrulesreviews`. Developers run it too, so it is weak alone, but it is a strong signal from a CI or workload identity: our stolen CI token ran it first. The burst rule then found 8 denials for ci-deployer across 6 resource types.

The threshold of 5 per file is only for this demo. In a SIEM, count `forbid` decisions per identity over a window such as 10 minutes, and weight by the number of distinct resources: one identity hitting one forbidden resource repeatedly is usually a broken deployment; one identity hitting many is usually someone exploring.

### D8: anonymous requests

kube-apiserver accepts anonymous requests by default (`--anonymous-auth` defaults to true; they arrive as `system:anonymous` in group `system:unauthenticated`). RBAC denied our anonymous call, but the event is still useful: anonymous requests for resource paths from outside your network mean the API server is reachable by people scanning for it. Any anonymous request that gets a 2xx on a resource path is an incident.

## Porting the rules to a SIEM

The fields used here (`user.username`, `impersonatedUser`, `objectRef.*`, `verb`, `stage`, `responseStatus.code`, `annotations`, `requestObject`, `requestURI`, `sourceIPs`) are fields of the `audit.k8s.io/v1` Event object, so the logic carries over to any backend that stores the events. Managed services may wrap each event in their own envelope and may run their own audit policy, which decides whether `requestObject` is present at all. Check one raw event from your provider before you trust a rule that depends on request bodies.

Three practical points:

- **Deduplicate on `auditID`.** It is the same across a request's stages.
- **Alert on attempts.** Keep 403 and 422 results in every rule unless you have a reason to drop them.
- **Join with identity context.** Mapping `user.username` and `sourceIPs` to a person, a pipeline or a node is what turns these rules from noise into findings. Our [incident logging guide](/posts/logging-for-incidents-not-for-dashboards/) covers what to keep alongside the audit log.

## Limits of this article

We tested on a single kube-apiserver with no nodes, controllers or scheduler, so no Pod ever ran and exec returned 400 instead of opening a session. A production log has far more control-plane and controller traffic, and your exclusion list will need tuning against it. We used static tokens; OIDC, certificates and cloud IAM identities change what `user.username` looks like. Managed Kubernetes providers control their own audit policies, and some do not log request bodies, which disables D2, D3 and the image detail in D1. These rules detect API activity only: they do not see what happens inside a container or on a node, which needs runtime or host telemetry.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Audit stages; `ResponseStarted` only for long-running requests | [Kubernetes docs: Auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/) | Verified |
| `impersonatedUser` and other Event fields | [kubernetes/apiserver audit/v1 types.go](https://github.com/kubernetes/apiserver/blob/master/pkg/apis/audit/v1/types.go) | Verified |
| Host namespaces, privileged and hostPath restrictions | [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) | Verified |
| Kubelet requests projected tokens on behalf of Pods | [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) | Verified |
| `--anonymous-auth` and `--allow-privileged` defaults | `kube-apiserver --help`, v1.34.1 | Verified |
| ATT&CK technique IDs and names | [MITRE ATT&CK STIX data](https://github.com/mitre-attack/attack-stix-data), enterprise collection 20.0 | Verified |
| All hits, counts and observed behaviour (exec stages, 422 logged with body, debug as ephemeralcontainers patch, bootstrap binding) | Our run: kube-apiserver v1.34.1, etcd 3.6.4, jq 1.7, October 26, 2026 | Verified (single test environment) |
