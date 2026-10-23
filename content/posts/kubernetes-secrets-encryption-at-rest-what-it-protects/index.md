+++
title = "Kubernetes Secrets Encryption at Rest: What It Protects"
date = 2026-10-23T04:45:00Z
tags = ["kubernetes", "secrets management", "encryption", "etcd"]
categories = ["cloud-security"]
summary = "Kubernetes stores Secrets unencrypted in etcd unless you configure an EncryptionConfiguration. Turning it on protects etcd data, but not against anyone who can read Secrets through the API, create Pods, or, with local keys, read the control plane host. This guide maps each threat to the control that actually stops it, with a tested config checker."
description = "Kubernetes Secrets encryption at rest protects etcd data, not API readers or Pod creators. What each provider stops, how to verify it, and a config checker."
author = "Craig Leslie"
imageAlt = "Rows of ornate brass deposit boxes with keyholes and numbers 564 to 624, viewed at an angle"
imageCredit = "Photo by [Tim Evans](https://unsplash.com/photos/Uf-c4u1usFQ) on Unsplash"
takeaways = [
  "By default Kubernetes writes Secrets to etcd in plain text; the default identity provider gives no confidentiality. Base64 in a manifest is encoding, not encryption.",
  "Encryption at rest is configured in an EncryptionConfiguration passed to kube-apiserver with --encryption-provider-config. The first provider listed encrypts new writes; later providers are only tried for reads.",
  "It protects the stored data in etcd. It does nothing against a user with get, list or watch on Secrets, or a user who can create Pods in the namespace, because the API server decrypts for them.",
  "Local-key providers (aescbc, aesgcm, secretbox) keep the key in a file on every control plane host, so a host compromise exposes it. KMS v2, stable since Kubernetes v1.29, keeps the key-encryption key outside the cluster.",
  "Enabling encryption only affects new writes. Rewrite existing Secrets with kubectl get secrets --all-namespaces -o json | kubectl replace -f -, then confirm the k8s:enc: prefix in etcd."
]

[[faq]]
q = "Are Kubernetes Secrets encrypted by default?"
a = "No. The Kubernetes documentation says Secrets are stored unencrypted in etcd by default. If kube-apiserver runs without --encryption-provider-config, or the first provider for Secrets is identity, new Secrets are written in plain text. Managed services may differ, so check your provider's documentation."
[[faq]]
q = "Does encryption at rest stop kubectl get secret from showing values?"
a = "No. The API server decrypts Secrets for any authorized request, so anyone with get, list or watch on Secrets still sees the values. Least-privilege RBAC is the control for API access."
[[faq]]
q = "Which encryption provider should I use?"
a = "The Kubernetes documentation rates KMS v2 the strongest option and a good choice when using a third-party key management tool. It recommends against aescbc because of CBC's vulnerability to padding oracle attacks, and against aesgcm unless you automate key rotation."
[[faq]]
q = "How do I know existing Secrets are encrypted?"
a = "Read one Secret directly from etcd with etcdctl and check that the stored value begins with k8s:enc: followed by the provider name, for example k8s:enc:aescbc:v1:key1. Secrets written before you enabled encryption stay in plain text until rewritten."
+++

Kubernetes encryption at rest protects one thing: the Secret data stored in etcd. It stops someone who gets etcd's data, or a copy of it, from reading Secrets in plain text. It does not stop anyone the API server is willing to serve, and that group is larger than most teams assume: everyone with `get`, `list` or `watch` on Secrets, and everyone who can create a Pod in the namespace. Turn encryption on, but don't count it as your Secrets access control.

## What Kubernetes does by default

The Kubernetes documentation is blunt: "Kubernetes Secrets are, by default, stored unencrypted in the API server's underlying data store (etcd)." The default provider is `identity`, which, in the docs' words, "does not encrypt stored data and provides *no* additional confidentiality protection."

The base64 you see in a Secret manifest doesn't change that. The good-practices page says it plainly: "Base64 encoding is *not* an encryption method, it provides no additional confidentiality over plain text." A Secret manifest committed to Git is a plain-text credential in Git.

Managed Kubernetes services run the control plane for you, and their defaults may differ from upstream. This article describes upstream behavior; check your provider's documentation for what it encrypts by default and whether it supports envelope encryption with your own key.

## Who can read a Secret

Before choosing an encryption provider, list who can read Secrets at all. Encryption at rest changes only the last two rows of this table.

