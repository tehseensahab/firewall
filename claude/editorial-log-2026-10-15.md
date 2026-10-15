# Editorial log 2026-10-15

Two new articles published. No post dated 2026-10-15 was on main at start. Posts dated 06:05Z and 06:06Z; pushed 06:08Z (commit 9858e2d); cover.jpg files added by workflow (5c54841). Both URLs returned 200 on firewallsync.com with canonical, og:image (200), hero img with correct alt, and all internal links (200).

## Article 1: CISA KEV JSON feed (security-operations)
Slug: cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| catalogVersion 2026.10.14, dateReleased 2026-10-14T19:27:28Z, count 1745 = array length = unique CVE IDs; 12 fields per entry | KEV JSON feed (curl, parsed in Python -I) | downloaded 2026-10-15 | VERIFIED | Snapshot |
| Field definitions (Known/Unknown, forensicTriage, cwes pattern) | cisagov/kev-data schema (raw) | develop branch, read 2026-10-15 | VERIFIED | |
| Weekday update pattern, sync within minutes, no inline revision history | cisagov/kev-data README | read 2026-10-15 | VERIFIED | cisa.gov page states no update frequency |
| Known 361 / Unknown 1384; forensicTriage Yes 84 / No 1661; empty cwes 175; notes with ';' 963, with >1 'http' 973 | Own tallies of JSON | 2026-10-15 snapshot | QUALIFIED | |
| dueDate-dateAdded gap tables by year; 128 entries since 2026-06-10 (84 Yes/3d, 21 No/3d, 23 No/14d); earliest and latest Yes 2026-06-25 / 2026-10-14; 238 entries at 181 days | Own calculation | snapshot | QUALIFIED | June 10 cut-off is BOD page date; cause of 181-day gap not investigated |
| BOD 26-04 applies to federal civilian agencies | CISA BOD page (read in prior session, cited in 2026-10-12 article) | | VERIFIED | Not re-fetched today |
| Ahsay CVE-2026-105134 added 10-14, due 10-17, triage Yes, notes content | KEV JSON | snapshot | VERIFIED | |
| Script and output | Run by us against a 5-row CSV | 2026-10-15 | VERIFIED | Not run on a real scanner export |
| Production suggestions | Own analysis | | QUALIFIED | Untested |

## Article 2: Pod Security Admission (cloud-security)
Slug: kubernetes-pod-security-admission-namespace-labels-modes-and-a-safe-rollout-from-warn-to-enforce
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Levels, modes, labels, version label, workload-resource behavior, exemptions + caution, exempt field updates, metrics | kubernetes/website pod-security-admission.md (raw) | main branch, read 2026-10-15 | VERIFIED | Docs for v1.37 |
| Baseline/restricted controls, OS-specific controls, alternatives | pod-security-standards.md (raw) | same | VERIFIED | Baseline table read in full; restricted read from the table |
| Example labels, kubectl commands, enforce-label warning, dry run | enforce-standards-namespace-labels.md (raw) + rendered page via WebFetch (v1.37 in manifest) | same | VERIFIED | Commands not run |
| Default privileged / latest, AdmissionConfiguration, flag, beta v1.23, GA v1.25 | enforce-standards-admission-controller.md (raw) | same | VERIFIED | |
| Unlabeled namespaces as gaps, multi-mode, intent to replace PSP | enforcing-pod-security-standards.md (raw) | same | VERIFIED | |
| Validating controller | admission-controllers.md (raw) | same | VERIFIED | |
| Latest docs version v1.37 | kubernetes/website hugo.toml | same | VERIFIED | |
| Existing pods not terminated; Deployment enforce failure shows as missing pods | Inference | | QUALIFIED | Labelled as untested in article |
| Example restricted pod | Own check against control table | | QUALIFIED | No cluster available |

## Corrections made during the run
- Post dates initially set to 06:12Z/06:14Z were later than the system clock (06:08Z); changed to 06:05Z/06:06Z before push so they were not scheduled.
- First padlock candidate (many padlocks) rejected: visible "Master" brand text; replaced with a single combination padlock on a chain-link fence.
- Removed an unsupported sentence claiming the Kubernetes docs say managed offerings behave differently.
- Dropped an alt-text word ("laptop-style") the photo did not support.

## Known limitations
- No cluster, kubectl or Hugo available; manifests untested; verified via live site.
- KEV counts are one snapshot; 181-day due-date gap unexplained.
- BOD 26-04 page not re-fetched today.
- Rendered kubernetes.io pages read via raw markdown from kubernetes/website main (one rendered page checked).

## Next-session candidates
1. CVE Program basics: CNA vs ADP containers, record states, what "rejected" or "disputed" means for triage (cve.org / CVE Record Format).
2. Kubernetes ValidatingAdmissionPolicy (CEL) as a built-in alternative for rules PSA cannot express (kubernetes.io docs).
3. EPSS data feed: columns, daily scoring, percentile vs probability, joining to a scanner export (FIRST EPSS docs).
