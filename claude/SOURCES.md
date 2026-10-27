# Source playbook

One line per source: domain, page or data path | works / fails (how) | workaround | date checked

## Works from the shell (curl)
- raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json | works | KEV catalog incl. forensicTriage, notes, cwes | 2026-10-26
- raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/<year>/<Nxxx>/CVE-*.json | works | full CNA record (affected, solutions, workarounds, exploits) + CISA ADP SSVC/KEV | 2026-10-26
- raw.githubusercontent.com/kubernetes/website/main/content/en/docs/... | works | k8s docs source (audit.md, pod-security-standards.md, configure-service-account.md) | 2026-10-26
- raw.githubusercontent.com/kubernetes/apiserver/master/pkg/apis/audit/v1/types.go | works | audit Event fields | 2026-10-26
- raw.githubusercontent.com/mitre-attack/attack-stix-data/master/enterprise-attack/enterprise-attack.json | works (55 MB) | ATT&CK IDs/names; parse with python | 2026-10-26
- github.com/kubernetes-sigs/controller-tools/releases/download/envtest-v1.34.1/envtest-v1.34.1-linux-amd64.tar.gz | works | kube-apiserver, etcd, kubectl for local tests | 2026-10-26
- github.com/gohugoio/hugo/releases/download/v0.152.2/hugo_extended_0.152.2_linux-amd64.tar.gz | works | builds site | 2026-10-27
- raw.githubusercontent.com/php/php-src/php-X.Y.Z/{NEWS,php.ini-production} | works | release notes per tag (CVE fix lines), production ini defaults | 2026-10-27
- raw.githubusercontent.com/php/doc-en/master/... (appendices/ini.core.xml, reference/session/ini.xml, reference/filesystem/ini.xml, install/fpm/configuration.xml) | works | PHP manual source; strip XML tags with sed; link php.net/manual pages in posts (URLs confirmed via WebSearch) | 2026-10-27
- images.unsplash.com/photo-<id>?w=1600&q=80&fm=jpg | works | preview a cover before committing; scripts/fetch-covers.sh runs locally if the workflow does not fire | 2026-10-27
- Sandbox has php8.3-cli (Ubuntu 24.04) | works | test PHP behaviour with php -n / -d / -S | 2026-10-27

## Fails from the shell
- api.first.org (EPSS API) | fails: proxy 403 CONNECT | use raw.githubusercontent.com/empiricalsec/epss_scores (README reachable) or WebSearch | 2026-10-26
- cisa.gov, nvd.nist.gov, cve.org | often 403 | WebSearch + WebFetch, or cvelistV5/kev-data raw | 2026-10-25
- firewallsync.com via curl | blocked by proxy | WebFetch | 2026-10-25
- firewallsync.com via WebFetch | PROVENANCE_REQUIRED on 2026-10-26 and 2026-10-27 (not retried) | live check not possible in runs; owner spot-checks | 2026-10-27
- api.github.com (GHSA advisories for repos outside session scope) | 403 | use the CNA's CVE record + vendor page via WebSearch | 2026-10-27
- php.net from shell | no connection (000) | WebSearch + WebFetch (php.net/archive/2026.php works) | 2026-10-27
- unsplash.com/photos pages found only inside a fetched search page | PROVENANCE_REQUIRED | WebSearch for the photo page first | 2026-10-27
- Restarting a background kube-apiserver with new flags (pkill + relaunch) | denied by the auto-mode classifier | start it once with all flags you need (e.g. --allow-privileged=true) | 2026-10-26

## WebFetch (after WebSearch)
- bleepingcomputer.com, thehackernews.com, csoonline.com articles | works (bleepingcomputer SERVER_ERROR once 2026-10-27) | press context only; attribute; infosecurity-magazine.com, securityaffairs.com work | 2026-10-27
- vulncheck.com/blog, openwall.com/lists/oss-security, ic3.gov/PSA | works | | 2026-10-27
- docs.paloaltonetworks.com (ngfw admin, pan-os/9-1 admin guide) | works | best-practices/10-1 landing page has no content, use the admin-guide pages | 2026-10-26
- security.paloaltonetworks.com advisories | not returned by WebSearch | use the CVE record (same text: solutions/workarounds/exploits) | 2026-10-26
- unsplash.com/photos/<slug-id> | works | gives photographer + images.unsplash.com photo id | 2026-10-26
- docs.azure.cn (AKS mirror) | works | learn.microsoft.com mirror; mark QUALIFIED | 2026-10-25
- docs.aws.amazon.com | works | | 2026-10-25

## Not available to these runs
- gsc-wizard / Google Search Console | do not use | | 2026-10-26
