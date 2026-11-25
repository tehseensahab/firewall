# Source playbook

One line per source: domain, page or data path | works / fails (how) | workaround | date checked
(Trimmed 2026-11-12: one-off product sources for PHP, Magento, Ruby, Brotli, Palo Alto, Adobe, Ivanti, Cisco, GitLab, WordPress, Node advisories, PostgreSQL docs and old sandbox notes; see git history before 2026-11-12 if needed.)

## Works from the shell (curl)
- raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json | works | KEV catalog incl. forensicTriage, notes, cwes | 2026-10-26
- raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/<year>/<Nxxx>/CVE-*.json | works | full CNA record (affected, solutions, workarounds, exploits) + CISA ADP SSVC/KEV | 2026-10-26
- raw.githubusercontent.com/kubernetes/website/main/content/en/docs/... | works | k8s docs source (audit.md, pod-security-standards.md, configure-service-account.md) | 2026-10-26
- raw.githubusercontent.com/kubernetes/apiserver/master/pkg/apis/audit/v1/types.go | works | audit Event fields | 2026-10-26
- raw.githubusercontent.com/mitre-attack/attack-stix-data/master/enterprise-attack/enterprise-attack.json | works (55 MB) | ATT&CK IDs/names; parse with python | 2026-10-26
- images.unsplash.com/photo-<id>?w=1600&q=80&fm=jpg | works | preview a cover before committing; scripts/fetch-covers.sh runs locally if the workflow does not fire | 2026-10-27
- raw.githubusercontent.com/OWASP/CheatSheetSeries/master/cheatsheets/*.md | works | link cheatsheetseries.owasp.org page in posts | 2026-10-28
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
- raw.githubusercontent.com/CVEProject/cvelistV5/main/{cves/delta.json,cves/deltaLog.json (36.8 MB),.github/workflows/*.yml,.github/workflows/dist/index.js} | works | change feed + tooling source | 2026-11-08
- github.com/CVEProject/cvelistV5/releases/download/cve_<date>_<HH>00Z/<date>_delta_CVEs_at_<HH>00Z.zip | works | hourly cumulative-since-midnight delta zip; git ls-remote --tags lists tags | 2026-11-08
- Hugo v0.139.4 extended tarball from github releases | works | builds site (0.152.2 also works) | 2026-11-08
- github.com/cisagov/kev-data full git clone (3 MB, 6 s; default branch develop) | works | every catalog version since 2025-01-27 via git show <commit>:known_exploited_vulnerabilities.json; field-history replays | 2026-11-10
- raw.githubusercontent.com/aquasecurity/trivy/v0.76.2/{docs/guide/supply-chain/vex/*.md,pkg/vex/oci/oci.go,pkg/oci/artifact.go} | works | VEX docs + OCI discovery source; link github.com blob at tag (trivy.dev URLs unverified) | 2026-11-11
- github.com/aquasecurity/trivy blobless clone + git log/tag --contains | works; `git grep` on blobless clone hangs (fetches all blobs) | use raw for file contents | 2026-11-11
- raw.githubusercontent.com/sigstore/cosign/v3.1.4/{CHANGELOG.md,doc/cosign_*.md,cmd/cosign/cli/options/*.go} | works | flag defaults, predicate type map | 2026-11-11
- raw.githubusercontent.com/sigstore/docs/main/content/en/cosign/verifying/attestation.md | works | link docs.sigstore.dev/cosign/verifying/attestation/ | 2026-11-11
- github.com HTML pages via curl | 403 from proxy | raw.githubusercontent.com for content | 2026-11-11
- unsplash.com photo pages via WebFetch | works; many results are Unsplash+ (premium, plus.unsplash.com) | check "Free to use under the Unsplash License" before adding to covers.tsv | 2026-11-11
- github.com/openvex/vexctl git clone --depth 1 --branch <tag> + raw openvex/go-vex/<tag>/pkg/... | works | vexctl source (internal/cmd, pkg/ctl, examples); git ls-remote --tags for latest | 2026-11-12
- github.com/<org>/<repo>/releases/download/... binaries (e.g. vexctl-linux-amd64) | download denied by auto-mode classifier ("Code from External") | read source at the tag; port logic to Python and label it | 2026-11-12
- raw.githubusercontent.com/CERTCC/SSVC/main/src/ssvc/decision_points/ssvc/automatable.py, cve-schema schema/imports/cvss/cvss-v4.0.json | works | | 2026-11-14
- firewallsync.com/posts/<slug>/?v=<commit> via shell curl | works 2026-11-15 (200; earlier runs got proxy 403); WebFetch still PROVENANCE_REQUIRED for some URLs | use curl + grep h1/cover_hu for the live check | 2026-11-15
- cvelistV5 release zip corpus passes (stream inner cves.zip; filter by assignerShortName, problemTypes, metrics; venv cvss lib for recomputation) | works, 663 MB ~20 s, ~50 s per full pass | | 2026-11-15
- cwe.mitre.org from shell (cwec_latest.xml.zip) | fails: proxy 403 CONNECT | WebSearch + WebFetch cwe.mitre.org/data/definitions/<n> and top25 archive pages (work) | 2026-11-15
- raw.githubusercontent.com/cisagov/vulnrichment/develop/README.md | works | CISA-ADP CWE/CVSS enrichment rules verbatim | 2026-11-15
- cvelistV5 tag-to-tag diff: blobless clone (~30 s) + git fetch --depth=1 origin tag <a> tag <b> + git diff --name-status, then curl --parallel -K cfg of raw.githubusercontent.com/CVEProject/cvelistV5/<commit>/<path> | works (46k files in ~2 min); ~2% return HTTP 429 text bodies at parallel 64: validate JSON and refetch at parallel 8 | 2026-11-16
- raw cvelistV5 main records for all 1,781 KEV CVEs via curl --parallel-max 16 -K cfg | works, ~11 s, no 429s | 2026-11-17
- cvelistV5 release asset <date>_all_CVEs_at_midnight.zip.zip | intermittent: 404 (9-byte body) on 2026-11-16 and for 2026-11-19 at 04:51Z; works 2026-11-17/18 | take the previous day's asset or the tag-diff method | 2026-11-19
- kev-data git history replay (git show <commit>:known_exploited_vulnerabilities.json for all 345 commits) | works, ~1 min | dueDate/forensicTriage edit audit; schema file known_exploited_vulnerabilities_schema.json has field descriptions | 2026-11-18
- pypi.org/pypi/<pkg>/json via curl | works | release list, upload times, yanked flags: primary record for PyPI compromises | 2026-11-19
- raw.githubusercontent.com/python/cpython/main/Doc/library/site.rst | works | .pth semantics verbatim; link docs.python.org/3/library/site.html | 2026-11-19
- raw openvex/go-vex/<tag>/pkg/vex/*.go + git clone --depth 1 go-vex main (pkg/validate) and vexctl main | works | statement struct, SortStatements, unreleased validator; local `go run` of stdlib-only programs works (Go 1.24.7) | 2026-11-20
- git clone --depth 1 --branch <tag> gocsaf/csaf + copy csaf/{advisory,models,cvss*enums,util}.go, internal/misc, util NWriter into a scratch module (module github.com/gocsaf/csaf/v3), GOPROXY=off go build | works | runs the exact decoder Trivy uses without go get | 2026-11-21
- git clone --filter=blob:none oasis-tcs/csaf + checkout csaf_2.0/referenced_schema (FIRST cvss schemas) | works | offline CSAF 2.0 schema validation via referencing.Registry; csaf_2.1/prose/share/csaf-v2.1-draft.md = CS01 2026-11-09 | 2026-11-21
- git clone --filter=blob:none oasis-tcs/csaf + checkout csaf_2.1/{prose/edit/src,prose/share,json_schema,referenced_schema,examples} | works | CS01 prose split by section (conformance-01-cls-18 converter, distributing-04 transition, profiles, tests-01-mndtr-*); offline 2.1 validation: register referenced_schema/first/*.json under https://www.first.org/cvss/<file> and certcc under certcc.github.io/SSVC/data/schema/v2/<file> | 2026-11-22
- git clone --depth 1 --branch 'v5.0.0-pre.1+20261105' gocsaf/csaf | works | first gocsaf tag with CSAF 2.1 (README, docs/csaf_downloader.md); v3.7.1 still 2.0-only | 2026-11-22
- raw.githubusercontent.com/oasis-tcs/csaf/<commit>/csaf_2.1/{json_schema/csaf.json,prose/edit/src/*.md,test/validator/data/{mandatory,recommended}/*.json} | works | blobless clone + git checkout of whole dirs timed out at 2 min 2026-11-23: use git ls-tree for names and raw for files; offline validation: Resource(..., DRAFT202012) for FIRST cvss schemas (their $schema meta.json is unknown to referencing) | 2026-11-23
- Broadcom VMSA (support.broadcom.com .../SecurityAdvisories/0/<id>), knowledge.broadcom.com/external/article/<id>, securityweek.com, rapid7.com/blog/post/etr-* | works via web-fetch agent on WebSearch URLs | | 2026-11-23
- unsplash.com/s/photos/<query> via web-fetch agent (from WebSearch results) | DENIED by auto-mode classifier 2026-11-23 (worked 11-15) | no workaround found; posts fall back to theme placeholder; owner adds covers | 2026-11-23
- github.com/CERTCC/SSVC blobless clone + git checkout of data/json/ssvc_object_registry.json, data/json/decision_tables/cisa/*, data/csv/cisa/*, docs/howto/*.md | works | registry has DecisionPoint + DecisionTable by namespace/key/version; docs source replaces certcc.github.io fetch | 2026-11-24
- cisco.com/c/ja_jp/support/docs/csa/2026/<advisory>.pdf via web-fetch agent (from WebSearch) | works | localized Cisco advisory; English sec.cloudapps.cisco.com page not returned by WebSearch; version strings usable, wording = translation | 2026-11-24
- github.com/cisagov/vulnrichment blobless clone (7 s, 13k commits) + git log -- <path> per CVE (139 paths ~25 s) + curl --parallel -K raw.githubusercontent.com/cisagov/vulnrichment/<sha>/<path> (1,083 files ~8 s, no 429s) | works | SSVC history replay | 2026-11-25
- cvelistV5 release asset cve_2026-11-25_0000Z/2026-11-25_all_CVEs_at_midnight.zip.zip | works (674 MB); census pass ~36 s | | 2026-11-25
- unsplash.com/photos/<page> download URL via shell | 401 (bot wall) | get photo id via web-fetch agent on WebSearch result page, then images.unsplash.com/photo-<id> works | 2026-11-25
## Fails from the shell
- git.kernel.org (vulns.git, stable) from shell | fails: proxy 403 CONNECT | use cvelistV5 records (references list the stable fix commits) | 2026-11-07
- epss.empiricalsecurity.com/epss_scores-current.csv.gz | fails: proxy 403 CONNECT 2026-11-02 (worked 2026-10-16) | git clone empiricalsec/epss_scores (above) | 2026-11-02
- api.first.org (EPSS API) | fails: proxy 403 CONNECT | use raw.githubusercontent.com/empiricalsec/epss_scores (README reachable) or WebSearch | 2026-10-26
- cisa.gov, nvd.nist.gov, cve.org | shell often 403; via WebFetch cve.org pages and NVD vulnerability-detail-pages return empty (JS) | cvelistV5/kev-data raw, cve-schema text, or WebSearch+WebFetch for cisa.gov | 2026-11-04
- api.github.com (GHSA advisories for repos outside session scope) | 403 | use the CNA's CVE record + vendor page via WebSearch | 2026-10-27
- security.access.redhat.com / access.redhat.com CSAF VEX files from shell | no connection (000) | describe from Red Hat blog posts via WebSearch (redhat.com/<locale>/blog/...); localized copies fetch fine | 2026-11-05
## WebFetch (after WebSearch)
- kernel.org/releases.html | works via WebSearch+WebFetch | longterm table, distro-kernel wording | 2026-11-07
- cisa.gov/known-exploited-vulnerabilities | works via WebSearch+WebFetch | KEV criteria verbatim | 2026-11-07
- research.empiricalsecurity.com/research/* (EPSS V5 post), EIN Presswire syndications of Empirical releases | works via WebSearch+WebFetch | vendor claims; first.org has no v5 page in search results 2026-11-06 | 2026-11-06
- bleepingcomputer.com, thehackernews.com, csoonline.com articles | works (bleepingcomputer SERVER_ERROR once 2026-10-27) | press context only; attribute; infosecurity-magazine.com, securityaffairs.com work | 2026-10-27 (bleepingcomputer non-amp URL: client_error 2026-10-30; try /amp/)
- rapid7.com/blog/post/etr-*, theregister.com/a/<id>, cyber.gc.ca/en/alerts-advisories/*, csa.gov.sg/alerts-and-advisories/alerts/* | works | Rapid7 reproduces vendor version tables (qualify); cyber.gc.ca/CSA SG are government alerts with update dates | 2026-10-31
- support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/<id> (VMSA) | works via WebSearch+WebFetch | primary for VMware CVEs (response matrix, change log) | 2026-11-01; knowledge.broadcom.com ESXi KBs also work
- ic3.gov/CSA/<year>/<id>.pdf (joint CISA/FBI advisories) | works via WebSearch+WebFetch | primary text when the cisa.gov resource page is not returned | 2026-11-09
- first.org/cvss/v4.0/specification-document | works via WebSearch (allowed_domains first.org) + WebFetch; page is 138k chars, use offset 100000 for Supplemental Table 23 | | 2026-11-14
- cve.org CNA_Rules_v4.1.0.pdf | works via WebSearch+WebFetch | CNA rule text | 2026-11-15
- cisa.gov BOD 26-04 page + implementation guidance, cisa.gov/news-events/alerts/2026/*, bleepingcomputer.com/news/security/*, upstreamonline.com | WebFetch client_error / robots_disallowed 2026-11-18 (cisa.gov BOD 22-01 page works) | cite earlier verified posts or other outlets | 2026-11-18
- wiz.io/blog/*, chainguard.dev/unchained/*, securityweek.com/* | works via WebSearch+WebFetch | supply-chain news sourcing; bleepingcomputer.com article SERVER_ERROR twice 2026-11-19; labs.cloudsecurityalliance.org briefing client_error | 2026-11-19
- Unsplash container/port photos | most show carrier brand names (Maersk, ONE, Hapag-Lloyd) | preview images.unsplash.com before adding; prefer non-branded motifs | 2026-11-20
- certcc.github.io/SSVC/* via web-fetch agent | DENIED by classifier 2026-11-24 | read docs/*.md from the CERTCC/SSVC repo | 2026-11-24
- cisa.gov directive pages via shell curl (URL from KEV notes) | DENIED by classifier 2026-11-24 | WebSearch + web-fetch agent only if the URL is a search result | 2026-11-24
- unsplash.com/s/photos/<query> via web-fetch agent | works only when the URL came back from WebSearch (allowed_domains unsplash.com); typed query URLs denied | 2026-11-24
- News outlets (therecord.media, theregister.com, securityweek.com, helpnetsecurity.com, huntress.com, cyberscoop.com, wiz.io, darkreading.com, Reuters syndications) | works via WebSearch + web-fetch agent | news trial ended 2026-11-22; details in git history | 2026-11-25
## Not available to these runs
- gsc-wizard / Google Search Console | do not use | | 2026-10-26
