# Editorial log 2026-10-17

Two new articles published. No post dated 2026-10-17 was on main at start. Posts dated 06:05Z and 06:06Z; pushed 06:10Z (commit 5d8f9a7); cover.jpg added by workflow; hero image for the Kubernetes post replaced (b47dd8f) because the first photo showed a third-party logo on a shirt, and both alt texts rewritten after viewing the images. Live pages, canonical, robots, hero images, internal links all returned 200 / correct.

## Article 1: Kubernetes ValidatingAdmissionPolicy (cloud-security, author John Marshall)
Slug: kubernetes-validatingadmissionpolicy-cel-rules-for-registry-allowlists-and-memory-limits-with-a-warn-first-rollout
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| VAP declarative in-process CEL alternative to webhooks; stable since v1.30; policy + binding required; params; Deny/Warn/Audit; Deny+Warn not combinable; failurePolicy Fail default/Ignore; all matching combinations must pass; has()/in; variables; messageExpression; reasons; matchConditions; type checking limits; exempt kinds | kubernetes.io Validating Admission Policy page | page last modified 2026-09-28; read 2026-10-17 | VERIFIED | v1.37 site |
| ValidatingAdmissionPolicy in default plugin list for 1.37 | Admission controllers reference | read 2026-10-17 | QUALIFIED | Same page's per-plugin text still mentions v1alpha1 prerequisites |
| kubernetes.io/metadata.name set on all namespaces, immutable | Well-known labels page | read 2026-10-17 | VERIFIED | |
| Runtime cost budget, estimated-cost rejection | CEL in Kubernetes page | modified 2026-08-13 | VERIFIED | |
| Example CEL results (registry prefix incl. look-alike host, init containers, memory limits) | Own run, cel-go v0.32.0 (cel.dev/cel-go) with strings ext, dyn types | 2026-10-17 | QUALIFIED | Not the Kubernetes CEL environment; no cluster run; YAML parsed only |
| Ephemeral containers not matched, LimitRange ordering, UPDATE on running pods | Own inference | | QUALIFIED | Stated as untested in article |

## Article 2: CVSS v4.0 vector strings (security-operations, author Craig Leslie)
Slug: how-to-read-a-cvss-v4-0-vector-string-metric-by-metric-with-real-cve-records
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Vector grammar, mandatory Base metrics, order, defaults, metric definitions, nomenclature, Supplemental no score effect, E:X = Attacked, requirements X = High, MacroVector scoring | FIRST CVSS v4.0 Specification Document v1.2 | read 2026-10-17 | VERIFIED | Lookup tables/formulas not reproduced |
| CVE-2026-88771 (pub 2026-09-27, NetScaler CNA, 9.5), CVE-2026-102489 (pub 2026-09-30, DIVD, 8.7 and 9.4 scenarios), CVE-2026-102490, CVE-2026-105207 (pub 2026-10-04, VulnCheck, v4 9.3 / v3.1 9.8, CISA SSVC exploitation none 2026-10-06) | cveawg.mitre.org records | read 2026-10-17 | VERIFIED | CNAs may amend records |
| Recalculated scores (5.1; 6.3; 7.4; 8.1; 8.6; 8.7; 6.9 for swapped order) and library accepting mis-ordered vector | Own run, Red Hat cvss 3.6 | 2026-10-17 | QUALIFIED | One library; matched 4 published scores (9.5, 8.7, 9.4, 9.3); FIRST calculator not run |
| Strictly BT naming for vectors including E:A | Spec nomenclature + record vectors | | QUALIFIED | Our reading |

## Corrections made during the run
- Both posts first used the same hero photo by mistake; Kubernetes post switched to a different photo. First replacement candidate (a drafting photo) showed a "KRA" shirt logo and was dropped; final photo viewed before pushing.
- Alt text was drafted before viewing; both rewritten after viewing (gauges are helicopter cockpit instruments at night, not a plain dial).
- Removed an incorrect phrase "Zammad-style vector" from a takeaway.
- covers.tsv had a blank trailing line from a scripted append; cleaned.

## Known limitations
- No Kubernetes cluster run; manifests untested; cel-go check is not the API server's CEL environment.
- NVD API returned zero results for cvssV4 queries in this environment, so examples use CVE Services records instead.
- Kubernetes: docs ask about LimitRange and ephemeral-container behavior unresolved.
- Hugo not installed locally; verified via live site.

## Next-session candidates
1. NVD CVE API 2.0: parameters, vulnStatus values, rate limits with/without key, avoiding gaps in a local mirror (note: cvssV4 filters returned empty results on 2026-10-17; investigate before writing).
2. Kubernetes MutatingAdmissionPolicy (CEL) vs mutating webhooks: what it can set, and how it orders with validating policies (kubernetes.io docs).
3. CISA SSVC decision tree: the four decision points and how CISA's Vulnrichment values map to Act/Attend/Track* outcomes (CISA SSVC guide) — check overlap with the existing Vulnrichment post first.
