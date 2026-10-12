# Editorial log 2026-10-12

Two new articles published (no articles dated 2026-10-12 were on main at start apart from the pre-scheduled API checklist post dated 09:00Z). Dated 06:10Z and 06:15Z; pushed 06:21Z.

## Article 1: SLSA Build levels and provenance attestations (appsec)
Slug: slsa-build-levels-and-provenance-attestations-what-they-prove-and-what-they-dont
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Build L0-L3 definitions and quoted phrases | slsa.dev v1.2 build-track-basics | Read 2026-10-12 | VERIFIED | |
| L3 isolation/unforgeability MUSTs | slsa.dev v1.2 build-requirements | | VERIFIED | |
| v1.2 adds Source track, threat model update | slsa.dev v1.2 whats-new | No date on page | QUALIFIED | Source track requirements not read |
| Predicate type; L1 required fields | slsa.dev v1.1 provenance | Retired page | QUALIFIED | v1.2 pages mention no format change |
| Sigstore keyless flow | docs.sigstore.dev overview | | VERIFIED | Cert lifetime not stated |
| GitHub attestations = SLSA v1.0 Build L2; L3 via reusable workflows; public vs private Sigstore | GitHub Docs | | QUALIFIED | v1.0 reference; plan requirements not stated |
| gh attestation verify flags; JSON predicate caveat | cli.github.com manual | | VERIFIED | |
| "Does not prove" list, adoption order | Own analysis | | QUALIFIED | Labelled as our conclusions |

## Article 2: CISA BOD 26-04 (security-operations)
Slug: cisa-bod-26-04-explained-kev-deadlines-forensic-triage-and-what-private-teams-can-borrow
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Page dated 2026-06-10; revokes BOD 22-01 and 19-02; scope; phases 0/60/180 days; four decision points; definitions | CISA BOD 26-04 page (WebFetch summary; direct curl blocked 403) | 2026-06-10 | QUALIFIED | No separate issuance date; Table 1 is an image |
| 3 days + forensic triage where table says so | Same | | VERIFIED | |
| Tiers 3/3/14/60/fix-on-upgrade | Tenable blog | | QUALIFIED | Secondary; flagged in article |
| Triage steps/timings | CISA implementation guidance | | VERIFIED | Best practice, not required timings |
| Five CVEs added 2026-10-08, due 2026-10-11 | CISA KEV catalog page + NVD API (cisaExploitAdd/cisaActionDue) | NVD modified 2026-10-09 | VERIFIED | Scores may change |
| CVE descriptions, dates, CVSS v3.1 | NVD API | | VERIFIED | Strapi 4.9 NVD / 7.2 CISA-ADP |
| Phase II 2026-08-09, Phase III 2026-12-07 | Own arithmetic from 2026-06-10 | | QUALIFIED | Stated as approximate |

## Corrections made during the run
- Hero alt texts corrected after viewing images: SLSA photo shows three bronze wax seals with a tree design on cream envelopes (not one gray seal); hourglass is wooden with blue sand, tilted on pebbles.

## Known limitations
- BOD Table 1 day counts for non-triage rows not verified; direct CISA fetches returned 403 so the WebFetch summarizer was used.
- No hands-on signing/verification; SLSA Source track, GitHub plan requirements, Sigstore cert lifetime, GitHub-to-SLSA-v1.2 mapping not checked.
- Exploitation details behind the five KEV additions not found.
- Hugo not installed locally; verified via live site.

## Next-session candidates
1. VEX and CSAF: publishing exploitability statements alongside SBOMs (CISA VEX docs, OASIS CSAF).
2. BOD 26-04 Table 1 walk-through once the appendix text can be read directly, or CISA Vulnrichment (Automatable / Technical Impact) explained.
3. Reproducible builds and artifact verification in container registries (Sigstore cosign for images).
