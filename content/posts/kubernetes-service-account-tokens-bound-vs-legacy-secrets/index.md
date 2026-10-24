+++
title = "Kubernetes Service Account Tokens: Retire Legacy Secrets"
date = 2026-10-24T04:45:00Z
tags = ["kubernetes", "service accounts", "tokens", "least privilege"]
categories = ["identity-access"]
summary = "Kubernetes Pods get short-lived, Pod-bound service account tokens from the TokenRequest API, but Secret-based tokens still never expire and stay valid until someone deletes the Secret. Here is how the two differ, why a default Pod token can stay valid for up to a year, and how to find, trace and remove the legacy tokens left in your clusters."
description = "Bound Kubernetes service account tokens expire and die with their Pod; Secret-based ones never expire. How to find, trace and retire legacy tokens."
author = "John Marshall"
imageAlt = "A grey bowl heaped with loose green numbered raffle tickets printed with the word TICKET"
imageCredit = "Photo by [Obi](https://unsplash.com/photos/PyO1DiAFPPQ) on Unsplash"
takeaways = [
  "Since Kubernetes v1.22, Pods get service account tokens from the TokenRequest API through a projected volume. These tokens have an expiry and an audience, and stop working when their Pod or ServiceAccount is deleted.",
  "Secret-based tokens (type kubernetes.io/service-account-token) don't expire and don't rotate. Kubernetes stopped creating them automatically in v1.24, but clusters older than that, and anyone who created one by hand, may still have them.",
  "From v1.29, auto-generated legacy tokens unused for a year are labelled invalid, and deleted after a further year unused. Manually created token Secrets are never cleaned up for you.",
  "By default kube-apiserver extends admission-injected Pod tokens to one year and marks them stale after about an hour. The serviceaccount_stale_tokens_total metric and the authentication.k8s.io/stale-token audit annotation tell you which clients aren't reloading.",
  "Find legacy tokens with a field selector on the Secret type, read their legacy-token-last-used label, trace callers through audit annotations, then move each caller to kubectl create token, a projected token or workload identity before you delete the Secret."
]

[[faq]]
q = "Do Kubernetes service account tokens expire?"
a = "Tokens issued by the TokenRequest API do: a projected token defaults to one hour and must be at least ten minutes. Secret-based tokens of type kubernetes.io/service-account-token do not expire and stay valid until the Secret or ServiceAccount is deleted, apart from automatic invalidation of unused auto-generated ones from v1.29."
[[faq]]
q = "Why does my Pod's token show an expiry a year away?"
a = "kube-apiserver's --service-account-extend-token-expiration flag defaults to true in the Kubernetes source. It extends the tokens the ServiceAccount admission controller injects into Pods to up to one year to avoid breaking clients that never reload the file, and adds a warnafter claim about an hour out. Using the token after warnafter is counted as stale."
[[faq]]
q = "How do I find legacy service account tokens in a cluster?"
a = "List Secrets of type kubernetes.io/service-account-token with kubectl get secrets -A --field-selector type=kubernetes.io/service-account-token. Their kubernetes.io/legacy-token-last-used label shows the last day each was used, and kubernetes.io/legacy-token-invalid-since shows if the control plane has already invalidated it."
[[faq]]
q = "How do I revoke a bound service account token?"
a = "There is no central list of issued tokens. A Pod-bound token dies when its Pod is deleted. To invalidate every token for a ServiceAccount, delete and recreate the ServiceAccount, which changes its UID. Legacy Secret-based tokens are revoked by deleting the Secret."
+++

A Kubernetes service account token is only as safe as its lifetime. Tokens that Kubernetes issues through the TokenRequest API expire, carry an audience, and stop working the moment the Pod they were issued for is deleted. Secret-based tokens, the `kubernetes.io/service-account-token` type, never expire and stay valid until someone deletes the Secret. Kubernetes stopped creating those automatically in v1.24, but clusters that predate it and any team that created one by hand may still have them. Find them, find out who still uses them, move those callers to short-lived tokens, then delete the Secrets.

## Two kinds of token

Both are signed JWTs that a client sends as `Authorization: Bearer <token>`. What differs is how long they live and what they are tied to.

