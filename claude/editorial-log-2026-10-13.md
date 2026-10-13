# Editorial log 2026-10-13

Two new articles published. Only one pre-scheduled post dated 2026-10-13 (API misconfigurations, 09:00Z) was on main at start. New posts dated 06:05Z and 06:06Z; pushed 06:10Z (commit b6bd2ec); cover.jpg files added by workflow (c2a4a22). Both URLs return 200 on firewallsync.com.

## Article 1: VEX explained (appsec)
Slug: vex-explained-what-a-not-affected-statement-means-and-how-to-read-one
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| VEX must contain metadata, product details, vulnerability details, status; four statuses; five not-affected justifications with definitions/examples; assertions may be accepted or not | CISA VEX Status Justifications PDF (read via pdftotext) | June 2022 | VERIFIED | Not exhaustive per CISA; later revisions not checked |
| CISA Minimum Requirements for VEX page dated 2023-04-21 | CISA resource page (WebFetch) | 2023-04-21 | QUALIFIED | PDF returned Access Denied; OpenVEX spec cited for "meets minimum requirements" |
| OpenVEX required fields, justification/impact_statement rule, action_statement, author signature, version increment | OpenVEX spec (raw markdown) | Spec titled v0.2.0, last dated revision 2023-07-18 | VERIFIED | Version labels inconsistent in spec |
| CSAF 2.0 OASIS Standard 2022-11-18; errata 2024-01-26 | OASIS CSAF 2.0 errata page | | VERIFIED | |
| CSAF Profile 5, product_status categories, flag labels | CSAF 2.0 os html (curl, parsed) | | VERIFIED | |
| Trivy --vex options; experimental | trivy.dev VEX docs | read 2026-10-13 | QUALIFIED | Not tested; formats supported not checked |
| Status mapping table, reading checklist | Own analysis | | QUALIFIED | Labelled as ours |

## Article 2: Cosign container image signing (appsec)
Slug: cosign-container-image-signing-keyless-signing-in-ci-and-why-verification-must-pin-an-identity
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Keyless signing definition, Fulcio, Rekor, --identity-token audience | docs.sigstore.dev signing overview | | VERIFIED | |
| cosign sign / --key; OCI 1.1 referrers; cosign tree | docs.sigstore.dev signing containers | | VERIFIED | Page does not discuss tags/digests or v2 vs v3 |
| id-token: write; sign tag@digest; cosign-release pinning; installer v4.1.0 | cosign-installer README (raw) | | VERIFIED | Example versions change |
| id-token: write required; GitHub issuer URL | GitHub Docs OIDC reference | | VERIFIED | Certificate-identity format for Actions NOT verified; article says so |
| --certificate-identity / -regexp, --certificate-oidc-issuer / -regexp required for keyless | cosign doc/cosign_verify.md (main) | | QUALIFIED | main branch docs |
| GHSA-fx35-mq7g-6g98: 2026-08-06, High 7.4, no CVE, versions, mechanism, OCI verify not affected, workaround | GitHub advisory | 2026-08-06 | VERIFIED | Score as published; not re-computed |
| v3.1.3 and v2.6.5 release 06 Aug 2026; bundle-format default note | cosign releases page | | QUALIFIED | Page shows month/day only; year inferred |
| Digest rationale, regexp advice, inspect-certificate procedure, checklist | Own analysis | | QUALIFIED | Labelled as ours |

## Corrections made during the run
- First hero choice for VEX (magnifying glass on an "Insurance Policy" and dollar bills, 1637763723578) rejected after viewing: off-topic. Replaced with Mediamodifier desk photo.
- VEX table header changed to "Status (CISA name)" since meanings come from OpenVEX, not CISA.

## Known limitations
- Direct curl to CISA, GitHub and Unsplash returns 403/bot challenge; link QA of external URLs relied on earlier WebFetch/curl reads, not live status codes. Internal links all 200.
- CISA Minimum Requirements PDF not read. CycloneDX VEX not reviewed. No hands-on cosign or scanner testing.
- Hero alt for VEX omits the ruler and mesh card holder visible in the photo (minor).
- Hugo not installed locally; verified via live site.

## Next-session candidates
1. CISA Vulnrichment (SSVC "Automatable" / "Technical Impact") and how it differs from KEV/EPSS.
2. Verifying signed container images at deploy time: Kubernetes admission policy with Sigstore policy-controller or similar (needs primary docs).
3. BOD 26-04 Table 1 walk-through once the appendix text is readable, or this week's KEV additions.
