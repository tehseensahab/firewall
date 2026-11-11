# Editorial log 2026-11-11

Run: scheduled. GSC quick fixes already done (2026-11-02), skipped. DAILY.md news trial active (run 4 of 15).
Guard: content/posts/ai-agent-security-... is dated 2026-11-11T09:00Z but is a pre-scheduled post committed 2026-10-28, not a run output; run continued.

## Topic selection
- Candidates from 2026-11-10 log: (1) CISA-ADP diff alerting — dropped today: overlaps cvelistv5-delta and kev flips posts too closely without new data; kept for later. (2) KEV notes/cwes — dropped: the KEV JSON feed post already covers notes splitting and empty cwes (cannibalization). (3) OpenVEX in OCI attestations — chosen: openvex-products-subcomponents post explicitly says it did not cover `--vex oci`.
- News: Chainalysis breach (Nov 6, 5 days old, primary blog only via THN) considered; N-able N-central Able2Shell (Nov 8-10) chosen: fresher, primary CVE records from N-able CNA, MSP/engineer relevance, prior N-central KEV history.

News trial: N-able N-central Able2Shell zero-days / hosted outage | why: widely used RMM, real outage, public exploits, MSP downstream risk | primary: N-able CVE records in cvelistV5 (7 records, published 2026-11-10); N-able status page via TechCrunch quote (direct fetch needed approval, skipped).

