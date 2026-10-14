# Editorial log 2026-10-14

Two new articles published. One pre-scheduled post dated 2026-10-14 (API rate limiting) was already on main at start, so it did not count as two. New posts dated 06:07Z and 06:08Z; pushed 06:11Z (commit 29c48d2); cover.jpg files added by workflow (afc640f). Both URLs returned 200 on firewallsync.com with canonical, og:image (200) and all internal links (200).

## Article 1: CISA Vulnrichment SSVC values (security-operations)
Slug: cisa-vulnrichment-how-to-read-ssvc-values-in-a-cve-record-and-turn-them-into-a-patch-decision
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| ADP container, three SSVC points, CWE/CVSS follow-on rules, CNA precedence, CPE stopped 2024-12-10, version string meaning | cisagov/vulnrichment README (raw) | read 2026-10-14 | VERIFIED | |
| SSVC/KEV location in CVE JSON; jq command and outputs for CVE-2024-4947, -25522, -34974, CVE-2021-44228, CVE-2026-76504, -88771 | CVE Services API, run live | 2026-10-14 | VERIFIED | Values and timestamps are snapshots |
| Exploitation 1.1.0, Automatable 2.0.0, Technical Impact 1.0.0 definitions | certcc.github.io/SSVC (WebFetch) | | VERIFIED | |
| Four outcomes + five decision points + timing | cisa.gov SSVC page (WebFetch) | | VERIFIED | Branch logic not on page |
| 36-row decision table, Mission and Well-being definitions | CERTCC/SSVC CISA-Coordinator.json (curl, parsed in Python) | main branch, read 2026-10-14 | QUALIFIED | Table computed by us; 36 unique combinations confirmed; SSVC Guide PDF not read |
| Why Mission and Well-being is not in public records | Own reasoning | | QUALIFIED | Labelled as inference |
| CVE-2024-25522 CISA CVSS 9.4 vs poc | CVE API ADP container | | VERIFIED | |

## Article 2: policy-controller admission (cloud-security)
Slug: verify-signed-container-images-in-kubernetes-sigstore-policy-controller-keyless-policy-and-rollout
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Controller behavior, opt-in label, AND/OR logic, no-match-policy, CIP fields, warn mode, digest resolution | docs.sigstore.dev policy-controller overview (WebFetch) | read 2026-10-14 | VERIFIED | Project says under active development |
| Helm install steps; no minimum k8s version; failure behavior not described | docs.sigstore.dev installation | | VERIFIED | |
| Releases v0.15.1 latest, v0.15.0 cosign v2 to v3 and no-match logging | GitHub releases page (WebFetch) | | QUALIFIED | Page shows day/month only; no dates published; API access blocked by session scope |
| Chart 0.10.8 / appVersion 0.13.1; failurePolicy Fail; replicaCount 1 | sigstore/helm-charts main (raw) | | QUALIFIED | Which webhook consumes failurePolicy not checked |
| failurePolicy semantics, default Fail, timeout 1-30 s | kubernetes/website markdown (raw) | | VERIFIED | |
| GitHub OIDC issuer | GitHub Docs OIDC reference | | VERIFIED | |
| Signer identity format | docs.sigstore.dev quickstart-ci | | VERIFIED | Shown for verify-blob; same flags for images per page |
| Docs example subjectRegExp does not match typical path as a regex | Own Python re test | | QUALIFIED | Not run in policy-controller; anchoring behavior unverified; article says so |
| Example policy and rollout | Own analysis | | QUALIFIED | Untested manifest, labelled |

## Corrections made during the run
- Two internal links initially pointed to posts dated in November 2026 (GitHub Actions security, GitHub Actions OIDC); removed before publishing.
- Example regex in the ClusterImagePolicy changed to use [^/]+ for the repo segment so the stated Python test matches the published expression.
- Log4Shell KEV column corrected from "Not checked" to the verified 2021-12-10.
- Hero alt texts corrected after viewing: compass photo's second object is a silver map-measuring instrument (not brass); gate photo includes a Chinese-character sign and wall monitor.

## Known limitations
- policy-controller not installed or run; manifests untested.
- CISA SSVC Guide PDF not read; decision table relies on CERT/CC JSON file on main.
- Direct curl to unsplash.com pages returns 307; photo ids taken via WebFetch of the photo pages.
- GitHub API for sigstore repos not reachable from this session, so release dates were not obtained.
- Hugo not installed locally; verified via the live site.

## Next-session candidates
1. Reading the CISA KEV catalog JSON feed programmatically (fields, dueDate, knownRansomwareCampaignUse) and joining it to a scanner export.
2. Kubernetes Pod Security Standards / Pod Security Admission levels and namespace labels (primary: kubernetes.io docs).
3. CVE Program basics: CNA vs ADP containers, record states and what "rejected" or "disputed" means for triage (primary: cve.org / CVE Record Format).
