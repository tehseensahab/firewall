# Editorial log 2026-11-15

Guard: content/posts/mcp-authentication-and-authorization-what-a-secure-deployment-should-check is dated 2026-11-15T09:00Z but is a pre-scheduled post added 2026-11-01 (commit c71f984), not a prior run today; proceeded.
GSC quick fixes: already done 2026-11-02; skipped.
DAILY.md hacking-news trial active (run 8 of 15).
Hub (vulnerability-prioritization-workflow-cve-record-to-patch-ticket) exists; Article A links it.

## Articles
A. cve-problemtypes-cweid-cwe-from-cve-json | appsec | Craig Leslie | [cluster/spec]; links hub, cve-adp-containers, cvelistv5-delta, cve-json-cvss-metrics, cisa-vulnrichment SSVC
B. screenconnect-sckit-worm-rmm-plus-extension-what-we-know | security-operations | John Marshall | [news]; links n-able-n-central post, cisa-kev-json-feed

News trial: ScreenConnect SCKit worm via RMM+ extension | Huntress post Nov 11 (updated Nov 13), within 72h for the second wave; ScreenConnect is widely deployed by MSPs, ~400 partner environments exposed; extension-auth lesson for engineers | primary: Huntress (research firm, own telemetry) + ConnectWise statements via CyberScoop and The Register (two independent outlets); CVE/KEV record for CVE-2026-84869 from cvelistV5 and kev-data.
Candidates considered: Chainstack production breach (The Hacker News, not researched; possible tomorrow), Vanderbilt (already covered), Microsoft 365 outage (Microsoft says not malicious; excluded).

## Fact-check A (corpus = cvelistV5 release cve_2026-11-15_0000Z, state PUBLISHED, grouped by datePublished year; scripts cwe.py / p2.py / inline passes in /tmp/work)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| problemTypes items require descriptions; description requires lang+description; cweId optional, pattern ^CWE-[1-9][0-9]*$, 5-9 chars; type free string 1-128; descriptions quoted | cve-schema main schema/CVE_Record_Format.json (default dataVersion 5.2.0) | repo commit 2025-10-29 | VERIFIED | |
| cnaPublishedContainer required = providerMetadata, descriptions, affected, references (problemTypes not required) | same | | VERIFIED | |
| Rule 5.1.7 "MUST identify the type of Vulnerability"; "SHOULD use the Common Weakness Enumeration (CWE)"; effective May 14, 2025 | cve.org CNA_Rules_v4.1.0.pdf (WebFetch) | 2025-05-14 | VERIFIED | |
| 2024: 39,924 pub; 25,623 cweId; 9,054 text; 5,247 none; 5,366 none anywhere. 2025: 48,150; 34,764; 6,982; 6,404; 5,626. 2026: 97,709; 74,189; 13,044; 10,476; 7,870 | cwe.py | snapshot | VERIFIED (computed; buckets sum to total) | |
| type counts CWE 198,469 / text 183,625 / missing 19,161 / Impact 2,778 / cwe 1,586 | cwe.py | snapshot | VERIFIED | all years, description objects |
| multi: 157,531 single / 19,947 two+ of 177,478 (88.8% / 11.2%) | cwe.py | snapshot | VERIFIED | all years |
| CNA patterns 2026: Linux 8,262/8,262 no problemTypes; mozilla 968/968; oracle 4,154/4,154 text; mitre 3,027 of 3,773 text, all 'n/a'; WPScan 2,312 of 2,314; apple 1,196/1,196; Chrome 705/3,972 | p2.py + mitre pass | snapshot | VERIFIED | |
| 3,063 records CWE in CNA text only; 2,559 type CWE/cwe descriptions with no cweId, 2,359 WPScan; ADP same 2,544 / diff 47 / none 472 | inline pass | snapshot | VERIFIED | 2026 |
| CISA-ADP cweId 16,066; fills gap 15,650; both 416; differ 101; redhat-SADP 1,124 vs CISA-ADP 44,152 all years | cwe.py | snapshot | VERIFIED | |
| ADP gap-fill top: 284 3,334; 200 975; 79 829; 269 717; 416 696; 284 gap-fills by oracle 2,624 | p2.py + inline | snapshot | VERIFIED | 2026 |
| CVE-2026-82126 WPScan text CWE-284 type CWE no cweId; CVE-2026-82997 oracle text + CISA-ADP CWE-284; CVE-2026-74687 Linux none; CVE-2024-3477 WPScan text CWE-352 + ADP; CVE-2024-2905 cna CWE-732 | raw cvelistV5 records + parser run (Python 3.13) | 2026-11-15 | VERIFIED | |
| Vulnrichment quotes ("some higher-risk CVEs will also receive enrichment...", "do not already have these fields populated...", "At no point will CISA overwrite...", drop on update, CNA "should take precedence") | raw cisagov/vulnrichment develop README.md | 2026-11-15 | VERIFIED | |
| CWE-284 Usage DISCOURAGED, "should not be used to map to real-world vulnerabilities", "extremely high-level, a Pillar", "not useful for trend analysis"; CWE 5.0 | cwe.mitre.org/data/definitions/284 (WebFetch) | CWE 5.0, 2026-10-28 | VERIFIED | |
| Top 25 2025: 39,080 records, Jun 1 2024-Jun 1 2025, "added by CISA Vulnrichment after publication", ~9,468 (24%) flagged | cwe.mitre.org top25 2025_methodology (WebFetch) | 2025 | VERIFIED | |
Removed before draft: CWE Top 25 2025 rank list (page did not expose ranks).

