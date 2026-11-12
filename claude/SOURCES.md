# Source playbook

One line per source: domain, page or data path | works / fails (how) | workaround | date checked
(Trimmed 2026-11-12: one-off product sources for PHP, Magento, Ruby, Brotli, Palo Alto, Adobe, Ivanti, Cisco, GitLab, WordPress, Node advisories, PostgreSQL docs and old sandbox notes; see git history before 2026-11-12 if needed.)

## Works from the shell (curl)
- raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json | works | KEV catalog incl. forensicTriage, notes, cwes | 2026-10-26
- raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/<year>/<Nxxx>/CVE-*.json | works | full CNA record (affected, solutions, workarounds, exploits) + CISA ADP SSVC/KEV | 2026-10-26
- raw.githubusercontent.com/kubernetes/website/main/content/en/docs/... | works | k8s docs source (audit.md, pod-security-standards.md, configure-service-account.md) | 2026-10-26
- raw.githubusercontent.com/kubernetes/apiserver/master/pkg/apis/audit/v1/types.go | works | audit Event fields | 2026-10-26
- raw.githubusercontent.com/mitre-attack/attack-stix-data/master/enterprise-attack/enterprise-attack.json | works (55 MB) | ATT&CK IDs/names; parse with python | 2026-10-26
- raw.githubusercontent.com/php/doc-en/master/... (appendices/ini.core.xml, reference/session/ini.xml, reference/filesystem/ini.xml, install/fpm/configuration.xml) | works | PHP manual source; strip XML tags with sed; link php.net/manual pages in posts (URLs confirmed via WebSearch) | 2026-10-27
- images.unsplash.com/photo-<id>?w=1600&q=80&fm=jpg | works | preview a cover before committing; scripts/fetch-covers.sh runs locally if the workflow does not fire | 2026-10-27
- pypi.org/pypi/<pkg>/json | works | release versions + upload dates | 2026-10-28
- raw.githubusercontent.com/OWASP/CheatSheetSeries/master/cheatsheets/*.md | works | link cheatsheetseries.owasp.org page in posts | 2026-10-28
- Sandbox: node v22.23.4, pip venv (python3 -m venv) and npm install (express etc.) from registries | works | test runtime behaviour | 2026-10-29
- raw.githubusercontent.com/nodejs/node/<vX.Y.Z>/doc/api/*.md | works | use the tag matching the tested runtime; main branch docs list unreleased versions | 2026-10-29
- raw.githubusercontent.com/{google/re2/main/README.md, golang/go/master/src/regexp/regexp.go, rust-lang/regex/master/{README.md,src/lib.rs}, python/cpython/main/Doc/library/re.rst, dotnet/docs/main/docs/standard/base-types/*.md, v8/v8.dev/main/src/blog/*.md} | works | engine/runtime doc sources; link the rendered docs pages | 2026-10-31
- cvelistV5 path for a KEV CVE with no CNA record yet (e.g. 2026/118xxx/CVE-2026-118527) | 404 | KEV shortDescription is then the only primary text; say so in the post | 2026-10-31
- Go module downloads (go get, GOPROXY=direct) | denied by the auto-mode classifier 2026-11-06; proxy.golang.org DNS fails | read library source via raw and port the logic to Python (label as a port) | 2026-11-06
- github.com/empiricalsec/epss_scores partial clone (blob:none, no-checkout) + git checkout HEAD -- <year>/epss_scores-YYYY-MM-DD.csv.gz | works | every daily file since 2021 + beta_scores/ (EPSS v5 beta, model v2026.05.12); first line = #model_version,score_date | 2026-11-06
- github.com/CVEProject/cvelistV5 partial clone (blob:none, no-checkout) | works in ~3 s | gives full file list (git ls-tree); fetch blobs with parallel curl of raw.githubusercontent.com/CVEProject/cvelistV5/<commit>/cves/... (xargs -P 24: 1,000 files in seconds); per-path git checkout of 1,000 blobs timed out | 2026-11-02
- github.com/CVEProject/cve-schema, cisagov/vulnrichment, CERTCC/SSVC (git clone, sparse checkout of data/csv/ssvc/*.csv, docs/howto/deployer_tree.md, src/ssvc/decision_points/ssvc/*.py), raw openvex/spec/main/OPENVEX-SPEC.md | works | primary specs for the prioritization cluster | 2026-11-02
- raw.githubusercontent.com/CycloneDX/specification/master/schema/bom-1.{6,7}.schema.json, openvex/spec/main/openvex_json_schema.json, git clone oasis-tcs/csaf (csaf_2.0/json_schema + prose) | works | VEX enums with meta:enum definitions; CSAF profile text = TC draft (qualify) | 2026-11-03
- git clone --sparse aquasecurity/trivy (pkg/vex) | works | how a real consumer maps VEX states | 2026-11-03
- Sandbox venv pip install jsonschema check-jsonschema | works | validate CycloneDX/OpenVEX test files | 2026-11-03
- git ls-remote --tags / git fetch --depth 1 <repo> tag <t> (cve-schema) | works | tag commit dates for "added in version X" claims | 2026-11-04
- github.com/oasis-tcs/csaf partial clone (blob:none) + git checkout of csaf_2.0/prose/csaf-v2-editor-draft.md, json_schema, examples/csaf/csaf_vex | works | CSAF 2.0 prose (OASIS Standard header), schema validates with python jsonschema; csaf_2.1 = CSD draft | 2026-11-05
- github.com/CVEProject/cvelistV5/releases/download/<tag>/<date>_all_CVEs_at_midnight.zip.zip | works (652 MB in ~24 s) | full corpus; stream inner cves.zip with python zipfile (~30 s per pass) for corpus-wide counts | 2026-11-05
- raw.githubusercontent.com/CVEProject/cve-schema/main/{schema/CVE_Record_Format.json,rfds/*.md}; package-url/purl-spec (types/*-definition.json, docs/specification/standard/*, docs/decisions/*) | works | | 2026-11-05
- raw.githubusercontent.com/aquasecurity/trivy/<tag>/{pkg/vex/*.go,docs/guide/supply-chain/vex/file.md} | works | docs moved from docs/docs/ to docs/guide/; git ls-remote --tags for latest tag | 2026-11-05; also raw openvex/go-vex/<tag>/pkg/vex/*.go (version from trivy go.mod) | 2026-11-06
- raw.githubusercontent.com/torvalds/linux/master/Documentation/process/cve.rst | works | kernel CVE process text; link docs.kernel.org/process/cve.html | 2026-11-07
- Linux CNA records: stream cvelistV5 release zip, filter cveMetadata.assignerShortName == "Linux" (7,987 for 2026 in ~1 min) | works | kernel affected/CPE corpus stats | 2026-11-07
- raw.githubusercontent.com/CVEProject/cvelistV5/main/{cves/delta.json,cves/deltaLog.json (36.8 MB),.github/workflows/*.yml,.github/workflows/dist/index.js} | works | change feed + tooling source | 2026-11-08
- github.com/CVEProject/cvelistV5/releases/download/cve_<date>_<HH>00Z/<date>_delta_CVEs_at_<HH>00Z.zip | works | hourly cumulative-since-midnight delta zip; git ls-remote --tags lists tags | 2026-11-08
- Hugo v0.139.4 extended tarball from github releases | works | builds site (0.152.2 also works) | 2026-11-08
- github.com/CVEProject/cvelistV5/releases/download/cve_<date>_0000Z/<date>_all_CVEs_at_midnight.zip.zip | works (656 MB); the cve_<date>_at_end_of_day tag has no such asset (9-byte 404 body) | use the next day's _0000Z tag | 2026-11-09
- github.com/cisagov/kev-data full git clone (3 MB, 6 s; default branch develop) | works | every catalog version since 2025-01-27 via git show <commit>:known_exploited_vulnerabilities.json; field-history replays | 2026-11-10
- raw.githubusercontent.com/aquasecurity/trivy/v0.76.2/{docs/guide/supply-chain/vex/*.md,pkg/vex/oci/oci.go,pkg/oci/artifact.go} | works | VEX docs + OCI discovery source; link github.com blob at tag (trivy.dev URLs unverified) | 2026-11-11
- github.com/aquasecurity/trivy blobless clone + git log/tag --contains | works; `git grep` on blobless clone hangs (fetches all blobs) | use raw for file contents | 2026-11-11
- raw.githubusercontent.com/sigstore/cosign/v3.1.4/{CHANGELOG.md,doc/cosign_*.md,cmd/cosign/cli/options/*.go} | works | flag defaults, predicate type map | 2026-11-11
- raw.githubusercontent.com/sigstore/docs/main/content/en/cosign/verifying/attestation.md | works | link docs.sigstore.dev/cosign/verifying/attestation/ | 2026-11-11
- github.com HTML pages via curl | 403 from proxy | raw.githubusercontent.com for content | 2026-11-11
- uptime.n-able.com status pages via WebFetch | approval prompt (PROVENANCE_REQUIRED) | use TechCrunch/Huntress quotes of the status page | 2026-11-11
- huntress.com/blog, techcrunch.com, csoonline.com, cybersecuritynews.com via WebSearch+WebFetch | works | news-trial confirmation sources | 2026-11-11
- unsplash.com photo pages via WebFetch | works; many results are Unsplash+ (premium, plus.unsplash.com) | check "Free to use under the Unsplash License" before adding to covers.tsv | 2026-11-11
- github.com/openvex/vexctl git clone --depth 1 --branch <tag> + raw openvex/go-vex/<tag>/pkg/... | works | vexctl source (internal/cmd, pkg/ctl, examples); git ls-remote --tags for latest | 2026-11-12
- github.com/<org>/<repo>/releases/download/... binaries (e.g. vexctl-linux-amd64) | download denied by auto-mode classifier ("Code from External") | read source at the tag; port logic to Python and label it | 2026-11-12
## Fails from the shell
- firewallsync.com live-page check | WebFetch asked for approval (PROVENANCE_REQUIRED) 2026-11-11; shell curl 403 CONNECT | report 'pushed; live not confirmed' | 2026-11-11
- git.kernel.org (vulns.git, stable) from shell | fails: proxy 403 CONNECT | use cvelistV5 records (references list the stable fix commits) | 2026-11-07
- epss.empiricalsecurity.com/epss_scores-current.csv.gz | fails: proxy 403 CONNECT 2026-11-02 (worked 2026-10-16) | git clone empiricalsec/epss_scores (above) | 2026-11-02
- api.first.org (EPSS API) | fails: proxy 403 CONNECT | use raw.githubusercontent.com/empiricalsec/epss_scores (README reachable) or WebSearch | 2026-10-26
- cisa.gov, nvd.nist.gov, cve.org | shell often 403; via WebFetch cve.org pages and NVD vulnerability-detail-pages return empty (JS) | cvelistV5/kev-data raw, cve-schema text, or WebSearch+WebFetch for cisa.gov | 2026-11-04
- firewallsync.com via curl | blocked by proxy | WebFetch | 2026-10-25
- firewallsync.com via WebFetch | PROVENANCE_REQUIRED 2026-10-26 to 11-10 (not retried) | live check not possible in runs; owner spot-checks | 2026-10-28
- api.github.com (GHSA advisories for repos outside session scope) | 403 | use the CNA's CVE record + vendor page via WebSearch | 2026-10-27
- unsplash.com/photos pages found only inside a fetched search page | PROVENANCE_REQUIRED | WebSearch for the photo page first | 2026-10-27
- security.access.redhat.com / access.redhat.com CSAF VEX files from shell | no connection (000) | describe from Red Hat blog posts via WebSearch (redhat.com/<locale>/blog/...); localized copies fetch fine | 2026-11-05
- trivy.dev docs via WebFetch | /docs/latest works (v0.67), versioned /v0.50/ client_error 2026-11-05 | read docs source from raw.githubusercontent.com at a tag | 2026-11-05
## WebFetch (after WebSearch)
- kernel.org/releases.html | works via WebSearch+WebFetch | longterm table, distro-kernel wording | 2026-11-07
- riskbasedprioritization.github.io/epss/* | works | community guide quoting FIRST FAQ (qualify); first.org/epss/faq not returned by WebSearch (only proxy mirrors) | 2026-11-07
- cisa.gov/known-exploited-vulnerabilities | works via WebSearch+WebFetch | KEV criteria verbatim | 2026-11-07
- research.empiricalsecurity.com/research/* (EPSS V5 post), EIN Presswire syndications of Empirical releases | works via WebSearch+WebFetch | vendor claims; first.org has no v5 page in search results 2026-11-06 | 2026-11-06
- unsplash.com/s/photos/<query> | works for listing, but photo pages from it need their own WebSearch hit | search "unsplash.com/photos <subject>" until a /photos/ URL is returned; reject Unsplash+ (plus.unsplash.com ids) | 2026-10-29
- bleepingcomputer.com, thehackernews.com, csoonline.com articles | works (bleepingcomputer SERVER_ERROR once 2026-10-27) | press context only; attribute; infosecurity-magazine.com, securityaffairs.com work | 2026-10-27 (bleepingcomputer non-amp URL: client_error 2026-10-30; try /amp/)
- vulncheck.com/blog, openwall.com/lists/oss-security, ic3.gov/PSA | works | | 2026-10-27
- unsplash.com/photos/<slug-id> (from WebSearch) | works | gives photographer + photo id; grep covers.tsv first; preview and reject brand names, signage, religious buildings | 2026-11-04
- rapid7.com/blog/post/etr-*, theregister.com/a/<id>, cyber.gc.ca/en/alerts-advisories/*, csa.gov.sg/alerts-and-advisories/alerts/* | works | Rapid7 reproduces vendor version tables (qualify); cyber.gc.ca/CSA SG are government alerts with update dates | 2026-10-31
- support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/<id> (VMSA) | works via WebSearch+WebFetch | primary for VMware CVEs (response matrix, change log) | 2026-11-01; knowledge.broadcom.com ESXi KBs also work
- therecord.media (homepage + articles), bleepingcomputer.com/news/security/<slug> (no www), cybersecuritynews.com | works | news-trial sourcing; homepage fetch lists last-7-day stories | 2026-11-08
- bugzilla.mozilla.org CA incident bugs (e.g. 2084460) | not returned by WebSearch for new bugs | cite outlets that quote it; say primary not retrieved | 2026-11-08
- ic3.gov/CSA/<year>/<id>.pdf (joint CISA/FBI advisories) | works via WebSearch+WebFetch | primary text when the cisa.gov resource page is not returned | 2026-11-09
- fox17.com/news/local/*, gizmodo.com/*, therecord.media/<slug> | works via WebSearch+WebFetch | news-trial sourcing; therecord.media homepage hit PROVENANCE_REQUIRED 2026-11-10; nashvillebanner.com robots_disallowed; bleepingcomputer www URL SERVER_ERROR, no-www URL works | 2026-11-10
- theregister.com/2026/02/03/greynoise_cisa_ransomware_gripe/ | works | GreyNoise KEV ransomware-flip count (press) | 2026-11-10
- news.vanderbilt.edu incident page | not returned by WebSearch | quote via FOX 17/Gizmodo, say so | 2026-11-10
- 1027wbow.com (Reuters syndication), theregister.com/security/2026/*, securityaffairs.com, cybernews.com/security/* | works via WebSearch+WebFetch | news-trial sourcing; maersk.com newsroom not returned by WebSearch (quote via Reuters/Register) | 2026-11-12
- unsplash.com/s/photos/<query> via WebFetch | works and lists images.unsplash.com photo-<id> for each tile | photo page pages often omit the id; get it from the search page, then WebSearch the photo page (locale copies like /pt-br/fotografias/ count) for photographer + license | 2026-11-12
- unsplash.com /download, /napi, /oembed from shell | bot challenge / "Authorization required" | use images.unsplash.com/photo-<id> for previews | 2026-11-12
## Not available to these runs
- gsc-wizard / Google Search Console | do not use | | 2026-10-26