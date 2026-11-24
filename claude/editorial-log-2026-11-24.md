# Editorial log 2026-11-24

Guard: no run-authored post dated today; the 2026-11-24T09:00Z post oauth-app-risk-... is pre-scheduled (2026-11-07), so the run proceeded. GSC quick fixes already done (11-02 log). Hub exists; both articles link it. News trial ended 11-22 (noted 11-23).

## Topic selection
- Dropped at overlap check: SSVC SelectionList 2.0.0 (log candidate 2): csaf-2-1-metrics-epss-ssvc-cvss-v4-per-product already covers schema, mapping table and validation gap.
- Deferred: SSVC poc->active lag before KEV (candidate 1): data-heavy, kept for a later run.
- A [spec/cluster]: BOD 26-04 decision table as SSVC JSON (found in CERTCC/SSVC registry while checking candidate 2). Distinct from the BOD 26-04 explainer (which only had Tenable's secondary tier summary) and from kev-duedate (catalog side).
- B [timely]: Cisco Expressway CVE-2026-76466, KEV added 2026-11-20, forensicTriage Yes. 2nd timely CVE post this week (vCenter 11-23). Other KEV adds considered: SAP NetWeaver CVE-2025-42884, Check Point CVE-2026-123039, Outlook CVE-2026-124194.

## Fact-check: Article A (bod-26-04-decision-table-ssvc-json-lookup)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| cisa:DT_BOD2604 1.0.0, inputs cisa:KEV/PE 1.0.0, ssvc:A 2.0.0, ssvc:TI 1.0.0, outcome cisa:BOD2604 1.0.0 | CERTCC/SSVC data/json/decision_tables/cisa/cisa_bod_26_04_1_0_0.json + registry | commit bf3213b 2026-10-22 | VERIFIED (parsed) | |
| 16 rows, each combo once; 3DF 3, 3D 2, 14D 6, 60D 3, FSU 2 | same, python Counter | 2026-11-24 | VERIFIED | |
| Outcome and PE definitions quoted | registry values | | VERIFIED | |
| Commit "Add CISA BOD 26-04 decision framework..." 2026-06-10; follow-ups 06-11 | git log | | VERIFIED | |
| "Readers should consult the directive..."; "InKEV, Automatable, and Technical Impact address the vulnerability whereas Publicly Exposed questions the state of the asset." | docs/howto/cisa_response.md | | VERIFIED | |
| SSVC version 2.0.3 = SSVC 2.0 + CISA Coordinator tree v3; "observe the version" | cisagov/vulnrichment README | | VERIFIED | |
| DT_CO 2.0.3 uses ssvc:E:1.1.0, A:2.0.0, TI:1.0.0 | registry | | VERIFIED | |
| Script output for CVE-2026-76466 and CVE-2026-40217 | run 2026-11-24, KEV 2026.11.23 | | VERIFIED | |
| 175 post-2026-06-10 KEV entries; 134 match PE=Y, 109 PE=N, 161 either, 14 neither; all 175 ADP SSVC v2.0.3 | kev-data + cvelistV5 main | 2026-11-24 | VERIFIED (computed) | current ADP values, not historical |
| Row-by-row match with CISA's directive Table 1 | cisa.gov | | NOT VERIFIED -> stated in Limits | curl to cisa.gov denied by classifier; web-fetch of certcc page denied |

## Fact-check: Article B (cisco-expressway-cve-2026-76466-kev-root-rce-fixed-release)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| CNA description (quoted), CVSS 3.1 9.8 vector, CWE-798, CSCww27732, datePublished 2026-10-21 | cvelistV5 CVE-2026-76466 (dateUpdated 2026-11-23) | | VERIFIED | |
| 94 affected version strings X8.1-X15.5.3, defaultStatus unknown, "X15.2.4." | same, parsed | | VERIFIED | |
| Fixed: X15.5.3 and earlier -> X15.5.20; X14 and earlier migrate; no workarounds; Oct 2026 hardening release | Cisco advisory, ja_jp PDF | v1.1 2026-11-23 | VERIFIED (version strings); QUALIFIED wording | English page not retrieved |
| Affects clustered Expressway-C/E, virtual and appliance | same | | QUALIFIED (translation) | |
| Rev 1.1 adds KEV; "no direct evidence of active exploitation" | same | | QUALIFIED (translation) | |
| KEV dateAdded 11-20, dueDate 11-23, forensicTriage Yes, ransomware Unknown, shortDescription quote | kev-data 2026.11.23 | | VERIFIED | |
| ADP SSVC active/yes/total | CVE record | | VERIFIED | |
| Hunting steps (logs, peer lists, rebuild) | editorial suggestion | | labelled as ours | |
| Reporter name | omitted | | n/a | |

## Hero images
- A: Unsplash 46G4xEr122c (Beatriz Cattel), previewed; alt written from the image.
- B: none. Unsplash search via web-fetch for a second query was denied (classifier, URL not from search results); theme placeholder.

## Skipped / approvals
- web-fetch agent on certcc.github.io/SSVC/howto/cisa_response/ denied ("Undermining Oversight"); used repo source docs/howto/cisa_response.md instead.
- shell curl to cisa.gov BOD 26-04 pages denied ("Unauthorized Access").
- Cisco English advisory (sec.cloudapps.cisco.com) not in search results; used ja_jp PDF.

## Next-session candidates
1. [cluster] SSVC Exploitation poc->active lag before KEV, from cisagov/vulnrichment git history | guide | how early SSVC "active" precedes KEV | cisagov/vulnrichment git log, kev-data history, cvelistV5 | must not repeat public-poc-cves-..., kev-time-to-listing-..., kev-duedate-...
2. [spec] SSVC object registry: find any decision point or table by namespace:key:version (ssvc_object_registry.json structure, 6 namespaces) | guide | tooling authors validating SSVC data from CSAF/CVE | CERTCC/SSVC data/json/ssvc_object_registry.json, data/schema/v2/SsvcObjectRegistry_2_0_0.schema.json | must not repeat csaf-2-1-metrics-..., bod-26-04-decision-table-ssvc-json-lookup
3. [timely] SAP NetWeaver CVE-2025-42884 JNDI injection (KEV 2026-11-20) only if SAP note text is reachable; else skip | timely | SAP admins | KEV entry, cvelistV5 2025/42xxx, SAP security notes bulletin 2025 | no SAP post exists yet; check weekly timely cap
