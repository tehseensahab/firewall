# Editorial log 2026-10-25

GSC: gsc-wizard connector refused all calls (payment_required: trial ended / no subscription). Topics chosen from the 2026-10-24 next-session candidates and the KEV feed.

## Article 1: VeloCloud Orchestrator CVE-2026-114625: Patch and Hunt
Slug: velocloud-orchestrator-cve-2026-114625-patch-and-hunt | security-operations | John Marshall | primary keyword: velocloud orchestrator cve-2026-114625

| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| SQLi (CWE-89), any authenticated user gains operator privileges / "superuser operator" | CVE-2026-114625 record (Arista CNA), cvelistV5 raw | published 2026-10-22, updated 2026-10-24 | VERIFIED | on-prem VCO |
| Min role Enterprise Read Only; exposed by default; no config prevents exposure | same record, configurations | 2026-10-22 | VERIFIED | |
| Affected 5.2.0-<5.2.3.18, 6.1.0-<6.1.3.10, 6.4.0-<6.4.2.12; defaultStatus unaffected; no 7.0 row | same record, affected | 2026-10-22 | VERIFIED (7.0 status QUALIFIED) | |
| Hosted incl. Dedicated affected and patched | same record | 2026-10-22 | VERIFIED | |
| CVSS 3.1 9.9 vector; CVSS 4.0 9.4 | same record | 2026-10-22 | VERIFIED | |
| External discovery; BUG2043622; advisory 0199 | same record source field | 2026-10-22 | VERIFIED | |
| Workarounds list | same record | 2026-10-22 | VERIFIED | |
| Advisory 0199 dated Oct 22 | arista.com advisories listing (WebFetch) | 2026-10-22 | VERIFIED | advisory page itself not fetched |
| KEV added 10-23, due 10-26, forensicTriage Yes, ransomware Unknown | kev-data raw JSON v2026.10.23 | 2026-10-23 | VERIFIED | |
| SSVC active / no / total | CISA ADP in CVE record | 2026-10-22 | VERIFIED | |
| Arista's Oct record doesn't say "actively exploited" (Jul record does) | both CVE records | | VERIFIED | |
| CVE-2026-16812: Jul 27, CWE-78, PR:N, CVSS 10, fixes 5.2.3.14/6.1.3.4/6.4.2.4/7.0.0.1, KEV 07-27 | CVE record; KEV; BleepingComputer 2026-07-27 | 2026-07-27 | VERIFIED | |
| CVE-2026-93952: Sep 22, CWE-20, cert-auth conditions, affected <=5.2.3.15/6.1.3.7/6.4.2.7/7.0.0.2, fixes 5.2.3.16/6.4.2.8, IOCs, evidence preservation | Arista SA 0183 (WebFetch); CVE record; KEV | 2026-09-22 | VERIFIED | |
| Build "still affected by" table | computed with python from 3 CVE records' version ranges | | VERIFIED (computed) | not tested on VCO |
| Whether 0183 IOCs relate to 0199 | none | | NOT VERIFIED -> stated as "Arista has not said" | |
| Hunt commands | illustrative, not run on VCO | | labelled illustrative | |

## Article 2: Kubernetes Audit Policy: What to Log, at What Level
Slug: kubernetes-audit-policy-what-to-log-and-at-what-level | cloud-security | Craig Leslie | primary keyword: kubernetes audit policy

| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| Stages, levels, first-match, no logging without flag, zero rules illegal | kubernetes/website audit.md (raw, main) | fetched 2026-10-25 | VERIFIED | |
| Log backend flags, `-` stdout, batching off for log; webhook batch default 400 / 30s; truncation off by default; memory note | same | | VERIFIED | |
| Policy fields; sourceIPs/userAgent warnings; empty resources = whole group | kubernetes/apiserver audit/v1 types.go | master | VERIFIED | |
| GCE policy: secrets/configmaps/serviceaccounts/token/tokenreviews at Metadata; "Get responses can be large" | kubernetes configure-helper.sh | master | VERIFIED | |
| authorization.k8s.io/decision annotation | apiserver filters/authorization.go | master | VERIFIED | |
| Test results (Secret metadata only, RBAC RequestResponse bodies, forbid, impersonatedUser, exec URI with command, exec verbs get+create, token request metadata) | own run: envtest kube-apiserver v1.34.1 + etcd, RBAC, static tokens | 2026-10-25 | VERIFIED | single apiserver, no nodes |
| Wrong rule order logs Secret base64 data ("UzNjcmV0VmFsdWUtNDU2") | own run | 2026-10-25 | VERIFIED | |
| jq queries | run against test audit.log | 2026-10-25 | VERIFIED | |
| EKS: off by default, audit stream name, best effort, CloudWatch charges | docs.aws.amazon.com control-plane-logs | fetched 2026-10-25 | VERIFIED | |
| AKS: kube-audit-admin excludes get/list; diagnostic setting required; kube-audit costly | docs.azure.cn monitor-apiserver (China mirror) | fetched 2026-10-25 | QUALIFIED | mirror, not learn.microsoft.com |
| Managed providers control the policy | general | | QUALIFIED (worded "generally") | |
| GKE | not researched | | removed | |

## Skipped / blocked
- gsc-wizard: payment_required.
- dl.k8s.io blocked by proxy (403); used envtest binaries from GitHub releases instead.
- Arista SA 0199 page not found via search; not fetched (rule: no constructed URLs). Content taken from CVE record.

## Next-session candidates
1. Palo Alto PAN-OS CVE-2026-0322 (KEV 2026-10-14): management-interface code injection, fixed releases, exposure checks
2. Ivanti Connect Secure CVE-2026-104935 (KEV 2026-10-13): auth bypass by spoofing; fixed versions and integrity checks
3. Kubernetes audit log detections: building alerts for exec, impersonation, RBAC escalation and Secret enumeration in a SIEM (follow-up to the audit policy guide)

## Publication status
Pushed to main: 3291171 (posts), 7d6c2d4 (covers, by workflow), c569550 (alt text + log). Local Hugo build: 0 errors, both pages present, no dead /posts/ links. Live check NOT confirmed: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED (not retried) and shell curl is blocked by the proxy. Owner should spot-check both URLs.
