# Editorial log 2026-11-14

Guard: content/posts/mcp-tool-poisoning-how-malicious-instructions-can-hide-inside-trusted-tools is dated 2026-11-14T09:00Z but is a pre-scheduled post added 2026-10-31 (commit a67cd5b), not a prior run today; proceeded.
GSC quick fixes: already done 2026-11-02; skipped.
DAILY.md hacking-news trial active (run 7 of 15).
Housekeeping: a stray nested clone (firewall/firewall, untracked) created by this run's setup was deleted before commit; nothing from it was pushed.

## Articles
A. cvss-v4-supplemental-metrics-in-cve-records-automatable-provider-urgency | security-operations | John Marshall | cluster/spec; links hub, CVSS v4 vector, Vulnrichment SSVC, KEV feed, CVSS-vs-EPSS-vs-KEV
B. uber-driver-license-data-stolen-fireworks-ai-breach-what-we-know | ai-security | Craig Leslie | [news]; follow-up to Notion/Fireworks post (substantial new development: new victim, state AG filings)

News trial: Uber driver license data stolen via AI vendor Fireworks AI | Uber is a household brand, story broke Nov 13 (within 72h), credential-at-vendor lesson for engineers | confirmation: two independent outlets (Reuters via finwire.io syndication quoting Uber's CA AG notice; TechCrunch quoting Uber and state filings). CA AG filing not retrieved directly.

## Fact-check A (corpus = cvelistV5 release cve_2026-11-14_0000Z, PUBLISHED records, CNA containers, scripts in session scratch: supp.py/supp2.py/supp3.py)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Supplemental group optional; "No metric will have any impact on the final calculated CVSS score (e.g. CVSS-BTE)." | first.org/cvss/v4.0/specification-document (WebFetch) | v4.0 spec | VERIFIED | all |
| Vector values S[X,N,P] AU[X,N,Y] R[X,A,U,I] V[X,D,C] RE[X,L,M,H] U[X,Clear,Green,Amber,Red]; "treat unspecified ... Supplemental as Not Defined" | same, Table 23 | v4.0 | VERIFIED | |
| Metric definitions quoted (AU "all 4 steps of the kill chain", V Diffuse/Concentrated, RE Low/High, U "pass-through", Clear/Red text) | same | v4.0 | VERIFIED | |
| JSON names Safety/Automatable/Recovery capitalised, valueDensity/vulnerabilityResponseEffort/providerUrgency camelCase; enums; default NOT_DEFINED | raw cve-schema main schema/imports/cvss/cvss-v4.0.json | 2026-11-14 | VERIFIED | |
| 46,973 records / 47,055 CNA v4 entries; 1,609 records (3.43%) / 1,661 entries with any Supplemental; 257 all six; 326 CNAs v4, 149 with Supplemental | supp3.py, supp2.py | snapshot 2026-11-14 | VERIFIED (computed) | CNA only |
| Per-metric counts AU 1,210 (Y 732/N 478); U 1,152 (Amber 617, Green 212, Red 208, Clear 115); RE 1,123 (M 726, L 330, H 67); R 1,067 (U 679, A 345, I 43); V 891 (D 448, C 443); S 475 (N 314, P 161) | supp.py value pairs, summed JSON-or-vector; ADP had 0 supplemental so totals = CNA | snapshot | VERIFIED (computed; sums checked) | |
| Juniper 258/426, Palo Alto 258/263, VulDB 0/14,115, VulnCheck 2/11,610, GitHub_M 31/5,841, icscert 0/947 | supp3.py | snapshot | VERIFIED | |
| 61 CNA entries vector vs JSON presence mismatch; GitHub_M 22, NLnet Labs 14, Vaadin 7; no case with two different defined values | supp2.py + supp.py value pairs | snapshot | VERIFIED | the one ('NOT_DEFINED','N') pair counts as one-side-missing |
| CVE-2026-110803 JSON all six, vector none; CVE-2026-41292 vector U:Red, no JSON | records via raw cvelistV5 + parser run | 2026-11-14 | VERIFIED | |
| CVE ID years among 1,661 entries: 2026 880, 2025 456, 2024 301 | supp.py | snapshot | VERIFIED | |
| ADP cvssV4_0 entries: 5, all CISA-ADP, none with Supplemental | supp2/supp3 | snapshot | VERIFIED | |
| CVE-2024-0012 CNA AU:N R:U V:C RE:H U:Red (two scenario entries 9.3/5.9); CISA-ADP SSVC 2024-11-18 active/yes/total; KEV dateAdded 2024-11-18 | raw cvelistV5 record; kev-data | 2026-11-14 | VERIFIED | |
| 117 KEV CVEs with CNA v4, 24 with Supplemental | supp3.py + kev-data | 2026-11-14 | VERIFIED | |
| SSVC Automatable question and yes definition | raw CERTCC/SSVC src/ssvc/decision_points/ssvc/automatable.py | 2026-11-14 | VERIFIED | |
| Parser output shown | ran supp_extract.py with Python 3.13 on 3 records | 2026-11-14 | VERIFIED | |
Removed/rewritten: "CNA AU is not updated by exploitation evidence" -> "nothing in the schema ties it to..."; no claim about why Palo Alto chose AU:N.

## Fact-check B
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| Notice: "unauthorized party used compromised credentials at a service provider to access its data"; notice dated Nov 10; Oct 9 told; Oct 13 determined; severed connections; Cyberscout; "had not identified any misuse"; RI 1,873; DC/MD/NC/NY/PA instructions; filing didn't name provider or list data | Reuters via finwire.io (WebFetch) | 2026-11-13 | QUALIFIED (press report of filing) | |
| Uber statement "a security incident impacting one of our third-party vendors, Fireworks.ai"; driver's license + personal info; MA 2,567, SC 3,430, RI 1,873; IL pending, CA no number; expected to rise; no group claimed | TechCrunch, Zack Whittaker (WebFetch) | 2026-11-13 | QUALIFIED (press) | speaker attributed to "Uber" (TechCrunch wording ambiguous between notice and spokesperson) |
| 7,870 combined | arithmetic | | VERIFIED | three states only |
| Fireworks Oct 6 / Oct 23-24 incidents, LLMJacking, secrets in eval jobs | Fireworks bulletins, verified in 2026-11-13 run | 2026-11-09 update | VERIFIED (prior run) | |
| Link between Uber and the Oct 6 path | none | | NOT VERIFIED -> stated as unconfirmed | |
Not used: FourWeekMBA "7,870" headline (secondary aggregator), The Hill (fetch client_error), CA AG filing (only seen inside a fetched page; not searched separately in time).

## Live check
WebFetch firewallsync.com/posts/cvss-v4-...?v=57422ad -> PROVENANCE_REQUIRED (not retried). Status: pushed; live not confirmed. Hugo build OK (619 pages), both posts present, no dead /posts/ links. Covers committed by workflow (fcd61c8); alts checked against cover.jpg, unchanged.

## Next-session candidates
1. [cluster] Alert when a CVE gains KEV or SSVC Exploitation: active by diffing CISA-ADP containers in cvelistV5 delta | guide | turns delta sync into exploitation alerts | cvelistV5 delta.json/deltaLog.json, cisagov/vulnrichment, CVE record ADP containers, kev-data git history | must not repeat cvelistv5-delta, cisa-vulnrichment, cve-adp-containers, kev flips
2. [cluster] CVE problemTypes CWE fields: how often CNAs set cweId, when CISA-ADP fills it, and mapping to the CWE Top 25 | guide | engineers build CWE dashboards from CVE JSON and hit missing/text-only entries | cve-schema CVE_Record_Format.json (problemTypes), cvelistV5 release zip (reuse supp.py streaming approach), CWE Top 25 page via WebSearch, cisagov/vulnrichment | must not repeat cve-adp-containers, cve-json-cvss-metrics
3. [spec] OpenVEX spec v0.2.0 fields tools ignore: status_notes, action_statement_timestamp, last_updated, version | guide | follows vexctl post | raw openvex/spec OPENVEX-SPEC.md, go-vex statement.go, trivy pkg/vex | must not repeat vex-explained, openvex-products-subcomponents, vexctl, cyclonedx-vex
News (Article B, trial): fresh 72h story at run time; Uber/Fireworks follow-up only if Uber gives a total, Fireworks names the path, or the CA AG filing adds data types.
