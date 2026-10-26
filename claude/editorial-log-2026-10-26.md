# Editorial log 2026-10-26

GSC not used (not available to these runs). Topics from the 2026-10-25 candidates (#1 PAN-OS, #3 k8s audit detections), checked against INDEX.md. Source check: CVE-2026-0322 record (cvelistV5 raw) and KEV raw both reachable; Ivanti CVE-2026-104935 record reachable but thin (no CVSS detail beyond v3.1, no title) and older (KEV 10-13); held for later.

## Article 1: PAN-OS CVE-2026-0322: Patch the Management Interface RCE
Slug: pan-os-cve-2026-0322-management-interface-rce-patch-and-hunt | security-operations | John Marshall | primary keyword: pan-os cve-2026-0322

| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| "authenticated attacker with network access to execute arbitrary code with root privileges on the firewall"; PA-Series, VM-Series, Panorama (virtual and M-Series); Cloud NGFW, Prisma Access not impacted | CVE-2026-0322 record, cvelistV5 raw (descriptions, affected) | published 2026-10-14, updated 2026-10-15 | VERIFIED | |
| Solutions table (20 rows, 12.2 to 10.2) | same record, solutions | 2026-10-14 | VERIFIED; script cross-checked: 20 in-line fixes == 20 `changes.at` values; LESS_THAN == record lessThan | |
| 12.1 affected range starts 12.1.0, solutions table starts 12.1.2 | same record | | VERIFIED (observation) | |
| "No known workarounds"; Threat IDs 510046/510047, content 9159-10287, conditions (DP port, replace cert, decrypt, threat prevention) | same record, workarounds | | VERIFIED | |
| "No special configuration is required to be affected" | same record, configurations | | VERIFIED | |
| "Very limited exploitation has been observed..." | same record, exploits | | VERIFIED | |
| CWE-94; CVSS 4.0 8.6 (AV:N) and 8.5 (AV:A) with PR:H, E:A, AU:N, U:Red; scenario texts | same record, metrics | | VERIFIED | |
| Internal discovery; reporter credited; initial publication 2026-10-14T16:00Z | same record, source/credits/timeline | | VERIFIED | |
| KEV added 10-14, due 10-17, ransomware Unknown, forensicTriage Yes, BOD 26-04 in requiredAction | kev-data raw v2026.10.23 | 2026-10-14 | VERIFIED | |
| SSVC active/no/total | CISA ADP in record | 2026-10-14 | VERIFIED | |
| 16 Palo Alto Networks KEV entries; CVE-2024-0012 + CVE-2024-9474 both 2024-11-18, names as stated; CVE-2026-0300 (05-06, Captive Portal, unauth BOF), CVE-2026-0257 (05-29, GlobalProtect bypass, ransomware Known) | kev-data raw (counted with python); CVE records 0300/0257 | | VERIFIED | |
| Three IPs 66.42.72.14, 208.83.239.114, 149.248.47.234 | BleepingComputer 2026-10-14 ("shared" by company); THN 2026-10-15 ("assessed to be linked") | | QUALIFIED (press; advisory page not fetched) | |
| IDC analyst Yih Khai Wong on "weak management-access hygiene" | CSO Online 2026-10-15 | | VERIFIED (attributed) | |
| Mgmt access guidance quotes; Device > Setup > Interfaces > Management | PAN-OS 9.1 admin guide (WebFetch) | | VERIFIED; 9.1 guide noted in post | |
| Empty Permitted IP list = access from any IP | docs.paloaltonetworks.com ngfw configure-the-management-interface-settings (SCM page, 11.1+) | | VERIFIED | SCM path, principle same |
| `show system info`, `show admins all`, `show log system/config` | not run | | labelled illustrative | |
| Checker sample output | own run, python3 | 2026-10-26 | VERIFIED | |
| Exploitation actors/timeline/post-exploitation | none | | NOT VERIFIED -> stated as not disclosed | |

## Article 2: Kubernetes Audit Log Detections: 8 Rules We Tested
Slug: kubernetes-audit-log-detections-8-rules-tested | cloud-security | Craig Leslie | primary keyword: kubernetes audit log detection

| Claim | Primary source | Source date | Status | Scope |
|---|---|---|---|---|
| ResponseStarted "only generated for long-running requests (e.g. watch)" | kubernetes/website audit.md raw | fetched 2026-10-26 | VERIFIED | |
| impersonatedUser field | kubernetes/apiserver audit/v1 types.go | master | VERIFIED | |
| PSS Baseline: host namespaces, privileged, hostPath disallowed | pod-security-standards.md raw | fetched 2026-10-26 | VERIFIED (corrected: hostPath is Baseline, not Restricted) | |
| Kubelet requests tokens on behalf of Pods | configure-service-account.md raw | | VERIFIED | |
| --anonymous-auth default true (system:anonymous / system:unauthenticated); --allow-privileged default false | kube-apiserver v1.34.1 --help | | VERIFIED | |
| ATT&CK T1609, T1610, T1611, T1098.006, T1552.007, T1528, T1613 names; collection 20.0 | attack-stix-data raw | | VERIFIED; mapping is editorial (stated) | |
| 574 events, 532 system:apiserver, alice 18 / ci-deployer 15 / dev-bob 8 / anonymous 1; 15 hits; per-rule table | own run (envtest kube-apiserver v1.34.1, etcd 3.6.4, jq 1.7), snapshot snap.log | 2026-10-26 | VERIFIED; published script diffed identical to tested script | single apiserver, no nodes/controllers |
| exec get+create, two stages each; dedupe via ResponseComplete; same auditID across stages | own run | | VERIFIED | |
| Privileged pod rejected 422 "disallowed by cluster policy", logged at Request with hostPath / | own run | | VERIFIED | |
| kubectl debug = patch pods/ephemeralcontainers, Request level, image busybox:1.36 | own run | | VERIFIED | |
| Bootstrap cluster-admin binding by system:apiserver fires D3 without exclusion | own run (first pass) | | VERIFIED | |
| Direct use of SA token would log as system:serviceaccount:... and be dropped by blanket system: filter | reasoning from field semantics | | QUALIFIED (worded as "had the attacker...") | not tested |
| Some distributions run controllers under kube-system SAs | general | | QUALIFIED ("some") | |
| Managed providers wrap events / control policy | general | | QUALIFIED ("may") | |

Process notes: restarting kube-apiserver with --allow-privileged=true was denied by the auto-mode classifier; the rejected privileged create became a finding instead.

## Next-session candidates
1. Ivanti Connect Secure CVE-2026-104935: auth bypass by spoofing, fixed in 25.1.3.0 | timely (KEV 2026-10-13) | admins search "is my ICS affected / fixed version" | CVE record cvelistV5 cves/2026/104xxx/CVE-2026-104935.json (affected: 25.1.3.0, 25.1.3.1, 22.8R2.5 unaffected; 22.7R2.14 and prior not impacted); KEV raw; Ivanti hub advisory (WebSearch first) | must not repeat: zero-trust-vs-vpn post (2026-11 scheduled, not live), citrix/netscaler patch-and-hunt posts
2. Siemens Software Center CVE-2026-110936 | timely (KEV 2026-10-20, due 2026-11-03) | OT/engineering IT teams patching | cvelistV5 record (check path 2026/110xxx), KEV raw, Siemens ProductCERT advisory via WebSearch | must not repeat: none
3. Management-plane hardening for network appliances: a checklist for firewalls, VPNs and SD-WAN orchestrators | guide (fundamentals or identity-access) | follows a run of edge-device KEVs | PAN-OS admin guide (securing administrative access), KEV raw (count edge/management CVEs), CVE records for 0322/114625/0012 | must not repeat: pan-os-cve-2026-0322..., velocloud-orchestrator..., the-2026-security-hardening-checklist (scheduled)

## Publication status
(filled after push)
