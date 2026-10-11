# Editorial log 2026-10-11

Two new articles published (no articles dated 2026-10-11 were on main at start). Dated 06:00Z and 06:05Z; pushed after 06:08Z.

## Article 1: HTTP security headers beyond CSP (appsec)
Slug: http-security-headers-hsts-nosniff-referrer-policy-and-permissions-policy-explained
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| OWASP recommended values for HSTS, nosniff, Referrer-Policy, Permissions-Policy; set Referrer-Policy explicitly; X-Frame-Options DENY and frame-ancestors; do not set X-XSS-Protection; no Expect-CT / HPKP; remove Server / X-Powered-By | OWASP HTTP Headers Cheat Sheet | Undated page, read 2026-10-11 | VERIFIED | Read via fetch summarizer |
| HSTS: max-age, includeSubDomains, HTTPS-only, first-visit gap, expiry refresh, max-age=0, no click-through, preload token | MDN Strict-Transport-Security | Read 2026-10-11 | VERIFIED | |
| Preload requirements; "cannot easily be undone"; removal slow | hstspreload.org | Undated, read 2026-10-11 | VERIFIED | |
| nosniff behavior (script/style blocking; no sniffing elsewhere) | MDN X-Content-Type-Options | | VERIFIED | |
| Referrer-Policy values; default strict-origin-when-cross-origin (spec revision Nov 2020; previously no-referrer-when-downgrade) | MDN Referrer-Policy | | VERIFIED | |
| Permissions-Policy syntax, effects, "Limited availability" / "Experimental" | MDN Permissions-Policy | | QUALIFIED | Labels may change |
| Rollout order; HSTS staged max-age; no-referrer sends least | Own analysis | | QUALIFIED | Labelled editorial judgment in article |

## Article 2: SBOM Minimum Elements 2026 (appsec)
Slug: sbom-minimum-elements-2026-what-cisa-and-partners-changed-from-the-2021-ntia-baseline
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| 2026 Minimum Elements published 2026-07-29; v1.0 2021-07-12, v2.0 2025-08-22 draft, v2.1 2026-07-29; replaces NTIA 2021; co-authors | CISA PDF (read in full to Appendix B, text extracted) and resource page | 2026-07-29 | VERIFIED | |
| 17 data fields (Appendix A); ten new (Notable Updates list); renamed/major/minor; Access Control removed; SWID removed; Depth -> Coverage; unknown-info; no new requirements; disclaimer | CISA PDF | | VERIFIED | Counts (17, 10) are ours from the document; CISA press release names only four new |
| 90+ comments; four named new elements | CISA announcement | 2026-07-29 | VERIFIED | |
| 2021: seven data fields, 2021-07-12 | NTIA 2021 PDF | | VERIFIED | |
| CycloneDX 1.7 released 2025-10-21; ECMA-424 | cyclonedx.org overview | Read 2026-10-11 | QUALIFIED | Current at read date |
| SPDX 3.0 current; ISO/IEC 5962:2021 | spdx.dev | Page updated 2025-08-05 | QUALIFIED | No version dates on page |
| Practical recommendations | Own analysis | | QUALIFIED | Labelled as suggestions |

## Corrections made during the run
- Referrer-Policy table: split `origin` and `origin-when-cross-origin` rows that were wrongly merged.
- SBOM post: replaced a link to a future-dated post (third-party SaaS checklist, 2026-11-25) with a live post; reworded an unsupported "listed first" SPDX claim; replaced an unsupported inference about the EU CRA with what the document says.
- Third-party summaries (Paubox "ten new fields", 2025-draft counts) were not relied on; the ten was counted from the CISA document itself.

- SBOM hero: first choice (port shipping containers) showed Maersk/ONE/Evergreen/COSCO/MSC brand names; replaced with wooden crates photo (Hemerson Coelho, iqEOJiBs1o8) after viewing. Headers hero alt corrected to include the brass padlock (tiny 'GLOBE' marking on padlock, judged not a recognisable logo).

## Known limitations
- No live-server header tests, no browser tests; no SBOM tool output checked against the 17 fields. Hugo not installed locally, so build not tested before push.
- Whether federal procurement or EU CRA rules now reference the 2026 document was not checked.
- Existing CSP post (2026-10-10) links to the API misconfigurations post, dated 2026-10-13, which is not yet live; link is dead until then. Not changed this run.
- WebFetch summaries (not raw HTML) were the reading route for MDN/OWASP/hstspreload pages.

## Next-session candidates
1. Software signing and provenance: Sigstore, SLSA levels and what build provenance attestations prove (primary: slsa.dev, Sigstore docs).
2. VEX and CSAF: how to publish vulnerability exploitability statements alongside SBOMs (CISA VEX docs, OASIS CSAF).
3. CISA KEV additions this week, or Sentinel/Splunk pricing models for the SIEM follow-up.
