# Editorial log 2026-11-13

Guard: content/posts/mcp-security-what-developers-need-to-secure-before-connecting-ai-to-tools is dated 2026-11-13T09:00Z but is a pre-scheduled post added 2026-10-30 (not a prior run today); proceeded.
GSC quick fixes: already done 2026-11-02 (commit ad84082); skipped.
DAILY.md hacking-news trial active (run 6 of 15).

## Articles
A. cve-json-cvss-metrics-cvssv4-0-cvssv3-1-basescore-trap | security-operations | John Marshall | cluster/spec, links hub + vector, vulnrichment, KEV, EPSS, ADP posts
B. notion-ai-chats-exposed-fireworks-ai-breach-what-we-know | ai-security | Craig Leslie | [news]

News trial: Notion AI chat transcripts exposed via Fireworks AI breach | well-known brand, AI vendor retention lesson engineers can act on | primary: Notion help-center notice + Fireworks bulletins (Oct 6 and Nov 9 update).

Topic selection: candidate 3 from 2026-11-12 (CVSS v4 in CNA records) taken and narrowed to the metrics array + baseScore B/BT finding. Candidates 1 and 2 carried forward. News: Maersk and N-able already covered; eMudhra CA key mishandling considered (not an attack); Xen Orchestra/Outlook/Chrome are CVE posts, not incidents.

## Fact-check A (data snapshot cvelistV5 cve_2026-11-13_0000Z, PUBLISHED + datePublished 2026)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| metrics optional in cnaPublishedContainer (required: providerMetadata, descriptions, affected, references) | CVE_Record_Format.json definitions.cnaPublishedContainer.required | main, read 2026-11-13 | VERIFIED | schema |
| anyOf cvssV4_0/V3_1/V3_0/V2_0/other; minItems 1; scenarios GENERAL default quote; other {type, content} quote | CVE_Record_Format.json definitions.metrics | same | VERIFIED | schema |
| v4.0 required version, vectorString, baseScore, baseSeverity; no threat/env score fields | imports/cvss/cvss-v4.0.json properties list | same | VERIFIED | schema |
| 96,879 records; combos table; 30,352 v4 (31.3%); 64,347 v3.1 (66.4%); 20,408 no CNA CVSS (21.1%) | scratchpad metrics.py over release zip | 2026-11-13 | VERIFIED (computed) | 2026 published |
| 15,148 CISA-ADP v3.1 fill; 5,260 none; 4 CISA-ADP v4.0; ssvc 90,133, kev 215 other entries | same | same | VERIFIED (computed) | |
| format=CVSS in 55,806 CNA entries; Red Hat severity rating 1,476; 3,543 non-GENERAL scenario entries | same | same | VERIFIED (computed) | |
| v4 CNA concentration VulnCheck 10,176, VulDB 6,370, GitHub_M 4,287 = 68.6% | same | same | VERIFIED (computed) | |
| E set 6,954; base-only 5,816; BT 1,067; equal 68; neither 3; VulDB 5,790 base; GitHub 432, palo_alto 120, qnap 106, NETGEAR 48 BT | v4bt.py, cvss lib 3.6 | same | VERIFIED (computed) | one library |
| exploitMaturity field counts NOT_DEFINED 10,620 / absent 19,051 / UNREPORTED 482 / POC 210 / ATTACKED 41 | metrics.py | same | VERIFIED (computed) | |
| CNA vs CISA-ADP v3.1: 468 both, 58 differ (31 higher, 27 lower) | metrics.py | same | VERIFIED (computed) | |
| Example vectors/scores CVE-2026-82598, -41129, -41225, -41080, -1995, -86471 and script output | raw cvelistV5 records + pick_cvss.py run | 2026-11-13 | VERIFIED | |
| CVSS-B/BT/BE/BTE nomenclature | FIRST spec via 2026-10-17 post | 2026-10-17 | QUALIFIED (not re-read; FIRST pages not returned by WebSearch today) | |
| "VulDB four-version row" | qualified to count match + one record opened | | QUALIFIED | |

## Fact-check B
| Claim | Primary source | Date | Status |
|---|---|---|---|
| <1% workspaces; chat transcripts; Insights/inference/LEAP uses; not-affected items; ZDR scope quote; actions as of Nov 3; owner CSV steps; rotate creds | notion.com/help/security-incident-involving-a-third-party-ai-vendor | undated, read 2026-11-13 | VERIFIED |
| Oct 6 internal credentials; eval-job env vars; "Removing a stored secret alone..." | fireworks.ai/security/bulletins/october-2026-security-incident | Oct 2026 | VERIFIED |
| Oct 23 provider incident; Oct 24 workload, same-day detection; billing/datasets/incomplete weights/secrets; ZDR products quote; LLMJacking group; Unit 42, law enforcement, controls | fireworks.ai/.../october-2026-security-incident-update | last updated 2026-11-09 | VERIFIED |
| Fireworks told Notion Nov 2; no customer count | SecurityWeek 2026-11-12 | | QUALIFIED (press) |
| Nov 8 new dataset; Fireworks policy-page quote | VentureBeat 2026-11-11 | | QUALIFIED (press) |
| Removed: "Notion dropped Fireworks after second breach" framing (headline wording from outlets), Wiz InvokeModel observation, CSA advice | VentureBeat | | REMOVED (secondary, not needed) |

## Publication status
- Pushed 0e23bce (posts, covers.tsv, INDEX); fetch-covers workflow committed both cover.jpg (7e2bd56). Hugo v0.139.4 build clean; both posts in /tmp/pub/posts; dead internal links: 0.
- Live check: WebFetch firewallsync.com -> PROVENANCE_REQUIRED (not retried). Status: pushed; live not confirmed.
- imageAlt written from preview of the same Unsplash photos (images.unsplash.com) before commit.

## Next-session candidates
1. [cluster] Alert when a CVE gains KEV or SSVC Exploitation: active by diffing CISA-ADP containers in cvelistV5 delta | guide | turns delta sync into exploitation alerts | cvelistV5 delta.json/deltaLog.json, cisagov/vulnrichment, CVE record ADP containers | must not repeat cvelistv5-delta, cisa-vulnrichment, cve-adp-containers, kev flips
2. [cluster] CVSS v4.0 Supplemental metrics in CVE records: who sets Automatable, Recovery, providerUrgency and how to use them | guide | v4 records now carry S/AU/R/V/RE/U; engineers want to know if they are usable signals | release zip corpus (same scripts as today: scratch metrics.py approach), cve-schema imports/cvss/cvss-v4.0.json, FIRST v4.0 spec via WebSearch | must not repeat today's cve-json-cvss-metrics post, how-to-read-a-cvss-v4-0-vector-string
3. [spec] OpenVEX spec v0.2.0 fields that tools ignore: status_notes, action_statement_timestamp, last_updated and statement version | guide | follows vexctl post | raw openvex/spec OPENVEX-SPEC.md, go-vex statement.go, trivy pkg/vex | must not repeat vex-explained, openvex-products-subcomponents, vexctl, cyclonedx-vex
News (Article B, trial): fresh 72h story at run time; Notion/Fireworks follow-up only if either names the storage feature, provider or adds a dated update.
