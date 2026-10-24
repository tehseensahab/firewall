# Editorial log 2026-10-24

GSC: gsc-wizard connector returned payment_required (trial ended / no subscription). Topics chosen from KEV feed and prior candidates.

## Article 1: collabora-code-cve-2026-110447-nextcloud-patch-and-hunt (Craig Leslie, security-operations)

| Claim | Primary source | Source date / effective date | Status | Scope |
|---|---|---|---|---|
| richdocumentscode before 26.4.303; OS command injection in proxy.php when CODE server not running; exploited Sept/Oct 2026; distinct from CVE-2025-66208; standalone not affected | CVE record (cvelistV5 raw) | published 2026-10-14, updated 2026-10-24 | VERIFIED | CNA mitre |
| CWE-78; CVSS 4.0 9.2 vector AT:P | CVE record | 2026-10-14 | VERIFIED | |
| SSVC active / automatable yes / total | CVE record CISA-ADP | 2026-10-23 | VERIFIED | |
| KEV added 2026-10-23, due 2026-10-26, forensicTriage Yes, ransomware Unknown | KEV JSON 2026.10.23 | 2026-10-23 | VERIFIED | |
| Fix commit 6cc8dae authored 2026-08-20, committed 2026-09-09; tag 26.4.303 2026-09-11; 26.4.502 2026-10-23; min Nextcloud 30 | richdocumentscode git clone | as dated | VERIFIED | |
| HTTP_HOST and REQUEST_URI escapeshellarg'd then embedded in double-quoted bash -c; 26.4.303 wraps inner cmd in escapeshellarg; master uses proc_open array + "$@" | git diff 26.4.302..26.4.303, master proxy.php | | VERIFIED (source); root-cause reading editorial. Shell behaviour demo run locally with harmless echo (not published) | |
| proxy.php 26.4.302 has no require/include of Nextcloud; ?status calls startCoolwsd when not running | git show 26.4.302:proxy.php | | VERIFIED | |
| Disabling insufficient; Docker/package/AIO not affected; attacks from Sept 10; Oct 3 forum warning; Collabora blames CVE backlog | BleepingComputer (WebFetch) | 2026-10-15 | QUALIFIED (secondary) | |
| IOCs shx*.php, shrf4645.php, $( %24%28 ${IFS} %2e%2e, webhook.site, sudo attempts | eSecurityPlanet, WZ-IT summarizing issue #354 | Oct 2026 | QUALIFIED (secondary) | |
| occ integrity:check-app reports EXTRA_FILE | WZ-IT | | QUALIFIED | |
| Exfiltration/root not confirmed | eSecurityPlanet | | QUALIFIED | |
| find/zgrep commands match sample files | local test (GNU find/grep) | 2026-10-24 | VERIFIED | |

Not reachable: GHSA-g3vx-3m76-fghh, GitHub issue #354 (api.github.com requires add_repo; skipped to avoid approval), Nextcloud forum post (not in search results).

## Article 2: kubernetes-service-account-tokens-bound-vs-legacy-secrets (John Marshall, identity-access)

| Claim | Primary source | Source date / effective date | Status | Scope |
|---|---|---|---|---|
| Secret tokens don't expire/rotate; no auto-gen since 1.24; manual allowed | k8s website service-accounts.md (main, v1.37) | 2026-10-24 fetch | VERIFIED | upstream |
| Bound object types; cleaner 24h, conditions, labels, 1y periods, flag; invalid token behaviour; no central record; recreate SA | service-accounts-admin.md | | VERIFIED | |
| kubectl create token --duration; claims example; reload every 5 min | configure-service-account.md | | VERIFIED | |
| exp-iat 31,536,000 s; warnafter-iat 3,607 s | computed with python from docs example | | VERIFIED | |
| expirationSeconds default 1h, min 600; subPath no updates | projected-volumes.md | | VERIFIED | |
| Feature gate versions (BoundSATokenVolume 1.22 GA; NoAutoGeneration beta 1.24 GA 1.26; Tracking GA 1.28; CleanUp beta 1.29 GA 1.30; NodeBinding GA 1.33) | feature-gates/*.md in website repo | | VERIFIED | |
| WarnOnly 3607 s; ExpirationExtension 1y; ExtendExpiration default true; help text quote; stale-token annotation + metric; legacy-token-* annotations; last-used label on all secret tokens; API warning for auto tokens; metric names | kubernetes/kubernetes master claims.go, legacy.go, metrics.go, options/authentication.go | main branch | VERIFIED (main; released versions may differ) | |
| TokenReview recommended over OIDC | service-accounts.md | | VERIFIED | |
| Inventory script | run locally Python 3.13 on fixture JSON | 2026-10-24 | VERIFIED | |
| Removed: "recreating SA invalidates legacy tokens too" (not explicitly sourced) | | | REMOVED | |

## Next-session candidates
1. Palo Alto PAN-OS CVE-2026-0322 (KEV 2026-10-14): management-interface RCE, fixed releases, exposure checks
2. Arista VeloCloud Orchestrator CVE-2026-114625 (KEV 2026-10-23): fixed releases 5.2.3.18 / 6.1.3.10 / 6.4.2.12 per CVE record; check advisory reachability
3. Kubernetes audit policy for security teams: which events and levels capture token, RBAC and Secret access

## Publication status
Pushed to main: 191901d (posts), 3a2ee83 (covers, by workflow), 02a6e18 (alt text + log). Local Hugo build: 0 errors, both pages present, no dead /posts/ links. Live check NOT confirmed: WebFetch of firewallsync.com returned PROVENANCE_REQUIRED (not retried) and shell curl is blocked by the proxy (403). Owner should spot-check both URLs.
