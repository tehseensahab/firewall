# Editorial log 2026-10-18

Two new articles prepared. No post dated 2026-10-18 was on main at start. NVD developer pages (nvd.nist.gov/developers/*) returned 403 from this environment, so the planned NVD CVE API 2.0 article was not written; Kubernetes MutatingAdmissionPolicy and the SSVC deployer model were chosen instead (both primary sources accessible).

## Article 1: Kubernetes MutatingAdmissionPolicy (cloud-security, author John Marshall)
Slug: kubernetes-mutatingadmissionpolicy-cel-mutations-apply-configuration-or-json-patch-and-when-a-webhook-is-still-needed
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| MAP declarative in-process CEL alternative to webhooks; stable v1.36, enabled by default, first available v1.30; three resources; policy+binding required; mutations non-empty; apply config rules; escapeKey; root-accessible fields; exempt kinds incl. v1.37 webhook exclusion | kubernetes.io Mutating Admission Policy page | last modified 2026-09-28; read 2026-10-18 | VERIFIED | v1.37 site |
| matchConditions semantics (max 64), failurePolicy, reinvocationPolicy required, CREATE/UPDATE/CONNECT only | MutatingAdmissionPolicy API reference v1 | modified 2026-08-26 | VERIFIED | |
| Binding has only policyName, paramRef, matchResources; missing policy ignored; per-param evaluation; cost budget | MutatingAdmissionPolicyBinding API reference | modified 2026-08-26 | VERIFIED | |
| Two-phase admission; PodSecurity validating; any failing MAP fails request | Admission Controllers reference | modified 2026-09-28 | VERIFIED | |
| MAP in 1.37 default plugin list | Admission Controllers reference | | QUALIFIED | Per-plugin text still says feature gate + v1alpha1 |
| Webhook reinvocation, idempotency, default Never | Dynamic Admission Control | read 2026-10-18 | VERIFIED | |
| Docs' two sidecar examples differ (image string, args) though text says "same mutation" | MAP page | | VERIFIED | Our comparison |
| JSON Patch add/test/escape behaviors | Own run, Python jsonpatch 1.35 | 2026-10-18 | QUALIFIED | RFC 6902 library, not the API server |
| Rollout suggestions; IfNeeded implies idempotent mutation | Own analysis | | QUALIFIED | Untested; no cluster |

## Article 2: SSVC deployer model (security-operations, author Craig Leslie)
Slug: ssvc-deployer-patch-priority-model-explained-exploitation-exposure-automatable-and-human-impact
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Deployer unit of work, four inputs, four outcomes and descriptions, mitigation notes | certcc.github.io/SSVC/howto/deployer_tree/ | no date on page; read 2026-10-18 | VERIFIED | |
| 72-row table (ssvc:DT_DP:1.0.0); counts 7/42/20/3; each combo once; monotonic; Active never Defer; Immediate only Active+Open | Same page; own extraction and checks | 2026-10-18 | QUALIFIED | Counts and checks ours; table is an "example" per CERT/CC |
| Input definitions and versions (E 1.1.0, EXP 1.0.1, A 2.0.0, HI 2.0.2, SI 2.0.1, MI 2.0.0) | CERT/CC reference pages | read 2026-10-18 | VERIFIED | |
| Human Impact 16-cell table vs prose definitions disagree in four cells (Marginal/Degraded, Marginal/Crippled, Marginal/MEF Failure, Critical/Degraded) and prose omits Critical/MEF Failure | CERT/CC Human Impact page | read 2026-10-18 | QUALIFIED | Our comparison; choice of table is our judgment |
| Vulnrichment values/KEV dates for CVE-2026-88771, -102489, -105207, -76504, -104286, -88779 | cveawg.mitre.org records | read 2026-10-18 | QUALIFIED | Live records change |
| Worked-example lookups | Own lookup in extracted table | | QUALIFIED | Assumes product present |

## Corrections made during the run
- First hero photo for article 2 (sticky-note board) showed the third-party brand name "ClickUp" handwritten on a note; replaced before pushing. Alt text for both written after viewing the images.
- Draft takeaway said "None produces Out-of-cycle only when..." (unclear); reworded. FAQ on Defer reworded so reassessment is labelled as our reading. "Controlled network" corrected to "Controlled exposure".
- covers.tsv already contains two pre-existing duplicate photo ids (1594915440248-1e419eba6611, 1698668975271-2ba9a323be6b) from earlier posts; not touched.

## Known limitations
- No Kubernetes cluster run; no MAP manifest tested. Behavior of failed JSON Patch and ordering of multiple MAPs not found in the docs read.
- CERT/CC pages undated; Human Impact prose/table inconsistency may be corrected upstream.
- NVD developer docs inaccessible (403) from this environment.
- Hugo not installed locally; verified via live site.

## Next-session candidates
1. NVD CVE API 2.0: parameters, vulnStatus values, rate limits with/without API key, avoiding gaps in a local mirror (needs NVD docs access; retry, or use another path to nvd.nist.gov).
2. SSVC Supplier/Coordination triage models or the CERT/CC "CISA BOD 26-04 Response Model" page (check overlap with the BOD 26-04 and Vulnrichment posts first).
3. Kubernetes admission: manifest-based admission control (ManifestBasedAdmissionControlConfig) — what it can intercept that REST-created policies cannot (kubernetes.io docs).