## Fact-check: Article A — Trivy --vex oci (John Marshall, cloud-security)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Feature EXPERIMENTAL; 3 layouts; referrer precedence then .att | trivy v0.76.2 docs/guide/supply-chain/vex/oci.md ("The referrer layout takes precedence; Trivy falls back to the legacy `.att` tag") | tag v0.76.2 | VERIFIED | Trivy v0.76.2 |
| "Trivy does not verify the signature of the discovered VEX attestation" | same doc, warning box (verbatim) | v0.76.2 | VERIFIED | |
| Tag in product ID not supported | same doc ("Using an image tag ... is not supported in the product ID at the moment") | v0.76.2 | VERIFIED | |
| Annotation filter semantics | same doc note + pkg/vex/oci/oci.go vexCandidates | v0.76.2 | VERIFIED | |
| First OpenVEX match wins, registry order | oci.go retrieveReferrerVEX ("Decode each candidate and return the first OpenVEX document") and legacy loop | v0.76.2 | VERIFIED | source reading |
| Caps 100 attestations, 20 MiB | oci.go maxAttestations = 100; maxAttestationSize = 20 << 20 | v0.76.2 | VERIFIED | |
| Artifact type strings | pkg/oci/artifact.go constants | v0.76.2 | VERIFIED | |
| Referrer discovery first in v0.73.0 (PRs #10932 2026-07-21, #10986 2026-07-29) | git log + `git tag --contains` | 2026-07 | VERIFIED | |
| Multiple --vex, order = priority; local file | docs vex/index.md | v0.76.2 | VERIFIED | |
| cosign --type openvex -> https://openvex.dev/ns | cosign v3.1.4 options/predicate.go + attestation.go OpenVexNamespace | v3.1.4 | VERIFIED | |
| --new-bundle-format default true, "attach a Sigstore bundle using OCI referrers API" | cosign v3.1.4 options/attest.go | v3.1.4 | VERIFIED | |
| v3 defaults on bundles + OCI 1.1 referring artifact | cosign CHANGELOG v3.0.0 (verbatim) | | VERIFIED | |
| verify-attestation flags --type, --certificate-identity, --certificate-oidc-issuer | doc/cosign_verify-attestation.md v3.1.4 | | VERIFIED | |
| Output: JSON with base64 payload | Sigstore docs example `jq -r .payload | base64 -d` | | QUALIFIED | not tested on v3.1.4; stated in post |
| oci purl version = digest | purl-spec types/oci-definition.json | main | VERIFIED | |
| Example VEX doc valid | ran jsonschema 4.26.0 vs openvex_json_schema.json: "schema ok" | run today | VERIFIED | |
| extract script works | ran on synthetic SBOM+VEX envelopes: output status not_affected | run today | VERIFIED | synthetic only, stated |
Removed: none. Note: trivy.dev docs URLs not verified, so links point to GitHub v0.76.2 blobs.

## Fact-check: Article B — N-able N-central Able2Shell (Craig Leslie, security-operations, [news])
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Exploits published on GitHub Sunday (Nov 8) | TechCrunch ("released the bugs on GitHub on Sunday") | 2026-11-10 | VERIFIED (secondary, established outlet) | |
| Hosted offline; status page wording "while we take the necessary actions..." | TechCrunch quoting N-able status page | 2026-11-10 | VERIFIED | status page direct fetch blocked (approval) |
| "no evidence of successful exploitation against any of its customer environments" | TechCrunch quoting N-able | 2026-11-10 | VERIFIED | |
| No active exploitation as of Nov 9 15:15 UTC; keep servers offline | Huntress blog (quoting N-able) | 2026-11-09 | VERIFIED | |
| 33 vulns, 4 chains (3 RCE, 1 root), build 2026.4.0.31 | Huntress; Cybersecurity News | 2026-11-09/10 | QUALIFIED | researcher's count, attributed |
| Hotfix 2026.4 HF2; agents/probes must upgrade; N-able hasn't confirmed how many reproduced | CSO Online | 2026-11-10 | QUALIFIED | trade press, attributed |
| watchTowr honeypot exploitation attempts; Defused probing | Cybersecurity News | 2026-11-10 | QUALIFIED | attributed |
| Researcher's motive | TechCrunch citing BleepingComputer | 2026-11-10 | QUALIFIED | his account, attributed |
| 7 CVEs, titles, CWEs, CVSS v4, PR values, lessThan 26.4.1 / 2026.4.1 | cvelistV5 raw records (N-able CNA, published 2026-11-10) | 2026-11-10 | VERIFIED | computed with python |
| Prior N-central KEV entries (5) and none of the 7 in KEV | kev-data JSON catalogVersion 2026.11.10 | 2026-11-10 | VERIFIED | |
Removed/not used: researcher's name (sources disagree on first name; not needed). Hosted restoration status: NOT VERIFIED -> stated as unknown.

## QC
- hugo v0.139.4 --minify: 565 pages, no errors; both posts in /tmp/pub/posts; dead internal link check: 0 dead.
- Titles 51/51 chars; descriptions 158/154.
- Internal links A: openvex-products-subcomponents, vex-explained, cosign keyless, prioritization workflow hub (3 cluster incl. hub). B: cve-affected-versions-lessthan, KEV JSON feed, hub.

## Skipped
- uptime.n-able.com/event/202580/ WebFetch: PROVENANCE_REQUIRED (approval), not retried.
- github.com HTML pages return 403 to curl via proxy (raw works).

## Next-session candidates
1. [cluster] Alert when a CVE gains KEV or SSVC Exploitation: active by diffing CISA-ADP containers in cvelistV5 delta | guide | turns delta sync into alerts | cvelistV5 deltaLog.json, cisagov/vulnrichment, CVE record ADP containers | must not repeat cvelistv5-delta, cisa-vulnrichment, cve-adp-containers, kev flips (link + hub)
2. [spec] vexctl: create, merge and attest OpenVEX documents (merge semantics, product IDs, timestamps) | guide | the tooling gap left by today's Trivy --vex oci post (Trivy can't create VEX) | raw openvex/vexctl README + pkg source at latest tag, openvex/spec, trivy v0.76.2 vex docs | must not repeat trivy-vex-oci, openvex-products-subcomponents, vex-explained (link + hub)
3. [cluster] CVSS v4 vectors in CNA records: reading AT, PR, UI and the scenarios field as published by CNAs (e.g. N-able's 7 records) | guide | engineers parse CNA metrics, not NVD | CVEProject/cve-schema CVE_Record_Format.json cvssV4_0, FIRST CVSS v4 spec via WebSearch, cvelistV5 records | must not repeat cvss-vs-epss-vs-kev (link + hub)
News (Article B, trial): fresh 72h story at run time; N-able follow-up only if KEV adds any of the 7 CVEs or N-able confirms customer compromise (then add dated Update line to today's post).

## Hero images
- A: CHUTTERSNAP aerial container terminal (Q4bmoSPJM18). Small carrier names on container roofs are visible but tiny; tried a replacement (fBZOVyF-96w) and rejected it (large crane logo). Owner may swap.
- B: İsmail Enes Ayhan, equipment-cabinet aisle (lVZjvw-u9V8). No logos.
- imageAlt rewritten from the actual covers.