| | Bound token (TokenRequest) | Secret-based token |
|---|---|---|
| How it is issued | TokenRequest API: the kubelet for a projected volume, or `kubectl create token` | A Secret of type `kubernetes.io/service-account-token`; the control plane fills in the token |
| Expiry | Yes. Projected volume default 1 hour, minimum 10 minutes, capped by `--service-account-max-token-expiration` | None |
| Rotation | The kubelet refreshes the file before expiry | None |
| Bound to | A Pod, Secret or Node (by name and UID), plus the ServiceAccount | The Secret and the ServiceAccount |
| Audience | Set per request; defaults to the API server's audiences | API server only |
| Dies when | It expires, or the bound object or ServiceAccount is deleted | The Secret or ServiceAccount is deleted |
| Default since | v1.22 (`BoundServiceAccountTokenVolume` stable) | Auto-created for every ServiceAccount before v1.24 |

The Kubernetes documentation states the trade-off without hedging: Secret-based tokens "don't expire and don't rotate". A leaked bound token gives an attacker an hour, or until the Pod goes away. A leaked Secret-based token gives them that ServiceAccount's permissions until someone notices. What those permissions allow is a separate question, and our [Kubernetes RBAC audit](/posts/kubernetes-rbac-audit-11-permissions-that-escalate-access/) covers the ones that let a ServiceAccount escalate.

## How Kubernetes got here

| Version | Change | Feature gate |
|---|---|---|
| v1.20 | Service account token volume projection stable | — |
| v1.22 | Pods get bound tokens through a projected volume by default | `BoundServiceAccountTokenVolume` |
| v1.24 | Token Secrets no longer auto-created for new ServiceAccounts (beta, on by default) | `LegacyServiceAccountTokenNoAutoGeneration` |
| v1.26 | That change goes GA | `LegacyServiceAccountTokenNoAutoGeneration` |
| v1.28 | Last-used tracking for Secret-based tokens GA | `LegacyServiceAccountTokenTracking` |
| v1.29 | Unused auto-generated tokens invalidated and then deleted (beta, on by default) | `LegacyServiceAccountTokenCleanUp` |
| v1.30 | That clean-up goes GA | `LegacyServiceAccountTokenCleanUp` |
| v1.33 | Creating Node-bound tokens GA | `ServiceAccountTokenNodeBinding` |

Upgrading never removed existing token Secrets. A cluster created on v1.21 and upgraded every quarter since can still hold a never-expiring token for every ServiceAccount that existed back then.

## The clean-up only covers half of the problem

From v1.29, the legacy token cleaner in kube-controller-manager checks every 24 hours. It marks an auto-generated token invalid if all of these are true:

- it is auto-generated, meaning the Secret and the ServiceAccount reference each other;
- no Pod currently mounts it;
- it has not been used for the clean-up period since it was created or last used.

Invalid tokens get a `kubernetes.io/legacy-token-invalid-since` label. If one stays unused for another period, the cleaner deletes it. Both periods default to one year and are set with `--legacy-service-account-token-clean-up-period`.

Two gaps follow from those rules. A token in active use is never invalidated, which is the point, but it also means the riskiest token, the one a CI system or an old script still uses every day, survives. And **manually created token Secrets are never cleaned up**, because they are not auto-generated. Kubernetes still lets you create them, and the docs ask you to "take into account the security implications" when you do.

## The one-year Pod token

There is a less obvious long-lived token in most clusters: the default one in every Pod.

The ServiceAccount admission controller requests tokens with a lifetime of 3,607 seconds. In the Kubernetes source, `--service-account-extend-token-expiration` defaults to true, and the flag's help text says that when it is enabled "admission injected tokens would be extended up to 1 year to prevent unexpected failure during transition, ignoring value of service-account-max-token-expiration." The token also gets a `warnafter` claim at the original expiry.

The example claims in the Kubernetes documentation show exactly this: `exp - iat` is 31,536,000 seconds (365 days), and `warnafter - iat` is 3,607 seconds. We computed both from the published example.

That token is still bound to its Pod, so deleting the Pod invalidates it. But a token copied out of a running Pod, for example through a file-read bug in the application, can stay valid for a long time if the Pod is long-lived. Managed Kubernetes providers set kube-apiserver flags themselves, so check yours.

When a client uses such a token after `warnafter`, the API server accepts it but adds the audit annotation `authentication.k8s.io/stale-token`, naming the subject, and increments `serviceaccount_stale_tokens_total`. Those are the clients that read the token once at start-up and never reload it. Fix them first. The documentation's advice is simple: reload the token file on a schedule, for example every five minutes. Once nothing is stale, you can consider turning the extension off.

## Step 1: inventory Secret-based tokens

```bash
kubectl get secrets -A --field-selector type=kubernetes.io/service-account-token
```

Two labels tell you most of what you need. The API server sets `kubernetes.io/legacy-token-last-used` to the current date whenever a Secret-based token authenticates, both auto-generated and manual ones; the date is a day, not a timestamp. `kubernetes.io/legacy-token-invalid-since` appears once the cleaner has invalidated the token.