## Fact-check B
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| 288 hosts / 48 orgs Nov 11, ~90 min, 1/3 first 10 min; 205 hosts / 41 orgs Nov 13 ("This latest wave of activity has impacted 205 hosts across 41 organizations.") | huntress.com/blog/sckit-worm-rogue-screenconnect | 2026-11-11, upd 11-13 | VERIFIED | Huntress telemetry |
| Timeline 17:47 first seen; 22:45 ConnectWise advisory; 16:12 Nov 13 | same | | VERIFIED | |
| Five extensions disabled "across 400 partner environments as a precaution" | same; CyberScoop; The Register | 2026-11-12 | VERIFIED | |
| ~400 = has extensions, not confirmed compromise | The Register | 2026-11-12 | QUALIFIED (as reported) | |
| RMM+ 1.0.31/1.0.32 accept blank key; "seems to be related"; link suggestive | Huntress; The Register quote "installations without a configured access key will accept a blank one." | | QUALIFIED (attributed) | |
| ConnectWise "found no evidence of a compromise of ConnectWise infrastructure or a vulnerability in ScreenConnect itself"; "not yet identified an initial access vector and full scope of the attack" | CyberScoop; Huntress | | VERIFIED | |
| SCKit ~16 files, UUID-keyed; RelayTrap; TrapWatch SYSTEM task; Defender exclusions, AppLocker/SRP; portproxy, hosts, cookie stealer (.aspxauth); spread reconstructed not observed | Huntress | | VERIFIED (Huntress analysis) | |
| No attribution; "Addmin" participant name | Huntress, CyberScoop | | VERIFIED | |
| CVE-2026-84869 description, 9.9, "All versions prior to 26.6.5", published 2026-09-08 | raw cvelistV5 CVE-2026-84869.json | 2026-11-15 | VERIFIED | |
| KEV dateAdded 2026-09-11 | raw kev-data JSON | 2026-11-15 | VERIFIED | |
| Isolation does not remove persistence; reinfection | Huntress (paraphrased; verbatim quote not obtainable) | | QUALIFIED → paraphrased in post | |

## Live check
(see below)

## Next-session candidates
1. [cluster] Alert when a CVE gains KEV or SSVC Exploitation: active by diffing CISA-ADP containers in cvelistV5 delta | guide | turns delta sync into exploitation alerts | cvelistV5 delta.json/deltaLog.json, cisagov/vulnrichment README (ADP drops values when CNA adds them, confirmed today), kev-data git history | must not repeat cvelistv5-delta, cisa-vulnrichment, cve-adp-containers, kev flips
2. [spec] OpenVEX spec v0.2.0 fields tools ignore: status_notes, action_statement_timestamp, last_updated, version | guide | follows vexctl post | raw openvex/spec OPENVEX-SPEC.md, go-vex statement.go, trivy pkg/vex | must not repeat vex-explained, openvex-products-subcomponents, vexctl, cyclonedx-vex
3. [cluster] CVE affected[] versions and defaultStatus: why version-range matching fails (lessThan vs lessThanOrEqual, versionType, free-text "All versions prior to X") | guide | engineers match CVE JSON to SBOM/inventory and hit free-text versions (e.g. CVE-2026-84869) | cve-schema CVE_Record_Format.json versions/changes, cvelistV5 release zip corpus pass, purl-spec | must not repeat cve-problemtypes-cweid, cve-json-cvss-metrics, cve-record-states, openvex-products-subcomponents
News (Article B, trial): fresh 72h story at run time; Chainstack production breach (The Hacker News, Nov 2026) is a fallback if still within 7 days and primary statement found; SCKit follow-up only if ConnectWise names the vector or the extension developer responds.
