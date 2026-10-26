# Source playbook

One line per source: domain, page or data path | works / fails (how) | workaround | date checked

## Works from the shell (curl)
- raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json | works | KEV catalog incl. forensicTriage, notes, cwes | 2026-10-26
- raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/<year>/<Nxxx>/CVE-*.json | works | full CNA record (affected, solutions, workarounds, exploits) + CISA ADP SSVC/KEV | 2026-10-26
- raw.githubusercontent.com/kubernetes/website/main/content/en/docs/... | works | k8s docs source (audit.md, pod-security-standards.md, configure-service-account.md) | 2026-10-26
- raw.githubusercontent.com/kubernetes/apiserver/master/pkg/apis/audit/v1/types.go | works | audit Event fields | 2026-10-26
- raw.githubusercontent.com/mitre-attack/attack-stix-data/master/enterprise-attack/enterprise-attack.json | works (55 MB) | ATT&CK IDs/names; parse with python | 2026-10-26
- github.com/kubernetes-sigs/controller-tools/releases/download/envtest-v1.34.1/envtest-v1.34.1-linux-amd64.tar.gz | works | kube-apiserver, etcd, kubectl for local tests | 2026-10-26
- github.com/gohugoio/hugo/releases/download/v0.152.2/hugo_extended_0.152.2_linux-amd64.tar.gz | works | builds site | 2026-10-26

## Fails from the shell
- api.first.org (EPSS API) | fails: proxy 403 CONNECT | use raw.githubusercontent.com/empiricalsec/epss_scores (README reachable) or WebSearch | 2026-10-26
- cisa.gov, nvd.nist.gov, cve.org | often 403 | WebSearch + WebFetch, or cvelistV5/kev-data raw | 2026-10-25
- firewallsync.com via curl | blocked by proxy | WebFetch | 2026-10-25
- Restarting a background kube-apiserver with new flags (pkill + relaunch) | denied by the auto-mode classifier | start it once with all flags you need (e.g. --allow-privileged=true) | 2026-10-26

## WebFetch (after WebSearch)
- bleepingcomputer.com, thehackernews.com, csoonline.com articles | works | press context only; attribute | 2026-10-26
- docs.paloaltonetworks.com (ngfw admin, pan-os/9-1 admin guide) | works | best-practices/10-1 landing page has no content, use the admin-guide pages | 2026-10-26
- security.paloaltonetworks.com advisories | not returned by WebSearch | use the CVE record (same text: solutions/workarounds/exploits) | 2026-10-26
- unsplash.com/photos/<slug-id> | works | gives photographer + images.unsplash.com photo id | 2026-10-26
- docs.azure.cn (AKS mirror) | works | learn.microsoft.com mirror; mark QUALIFIED | 2026-10-25
- docs.aws.amazon.com | works | | 2026-10-25

## Not available to these runs
- gsc-wizard / Google Search Console | do not use | | 2026-10-26
