# Editorial log 2026-10-22

Catch-up session after the scheduled task stopped (no new articles Oct 19-21; the backlog ended Oct 19). Six articles published, dated 2026-10-22 (not backdated). Bylines alternate John Marshall / Craig Leslie. Covers fetched with scripts/fetch-covers.sh and viewed before alt text was written.

## 1. Plex Media Server CVE chain (security-operations, John Marshall)
Slug: plex-media-server-cve-2026-96656-exploited-chain-patch-and-hunt
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Four CVEs, affected before 1.43.3.10861, descriptions, CWEs, CVSS 3.1/4.0 | cvelistV5 records (cisa-cg CNA) | published 2026-09-23, updated 2026-10-21 | VERIFIED | |
| VA-26-266-01 risk evaluation; fix 1.43.3.10861; CVE-2026-96651 details and SSVC none | CISA CSAF JSON | 2026-09-23 | VERIFIED | |
| KEV added 2026-10-20; due 10-23 (96654, 96656) and 11-03 (96652, 96655); forensic triage only 96656; chaining note | KEV JSON 2026.10.21 | | VERIFIED | |
| CISA SSVC values per CVE | CVE record ADP | 2026-10-19/20 | VERIFIED | |
| Sept 1 notice; Oct 19 update: widely exploited, PoC Oct 16, miners/proxies, indicators, remediation, port 32400 advice | Plex forum t/942319 | 2026-09-01, 2026-10-19 | QUALIFIED | Vendor statements |
| Chain sequence | Our reading | | QUALIFIED | Labelled as interpretation |

## 2. BeyondTrust Remote Support CVE-2026-102764 (security-operations, Craig Leslie)
Slug: beyondtrust-remote-support-cve-2026-102764-patch-and-hunt
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Description, CWE-290, <=26.2.3, CVSS 4.0 9.3 vector | CVE record (BT CNA) | 2026-10-15 | VERIFIED | |
| SSVC active/yes/total; KEV 10-16, due 10-19, forensic triage Yes | CVE ADP; KEV JSON | | VERIFIED | |
| Timeline Aug 29 - Oct 15, two customers, 27 minutes, PRA precautionary patch, SaaS auto-patched, hunting, rotation, Sev 1 | BeyondTrust blog bt26-05 | updated 2026-10-16 | VERIFIED | Vendor advisory page bt26-05 did not load |
| BT26-05-RS for 24.3.1-26.2.3; upgrade first; SaaS patched Oct 9 | Canadian Cyber Centre AL26-025; Google GTIG | 2026-10-16; 2026-10-15 | VERIFIED | Two sources agree |
| Attribution, SAWFLY/BARECLAW, paths, HAProxy route, hashes, response steps | Google GTIG blog | 2026-10-15 | QUALIFIED | Google's analysis |
| Host FS not auditable; logs can't be recovered | Rapid7 | 2026-10-19 | QUALIFIED | Secondary |

## 3. Kubernetes NetworkPolicy default deny (cloud-security, John Marshall)
Slug: kubernetes-networkpolicy-default-deny-safe-rollout
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Isolation semantics, additive, both ends, node traffic, plugin required, policyTypes default, selector example, DNS caution, metadata.name label, ipBlock, protocols, hostNetwork, unsupported list, existing connections, startup timing | kubernetes/website network-policies.md (v1.37 site) | read 2026-10-22 | VERIFIED | |
| CoreDNS k8s-app=kube-dns label | dns-debugging-resolution.md | | VERIFIED | Managed clusters may differ (stated) |
| Namespace patch widens NetworkPolicy | rbac-good-practices.md | | VERIFIED | |
| Manifests valid | kubeconform 0.6.7 -strict, k8s 1.34 schema | 2026-10-22 | VERIFIED | Not applied to a cluster |
| Rollout order | Own | | QUALIFIED | Corrected during edit: DNS allow policy isolates egress on its own |

## 4. Kubernetes RBAC audit (identity-access, Craig Leslie)
Slug: kubernetes-rbac-audit-11-permissions-that-escalate-access
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| 11 escalation risks, nodes/proxy get not read-only, weak namespace boundaries, system:masters, wildcards, deleted users, hardening | rbac-good-practices.md | read 2026-10-22 | VERIFIED | |
| escalate/bind restrictions, resourceNames example, cluster-scoped needs ClusterRoleBinding | rbac.md | | VERIFIED | |
| Kubelet subresource mapping; KubeletFineGrainedAuthz beta default-on 1.33, stable 1.36 | kubelet-authn-authz.md; feature-gate page | | VERIFIED | |
| Cert organization fields = groups | authentication.md | | VERIFIED | |
| can-i with --as | authorization.md | | VERIFIED | |
| automountServiceAccountToken precedence | configure-service-account.md | | VERIFIED | |
| Script output | Run, Python 3.13, 5-binding fixture | 2026-10-22 | VERIFIED | Not run on a cluster |

## 5. Mass assignment (appsec, John Marshall)
Slug: mass-assignment-vulnerability-how-to-stop-clients-setting-role-admin
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Definition, names, CWE-915, GitHub 2012 (as cited), allowlist, DTO not authorization, nested | OWASP Mass Assignment Cheat Sheet (GitHub master) | read 2026-10-22 | VERIFIED | GitHub incident via OWASP only |
| API3:2023 merges excessive data exposure and mass assignment; API1 BOLA | OWASP API-Security repo | | VERIFIED | |
| Spring safe binding, setAllowedFields, declarativeBinding, disallowedFields deprecated in 7.1 | spring-framework main docs source | | VERIFIED | Current docs statement |
| Rails ForbiddenAttributesError, params.expect in 8.0 (absent in 7-2-stable), empty-hash warning | Rails guide (main), 8-0-stable changelog and source | | VERIFIED | |
| Flask/Pydantic demo output | Run: Python 3.13, Flask 3.1.3, Pydantic 2.13.5 | 2026-10-22 | VERIFIED | |
| @RequestBody not via data binder | Own note | | QUALIFIED | |

## 6. LLM05 improper output handling (ai-security, Craig Leslie)
Slug: llm-improper-output-handling-treat-model-output-as-untrusted-input
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| LLM05:2025 definition, outcomes, conditions, examples, mitigations, scenarios | OWASP LLM Top 10 repo 2_0_vulns/LLM05 | read 2026-10-22 | VERIFIED | |
| LLM01:2025 is Prompt Injection | Same repo | | VERIFIED | |
| Sanitizer, SQL and action-allowlist test results | Run: Markdown 3.10.3, nh3 0.3.7, Pydantic 2.13.5, SQLite | 2026-10-22 | VERIFIED | |
| Python-Markdown passes raw HTML | Observed in test | | VERIFIED | That version |

## Site checks
- hugo --minify: no errors; all six posts built with covers, canonical, no noindex; no dead internal links.
- No duplicate cover ids added (pre-existing duplicates unchanged).

## Flag for owner
- Backlog post webhook-security-hmac-signatures-timestamps-and-replay-protection (Oct 19) overlaps how-to-secure-webhooks-against-replay-attacks-and-forged-requests (Oct 18): likely keyword cannibalization; consider merging and redirecting.

## Next-session candidates
1. CVSS v4.0 supplemental metrics and when vendors fill them in
2. Kubernetes Secrets: who can read them (RBAC, pod creation) versus encryption at rest
3. OWASP LLM06:2025 Excessive Agency, implementation patterns for tool permissions
