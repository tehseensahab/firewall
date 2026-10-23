# Editorial log 2026-10-23

Run: scheduled, unattended. GSC Wizard unavailable (payment_required: trial ended / no subscription), so topics were chosen from KEV (last 14 days) and the previous log's candidates. claude/INDEX.md did not exist; built from front matter and committed. No claude/DAILY.md.

## Article 1: Atlassian CVE-2026-21589 File Read: Patch and Hunt
Slug: atlassian-cve-2026-21589-data-center-file-read-patch-and-hunt | security-operations | John Marshall | primary keyword: atlassian cve-2026-21589

| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| 8 products affected; unauthenticated web-root file read; exact path needed; no enumeration | CVE record (cvelistV5 raw) | published 2026-10-05, updated 2026-10-19 | VERIFIED | Data Center + Crucible/Fisheye |
| CWE-552; CVSS 4.0 9.3, vector AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:H/SI:H/SA:H | CVE record CNA metrics; KEV cwes | 2026-10-05 | VERIFIED | |
| Fixed versions per product (table) | CVE record affected[] (8 entries, counted by code) | 2026-10-05 | VERIFIED | |
| SSVC active / no / total | CVE record CISA ADP | 2026-10-15 | VERIFIED | |
| KEV added 2026-10-15, due 2026-10-18; BOD 26-04 wording in all 24 October KEV entries | KEV JSON 2026.10.21 (counted by code) | 2026-10-21 | VERIFIED | |
| Cloud patched; WAF/RewriteValve/urlrewrite mitigations; "limited and not a replacement for patching"; EOL may be affected | Atlassian JRASERVER-79546 (WebFetch) | 2026-10-05 | VERIFIED | Jira ticket; other products' tickets not fetched |
| watchTowr :: traversal root cause, web.xml read, crowd.properties -> jira-administrators | Rapid7 ETR summarizing watchTowr | 2026-10-07/16 | QUALIFIED | secondary; watchTowr post not reached |
| Exploitation attempts reported by Previdian 2026-10-06 (Tuesday, verified by code) | Help Net Security | 2026-10-07 | QUALIFIED | |
| PoC availability | Help Net (checker only) vs Rapid7 (PoC scripts + Nuclei template) | | QUALIFIED | disagreement stated in article |
| Log-scan script | our code, run on 5-line synthetic log; 3 hits as described | 2026-10-23 | VERIFIED | illustrative |
Removed: none. Atlassian main advisory page (confluence.atlassian.com) and community post not fully readable; BleepingComputer fetch failed.

## Article 2: Kubernetes Secrets Encryption at Rest: What It Protects
Slug: kubernetes-secrets-encryption-at-rest-what-it-protects | cloud-security | Craig Leslie | primary keyword: kubernetes secrets encryption at rest
Differentiated from kubernetes-rbac-audit (RBAC verbs) by focusing on storage/encryption threat model; links to it for RBAC.

| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| Secrets unencrypted in etcd by default; Pod creators read namespace Secrets | kubernetes/website secret.md (raw, main) | fetched 2026-10-23 | VERIFIED | upstream |
| base64 not encryption; list implies contents; short-lived Secrets; audit alerting; CSI driver | secrets-good-practices.md | fetched 2026-10-23 | VERIFIED | |
| identity default/no confidentiality; first provider encrypts; ordering; provider table; local vs KMS; kms v1 deprecated 1.28; kms v2 stable 1.29; replace command; k8s:enc prefix; rotation steps | encrypt-data.md | fetched 2026-10-23 | VERIFIED | |
| Example audit policy: secrets/configmaps at Metadata | audit.md | fetched 2026-10-23 | VERIFIED | |
| Leaked etcd copy is ciphertext with local key | editorial inference | | QUALIFIED | labelled in article |
| Config checker | our code, run on 3 sample files with PyYAML 6.0.3 | 2026-10-23 | VERIFIED | illustrative |
Fix during review: rotation step rewritten to match docs (new key added as second entry first). Anchor text to AWS IAM post corrected.

## Images
- atlassian: Unsplash wKfAiJTgyK8 (MIKE STOLL), id 1768119997334-bc76e6f60e7d
- k8s secrets: Unsplash Uf-c4u1usFQ (Tim Evans), id 1462045504115-6c1d931f07d1

## Next-session candidates
1. CVSS v4.0 supplemental metrics and when vendors fill them in
2. Palo Alto PAN-OS CVE-2026-0322 (KEV 2026-10-14) or Cisco Secure Email Gateway CVE-2026-76519: patch and hunt, if vendor advisory reachable
3. Kubernetes service account tokens: bound tokens, TokenRequest and why legacy Secret-based tokens should go

## Publication status
Both pushed to main (commits dda8c47, b7cdc89 covers, cce9403 alt text). Local Hugo build: 0 errors, both pages present, no dead /posts/ links. Live check NOT confirmed: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED (approval not available in unattended run) and shell curl is blocked by the proxy (403). Owner should spot-check both URLs.
