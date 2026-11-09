# Editorial log 2026-11-09

Run: scheduled, 04:53 UTC. GSC quick fixes already done (log 2026-11-02); skipped. DAILY.md news trial active (run 2 of 15).

## Article A: kev-time-to-listing-cve-published-to-dateadded-days-by-vendor (John Marshall, security-operations) [cluster]
Data: KEV 2026.11.06 (1,769) joined to cvelistV5 release cve_2026-11-09_0000Z cveMetadata.datePublished. Scripts: scratch ttl.py/an.py/an2.py/adp.py; reader script kev_lag.py run 2026-11-09 (107 adds since 2026-08-11, median 8, 24 <=0, 53 <=7, 13 >365), matches corpus calc.

| Claim | Primary source | Date | Status | Scope |
| --- | --- | --- | --- | --- |
| 2026 adds n=285 median 14d; <=0 19%, <=7 43%, <=30 59%, >365 18% | kev-data + cvelistV5 | 2026-11-06 / 11-09 | VERIFIED (code) | all 2026 adds |
| Per-year table 2021-2025 | same | same | VERIFIED (code) | |
| 2026 same-year IDs n=197 median 4; 28% / 60% / 82% | same | same | VERIFIED | |
| Vendor table 2025-26 (n>=8) | same | same | VERIFIED | small samples, stated |
| 62 negative gaps, 4 in 2026; CVE-2026-118527 added 10-30, published 11-03; CVE-2026-87886 -1 | same | same | VERIFIED | |
| 210 midnight datePublished timestamps | cvelistV5 | same | VERIFIED | legacy interpretation QUALIFIED |
| 2026 due tiers 151x3d, 87x14d, 44x21d; pub->due median 22d | kev-data | 2026-11-06 | VERIFIED | |
| 51 of 285 >365d; oldest CVE-2008-4128 Cisco 6,507d | same | same | VERIFIED | |
| 1,767/1,769 KEV records carry CISA-ADP kev metric | cvelistV5 | 2026-11-09 | VERIFIED | |
| datePublished definition quote | cve-schema CVE_Record_Format.json | main | VERIFIED | |
| KEV three criteria quotes | cisa.gov/known-exploited-vulnerabilities (WebFetch) | current | VERIFIED | |
| Reasons for vendor differences | editorial | | QUALIFIED (labelled interpretation) | |
Removed before draft: claim that CISA "typically updates" ADP on listing replaced by measured 1,767/1,769.

## Article B: supermarket-freezer-hacks-refrigeration-controllers-cisa-fbi-warning (Craig Leslie, security-operations) [news]
News trial: story = European supermarket refrigeration controller attacks (France Oct 11-12; second wave Nov 2) + Nov 5 US joint warning. Why: mainstream curiosity (food spoiled in hundreds of stores, many countries), concrete OT lesson. Primary source: joint CISA/FBI/HHS/USDA/DoT document (ic3.gov/CSA/2026/261105.pdf); retailer statements via AP/ITV. Window: 4-7 days (stretch rule; nothing fresher with a primary source on therecord.media homepage).

| Claim | Source | Date | Status | Scope |
| --- | --- | --- | --- | --- |
| Joint warning title/date/agencies/quotes/8 mitigations; no vendor/CVE named | IC3 PDF | 2026-11-05 | VERIFIED | |
| France: Sunday night attack, 250-350 stores (French outlets), chains, prosecutor investigation (AFP), Coop U quote | BleepingComputer | 2026-10-12 | QUALIFIED (press) | |
| ~700 victims per Paris prosecutor | The Record | 2026-11-02 | QUALIFIED, attributed | |
| Nov 2 wave countries; Belgium >50 stores; Swedish manager quote; Sabcobel ~20 units; Danfoss/Copeland "mainly discontinued"; CCB quote; NOS Copeland | The Record | 2026-11-02 | QUALIFIED, attributed | |
| Delhaize, Carrefour 15/700+, ICA, Coop six (TT), Selver one | AP via ITV | 2026-11-02 | VERIFIED (company statements) | |
| Germany/Italy/Portugal/Romania, EU meetings | Latin Times | 2026-11-04 | NOT VERIFIED -> placed in "not confirmed" row only | |
| CVE-2025-41450/41451 versions, CVSS, SSVC poc | cvelistV5 records | 2025 | VERIFIED (data) | no link to attacks claimed |
| Neither CVE in KEV | kev-data 2026.11.06 | | VERIFIED | |
| Paris prosecutor date | AFP via BleepingComputer | | QUALIFIED -> "By Oct 12" | |

## Category note
Both posts in security-operations (news trial default; Article A is vuln-management). No better existing category for either.

## Next-session candidates
1. [cluster] Alert when a CVE gains a KEV listing or SSVC Exploitation: active by diffing CISA-ADP containers in the cvelistV5 delta | guide | turns delta sync into an alert; today showed 1,767/1,769 KEV records carry ADP kev metric | deltaLog.json, cisagov/vulnrichment README, CVE record ADP containers | must not repeat cvelistv5-delta, cisa-vulnrichment, cve-adp-containers, kev-time-to-listing (link + hub)
2. [cluster] OpenVEX in OCI attestations: trivy --vex oci, cosign attest --type openvex | guide | VEX that travels with the image | trivy docs/guide/supply-chain/vex (raw at tag), sigstore/cosign docs raw, openvex/spec | must not repeat openvex-products-subcomponents, cosign keyless (link both + hub)
3. [spec] KEV knownRansomwareCampaignUse: how often "Unknown" flips to "Known" and how to track it | guide | field-level, ransomware-driven SLAs | kev-data git history (git log -p on the JSON), CISA KEV page | must not repeat cisa-kev-json-feed (link + hub)
News (Article B, trial): pick fresh 72h story at run time; follow-up possible on freezer attacks if a vendor/CERT publishes the access method.

## Publication status
See end of file.
Pushed in 6f9f553; fetch-covers workflow committed both cover.jpg (7603a9c); covers previewed before commit, imageAlt matches. Rebuild after pull: zero errors, no dead /posts/ links. Live check: WebFetch returned PROVENANCE_REQUIRED (not retried), so live not confirmed by this run; owner spot-check needed.
Covers rejected today: Tissot watch (brand), grocery shelf (brands), CHEN STAR clock (logo), "2025" stencil (misleading), two Unsplash+ photos.