| Who | How they read Secrets | Does encryption at rest stop it? | Control that does |
|---|---|---|---|
| A user or service account with `get` on Secrets | Asks the API server | No; the API server decrypts for them | Least-privilege RBAC |
| A subject with `list` or `watch` on Secrets | A list response includes the contents of every Secret returned | No | Restrict `list`/`watch` to system components |
| Anyone who can create Pods, Deployments or other workloads in the namespace | Mounts any Secret in that namespace into a Pod they control | No | Separate namespaces by trust; RBAC on workload creation |
| Someone with access to etcd, its disks or a copy of its data | Reads stored bytes directly | **Yes** | Encryption at rest; restrict etcd access |
| Someone with root on a control plane host | Reads etcd data *and* the local key file | Only with KMS | KMS provider; host hardening |

The middle row surprises people. The Secret documentation says "anyone who is authorized to create a Pod in a namespace can use that access to read any Secret in that namespace; this includes indirect access such as the ability to create a Deployment." Our [Kubernetes RBAC audit](/posts/kubernetes-rbac-audit-11-permissions-that-escalate-access/) covers how to find these grants in your bindings; this article stays on the storage side.

## How encryption at rest is configured

You pass an `EncryptionConfiguration` file to `kube-apiserver` with `--encryption-provider-config`. A minimal example for Secrets with a local AES-CBC key, shaped like the one in the Kubernetes task page:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <BASE64-ENCODED 32-BYTE KEY>
      - identity: {} # lets the API server read Secrets written before encryption
```

Three rules from the documentation decide what this file does:

- **The first provider encrypts.** "The first provider in the list is used to encrypt resources written into the storage." If `identity` is first, new writes are plain text even if other providers are listed.
- **Later providers only decrypt.** On reads, each matching provider is tried in order. The trailing `identity` is what lets the API server keep reading old plain-text Secrets during a migration. Once everything is rewritten, you can remove it.
- **Order across rules matters too.** The `resources` list is processed in order, so an earlier rule that names `secrets` with `identity` will win over a later `*.*` wildcard that encrypts. Wildcards are `*.` for the core group (which includes Secrets) and `*.*` for everything.

## Which provider stops which attacker

| Provider | Key location | Kubernetes docs say |
|---|---|---|
| `identity` | None | No encryption; the default |
| `aescbc` | Local file on each control plane host | Not recommended: CBC is vulnerable to padding oracle attacks |
| `aesgcm` | Local file | Not recommended unless you automate key rotation |
| `secretbox` | Local file | Newer cryptography that may not pass high-review environments |
| `kms` v1 | External KMS | Deprecated since Kubernetes v1.28 |
| `kms` v2 | External KMS | Strongest; envelope encryption with AES-GCM data keys; stable from v1.29 |

The key-location column is the one that maps to threats. With a local key, the docs say encryption "protects against an etcd compromise, but it fails to protect against a host compromise," because the key sits in the configuration file on the host. With KMS, Kubernetes encrypts data with a data encryption key and the KMS wraps that key, so an attacker "would need to compromise etcd **and** the third-party KMS provider."

A local key is still worth having. It turns a leaked etcd snapshot or a mis-scoped etcd client certificate into ciphertext rather than credentials. Our view: use KMS v2 where you have a KMS to point at, and treat a local `aescbc` key as a stopgap you plan to replace.

## Checking a configuration file

We wrote a short checker that reads an `EncryptionConfiguration` and flags the weak settings above. It reads only the file and does not contact a cluster. It needs Python 3 and PyYAML; we ran it with Python 3 and PyYAML 6.0.3 against three sample files. It is illustrative: it does not validate the whole schema, and it reads `kms` without an `apiVersion` as v1.

```python
#!/usr/bin/env python3
"""Flag weak settings in a Kubernetes EncryptionConfiguration file.
Usage: python3 check_encryption_config.py /path/to/encryption-config.yaml
Reads the file only; it does not contact a cluster."""
import sys
import yaml

LOCAL_KEY = {"aescbc", "aesgcm", "secretbox"}

def covers_secrets(resources):
    return any(r in ("secrets", "*.", "*.*") for r in resources)

def main(path):
    with open(path) as f:
        cfg = yaml.safe_load(f)
    findings = []
    secrets_rule_seen = False
    for i, rule in enumerate(cfg.get("resources", [])):
        res = rule.get("resources", [])
        if not covers_secrets(res):
            continue
        # The first matching rule wins, so only the first rule covering secrets counts.
        if secrets_rule_seen:
            continue
        secrets_rule_seen = True
        providers = rule.get("providers", [])
        first = next(iter(providers[0])) if providers else None
        if first == "identity":
            findings.append(f"rule {i}: first provider is identity, so new Secrets are written in plain text")
        elif first in LOCAL_KEY:
            findings.append(f"rule {i}: first provider is {first}; key sits in this file on every control plane host")
            if first == "aescbc":
                findings.append(f"rule {i}: aescbc is not recommended by the Kubernetes docs (padding oracle)")
        elif first == "kms":
            ver = providers[0]["kms"].get("apiVersion", "v1")
            if ver != "v2":
                findings.append(f"rule {i}: KMS v1 is deprecated since Kubernetes v1.28; move to KMS v2")
        if any("identity" in p for p in providers[1:]):
            findings.append(f"rule {i}: identity fallback present; unencrypted Secrets can still be read (expected during migration)")
    if not secrets_rule_seen:
        findings.append("no rule covers secrets: Secrets are stored unencrypted")
    for f_ in findings:
        print("WARN", f_)
    if not findings:
        print("OK no weak settings found for secrets")
    return 1 if findings else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