This short script turns the JSON into a table. It only reads stdin and changes nothing:

```python
#!/usr/bin/env python3
"""List Secret-based service account tokens from `kubectl get secrets -A -o json`.

Usage: kubectl get secrets -A -o json | python3 sa_token_secrets.py
Read-only: it parses JSON on stdin and prints a table. Python 3.8+.
"""
import json
import sys

LAST_USED = "kubernetes.io/legacy-token-last-used"
INVALID_SINCE = "kubernetes.io/legacy-token-invalid-since"
SA_ANNOTATION = "kubernetes.io/service-account.name"

items = json.load(sys.stdin).get("items", [])
rows = []
for s in items:
    if s.get("type") != "kubernetes.io/service-account-token":
        continue
    md = s.get("metadata", {})
    labels = md.get("labels") or {}
    rows.append((
        md.get("namespace", ""),
        md.get("name", ""),
        (md.get("annotations") or {}).get(SA_ANNOTATION, "?"),
        md.get("creationTimestamp", ""),
        labels.get(LAST_USED, "-"),
        labels.get(INVALID_SINCE, "-"),
    ))

header = ("NAMESPACE", "SECRET", "SERVICEACCOUNT", "CREATED", "LAST-USED", "INVALID-SINCE")
for r in [header] + sorted(rows):
    print("\t".join(r))
print(f"\n{len(rows)} Secret-based service account token(s)", file=sys.stderr)
```

We ran it with Python 3.13 against a sample `kubectl` JSON document with two token Secrets and one ordinary Secret; it listed the two tokens with their labels and skipped the other. Not reading the token value is deliberate: the inventory does not need it.

Sort the output into three groups:

| LAST-USED | INVALID-SINCE | What it means | Action |
|---|---|---|---|
| Recent | `-` | Someone depends on it today | Trace the caller (step 2), migrate, then delete |
| Old or `-` | `-` | Not used recently, or not used since tracking started | Confirm with audit logs, then delete |
| Any | A date | Already invalidated by the control plane | Delete now rather than waiting a year |

A missing last-used label does not prove a token was never used. Tracking only began when your cluster first ran a version with it enabled; the control plane records that date in the `kube-system/kube-apiserver-legacy-service-account-token-tracking` ConfigMap.

## Step 2: find out who still uses them

The API server adds an audit annotation every time a Secret-based token authenticates:

| Audit annotation | Meaning |
|---|---|
| `authentication.k8s.io/legacy-token-autogenerated-secret` | An auto-generated token Secret was used; the value is the Secret name |
| `authentication.k8s.io/legacy-token-manual-secret` | A manually created token Secret was used |
| `authentication.k8s.io/legacy-token-invalidated` | Someone tried an invalidated token; the value is `<secret>/<namespace>` |

Search your audit logs for those keys and read `sourceIPs` and `userAgent` from the same events to identify the caller. If you don't have audit logs, the counters `serviceaccount_legacy_auto_token_uses_total` and `serviceaccount_legacy_manual_token_uses_total` at least tell you whether usage is going up or down. Clients using an auto-generated token also get an API warning asking them to use TokenRequest tokens instead, which sometimes shows up in CI logs.

## Step 3: move each caller to a short-lived token

| Caller | Replacement |
|---|---|
| A workload in the cluster | The default projected token, mounted automatically. Make sure the client reloads the file. |
| A workload that sends the token to another service | A projected `serviceAccountToken` volume with that service's `audience` and an explicit `expirationSeconds` |
| A person or a one-off job | `kubectl create token <serviceaccount> --duration=1h`; the issued duration may differ from what you ask for |
| CI/CD or another external system | Prefer an identity the cluster already trusts, such as your provider's workload identity or OIDC. If you must use a ServiceAccount token, issue a short one per run with `kubectl create token`. |

A projected token for a specific audience looks like this, adapted from the Kubernetes documentation example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  serviceAccountName: build-robot
  containers:
  - name: app
    image: registry.example.com/app:1.4.2
    volumeMounts:
    - mountPath: /var/run/secrets/tokens
      name: vault-token
  volumes:
  - name: vault-token
    projected:
      sources:
      - serviceAccountToken:
          path: vault-token
          expirationSeconds: 7200
          audience: vault
