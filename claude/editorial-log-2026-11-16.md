# Editorial log 2026-11-16

Run: scheduled, unattended. GSC quick fixes already done (2026-11-02 log), skipped. Hub exists; Article A links it. Pre-scheduled post how-to-secure-mcp-servers-in-production (dated 2026-11-16T09:00Z, committed 2026-11-01) is not a run post; guard not triggered.

## Published
A. cve-exploitation-alerts-cisa-adp-kev-ssvc-cvelistv5-diff | security-operations | John Marshall | [cluster]; links hub, cve-adp-containers, cisa-vulnrichment, cve-record-states, cisa-kev-json-feed, cvelistv5-delta, kev ransomware flips
B. maileva-data-breach-la-poste-22-million-addresses-what-we-know | identity-access | Craig Leslie | [news]; links vetting-third-party-saas, notion-fireworks

News trial: Maileva (La Poste/Docaposte) 22 million names+addresses; chosen as La Poste confirmed to AFP on Nov 14 (within 72h), large count, well-known brand, B2B-SaaS lesson (processor/controller, sending-account security). Primary: La Poste statement to AFP (via Euronews/Yahoo) + Maileva written response (Cyberattaque.org). Franceinfo/Ouest-France robots_disallowed.

## Method (Article A)
Blobless clone of CVEProject/cvelistV5; git diff --name-status cve_2026-10-17_0000Z (985d3ad, 2026-10-16T23:29Z) .. cve_2026-11-16_0000Z (94d1c63, 2026-11-16T00:15Z) = 16,690 A + 14,624 M (2 non-CVE: delta.json, deltaLog.json). Fetched both versions via raw at commit (curl --parallel 64); 585 files came back as 429 bodies, refetched with parallel 8, 0 bad after. Scripts: /home/claude/scripts/adp_diff.py, kev_adp_lag.py (scratch, not in repo); watcher tested on CVE-2026-97229 and CVE-2023-54404 old->new and live delta.json.

## Fact-check (internal)
| Claim | Primary source | Date | Status | Scope |
|---|---|---|---|---|
| "For those CVEs that are on the KEV, the CISA ADP will add a KEV block. For those that aren't, no update will occur." | cisagov/vulnrichment README (develop) | checked 2026-11-16 | VERIFIED | |
| SSVC active = "Shared, observable, reliable evidence that the exploit is being used in the wild by real attackers; there is credible public reporting." | CERTCC/SSVC exploitation.py (main) | 2026-11-16 | VERIFIED | |
| 31,312 changed CVE files: 16,690 added, 14,622 modified | git diff, counted | 2026-11-16 | VERIFIED | |
| Transitions: None->none 2,389; None->poc 282; none->active 14; none->poc 10; poc->none 5; None->active 2; none/poc->None 19 | adp_diff.py | 2026-11-16 | VERIFIED | modified records |
| 19 losses all PUBLISHED->REJECTED; 29 newly rejected; 672 rejected records in changed set, 0 with adp | script | 2026-11-16 | VERIFIED | |
| New records: none 12,071; poc 1,940; active 18; no SSVC 2,661 | script | 2026-11-16 | VERIFIED | |
| 34 active (16 gained + 18 born) all in KEV catalog | script vs kev-data JSON | 2026-11-16 | VERIFIED | window only |
| 33 KEV adds dateAdded 2026-10-17..11-15; 31 with ADP kev (matching date); all 33 active; CVE-2026-48356 and CVE-2026-111497 lack kev block, ADP updated 2026-10-28 | kev_adp_lag.py | 2026-11-16 | VERIFIED | as of snapshot |
| ADP dateUpdated minus KEV dateAdded: 1 day x28, 2 days x2 (PHP 109618/109619), 4 days x1 (Ivanti 118527) | script | 2026-11-16 | QUALIFIED (upper bound) | |
| Watcher output lines | run | 2026-11-16 | VERIFIED | |
| Maileva: La Poste to AFP Nov 14: "vol des coordonnées de 22 millions de personnes", mid-September; "prénom, le nom et l'adresse postale"; bank details "ne sont pas concernées"; CNIL + plainte; "enquête judiciaire est en cours"; 70,000 users, 180M documents 2024 | Euronews via fr.news.yahoo.com | 2026-11-15 | VERIFIED (company statement as reported) | |
| Maileva written response: "22 millions de personnes sont concernées ... prénom, nom, adresse postale"; "Plusieurs milliers d'entreprises clientes"; "L'information des personnes concernées relève des organisations clientes" | cyberattaque.org | 2026-11-13 | VERIFIED (as published) | |
| 39M references -> ~22M from internal docs attributed to Docaposte | cyberattaque.org | 2026-11-13 | QUALIFIED (not confirmed) | |
| Sept 23 07:00 suspension; Sept 29 "de nouveau pleinement opérationnels"; "tentatives d'accès non autorisé par un cyber criminel afin de procéder à l'envoi illégitime de courriers"; accounts blocked; client told no mail sent from its space/API portal; first reported Sept 24 by Cyberattaque.org and FrenchBreaches | solutions-numeriques.com | 2026-09-30 | VERIFIED (as reported) | |
| GDPR 33(2) "The processor shall notify the controller without undue delay after becoming aware of a personal data breach." | gdpr-info.eu | | VERIFIED | |
| Access method; attribution | none | | NOT DISCLOSED (stated as such) | |
Removed: "UK GDPR has the same structure" (no quote gathered).

## Next-session candidates
1. [cluster] SSVC Exploitation poc in CISA-ADP: what moves a CVE to poc and how many reach KEV | guide | today's diff found 292 changed records gaining poc and 1,940 born poc in 30 days; engineers ask whether poc should page | cvelistV5 tag diffs (method above), CERTCC/SSVC exploitation.py, vulnrichment README, kev-data | must not repeat cve-exploitation-alerts (today), cisa-vulnrichment, epss-scores-for-kev-cves
2. [spec] OpenVEX spec v0.2.0 fields tools ignore: status_notes, action_statement_timestamp, last_updated, version | guide | follows vexctl post | raw openvex/spec OPENVEX-SPEC.md, go-vex statement.go, trivy pkg/vex | must not repeat vex-explained, openvex-products-subcomponents, vexctl, cyclonedx-vex
3. [cluster] KEV catalog vs CISA-ADP kev block gaps across the full corpus: which KEV CVEs have no kev block in their CVE record | guide | today found 2 of 33 recent adds missing; corpus-wide count is a data story | kev-data JSON, cvelistV5 midnight zip (release asset URL 404'd today; use git tag diff or raw fetch), vulnrichment README | must not repeat today's article (frame as audit of all ~1,500 KEV CVEs), kev-time-to-listing
News (Article B, trial ends 2026-11-22): fresh 72h story; Maileva follow-up only if access method/CNIL statement appears.