```

Results on our samples: the `aescbc`-plus-`identity` file above produced three warnings and exit code 1; a file using `kms` with `apiVersion: v2` printed `OK` and exited 0; a file that only configured ConfigMaps reported that no rule covers Secrets. The non-zero exit code lets you run it in CI against the configuration you deploy to control plane nodes.

## Rolling it out without locking yourself out

The Kubernetes task page walks through the full procedure. The steps that most often go wrong:

1. **Every control plane host needs the same file and key.** The docs say to copy the key to every control plane host over a secure channel, and to restart each API server. An API server without the key can't read Secrets another one encrypted.
2. **Existing Secrets are not touched.** Encryption applies on write. Rewrite everything once all API servers have the new configuration:

   ```shell
   kubectl get secrets --all-namespaces -o json | kubectl replace -f -
   ```

3. **Verify in etcd, not through the API.** The API always returns decrypted values, so `kubectl get secret` proves nothing. Read a Secret with `etcdctl get /registry/secrets/<namespace>/<name>` and check that the stored value starts with `k8s:enc:<provider>:v1:<key-name>:`, for example `k8s:enc:aescbc:v1:key1:`.
4. **Rotate keys in two passes.** The docs' zero-downtime procedure: add the new key as the *second* entry on every control plane node and restart all API servers so each can decrypt with it; back the key up; then make it the first entry, restart again, rewrite all Secrets, and only then remove the old key. Losing every copy of a key means deleting the resources encrypted with it.

## Controls that matter as much as encryption

Encryption at rest is one line in the Kubernetes Secrets good-practices list. The others address the readers in the first table:

- **Restrict `get`, `list` and `watch`.** The docs say to limit `watch` and `list` to "the most privileged, system-level components" and caution that `list` "implicitly lets the subject fetch the contents of the Secrets."
- **Separate namespaces by trust.** Pod creation reaches every Secret in a namespace, so a namespace is the practical boundary. Enforce [Pod Security Admission](/posts/kubernetes-pod-security-admission-namespace-labels-modes-and-a-safe-rollout-from-warn-to-enforce/) where workload creators are less trusted, and consider [ValidatingAdmissionPolicy](/posts/kubernetes-validatingadmissionpolicy-cel-rules-for-registry-allowlists-and-memory-limits-with-a-warn-first-rollout/) for rules Pod Security doesn't cover.
- **Audit Secret access at the Metadata level.** The example audit policy in the Kubernetes docs logs Secrets and ConfigMaps at `Metadata`, which records who accessed what without writing values into your logs. The good-practices page suggests alerting on events such as one user reading many Secrets at once.
- **Use short-lived credentials and external stores.** The docs recommend short-lived Secrets and mention the Secrets Store CSI Driver for keeping values in an external store. The same reasoning drives [least privilege in cloud IAM](/posts/aws-iam-least-privilege-a-practical-guide-to-finding-excess-permissions/): a credential that expires in an hour is worth less to whoever reads it.

## Limits of this article

This describes upstream Kubernetes as documented on kubernetes.io at the time of writing. We tested the checker against sample files only, not against a live cluster or a managed service. We have not tested the encryption rollout procedure ourselves; follow the Kubernetes task page and your distribution's documentation, and rehearse on a non-production cluster first.

## Sources and verification

| Important claim | Source | Verification |
|---|---|---|
| Secrets stored unencrypted in etcd by default; Pod creators can read any Secret in the namespace | [Kubernetes: Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) | Verified |
| Base64 is not encryption; list access reveals contents; short-lived Secrets, audit alerting, Secrets Store CSI Driver | [Kubernetes: Good practices for Kubernetes Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/) | Verified |
| list and watch reveal contents; workload creation grants namespace Secret access | [Kubernetes: RBAC good practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/) | Verified |
| identity default; first provider encrypts; rule ordering; provider ratings; local vs KMS key threat model; KMS v1 deprecated v1.28; KMS v2 stable v1.29; rewrite command; k8s:enc: prefix; key rotation steps | [Kubernetes: Encrypting confidential data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) | Verified |
| Example audit policy logs Secrets and ConfigMaps at Metadata level | [Kubernetes: Auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/) | Verified |
| A local key turns a leaked etcd copy into ciphertext | Editorial inference from the encrypt-data page's statement that local keys protect against etcd compromise | Qualified |