```

A service that receives this token should reject any token whose audience is not its own. If you write that validation yourself, the Kubernetes project recommends the TokenReview API over OIDC discovery, because TokenReview fails immediately once the bound Pod is deleted, while plain JWT validation would keep accepting the token until it expires. Our guide to [JWT security mistakes](/posts/jwt-security-9-mistakes-that-can-turn-tokens-into-an-attack-path/) covers the audience and expiry checks that apply here too.

## Step 4: delete, and stop new ones appearing

When a token Secret has no callers left, delete it:

```bash
kubectl -n <namespace> delete secret <token-secret-name>
```

If a caller you missed fails afterwards, you will see it in your audit logs and can issue a short-lived replacement. That is a better failure than an unexpired credential nobody owns.

To keep new ones from appearing, decide who may create Secrets of this type. RBAC can't filter on a Secret's `type` field, so use an admission policy for that rule; our walkthrough of [ValidatingAdmissionPolicy with CEL](/posts/kubernetes-validatingadmissionpolicy-cel-rules-for-registry-allowlists-and-memory-limits-with-a-warn-first-rollout/) shows the warn-first rollout pattern. Expressions along the lines of `object.type != 'kubernetes.io/service-account-token'`, scoped to namespaces where nobody should create them, will do.

## Reduce what any token can do

- **Don't mount tokens Pods don't use.** Set `automountServiceAccountToken: false` on the ServiceAccount or the Pod; the Pod setting wins if they disagree. Most application Pods never call the Kubernetes API.
- **Give each workload its own ServiceAccount** instead of sharing `default`, so a token's permissions match one workload.
- **Know how to revoke.** There is no central record of issued bound tokens, so you can't revoke one by ID. Delete the Pod to kill a Pod-bound token. To kill every token for a ServiceAccount, delete and recreate it; the new UID invalidates the tokens issued for it.
- **Don't mount projected tokens with `subPath`.** A `subPath` mount never receives the refreshed file, so the application ends up with an expired token.

## Common mistakes

- Treating an upgrade to v1.24 or later as the fix. It stopped new auto-generated tokens; it didn't remove old ones.
- Waiting for the automatic clean-up. It ignores manual tokens and anything still in use, and takes up to two years by default.
- Copying a Pod's token out for use elsewhere because it "lasts a year". It is bound to that Pod and dies with it, and the API server counts it as stale after about an hour.
- Hunting for leaked tokens in Secrets but not in Git, CI variables and kubeconfig files on laptops, where most old Secret-based tokens end up.

## Limits of this article

This guide follows the upstream Kubernetes documentation for v1.37 and the Kubernetes source on the main branch. Managed services (EKS, GKE, AKS and others) set kube-apiserver and kube-controller-manager flags themselves and may disable or change the token extension, the clean-up period or audit logging. Check your provider's documentation before relying on any default described here. We tested the inventory script against sample JSON, not a live cluster.

## Sources and verification

| Important claim | Source | Verification |
|---|---|---|
| Secret-based tokens don't expire or rotate; auto-creation stopped in v1.24; manual creation still possible | [Service Accounts concept page](https://kubernetes.io/docs/concepts/security/service-accounts/) | Verified |
| Bound object types; v1.29 invalidation and deletion after one year each; cleaner conditions and 24-hour check; labels; `--legacy-service-account-token-clean-up-period`; no central record of short-lived tokens; recreate ServiceAccount to revoke | [Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/) | Verified |
| `kubectl create token --duration`; projection flags; example claims with `warnafter`; kubelet refresh at 80% of TTL or 24 hours; reload every five minutes | [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) | Verified; lifetimes computed from the example |
| `expirationSeconds` defaults to 1 hour, minimum 600 seconds; `subPath` mounts don't receive updates | [Projected Volumes](https://kubernetes.io/docs/concepts/storage/projected-volumes/) | Verified |
| TokenReview recommended over OIDC discovery because it fails once bound objects are deleted | [Service Accounts concept page](https://kubernetes.io/docs/concepts/security/service-accounts/) | Verified |
| Feature gate stages and versions | [Feature gates reference](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/) (website repository source) | Verified |
| 3,607-second injected lifetime; one-year extension; extension defaults to true; stale-token and legacy-token audit annotations; last-used label set for manual and auto-generated tokens; metric names | Kubernetes source: [claims.go](https://github.com/kubernetes/kubernetes/blob/master/pkg/serviceaccount/claims.go), [legacy.go](https://github.com/kubernetes/kubernetes/blob/master/pkg/serviceaccount/legacy.go), [metrics.go](https://github.com/kubernetes/kubernetes/blob/master/pkg/serviceaccount/metrics.go), [authentication options](https://github.com/kubernetes/kubernetes/blob/master/pkg/kubeapiserver/options/authentication.go) | Verified from main branch; released versions may differ |
