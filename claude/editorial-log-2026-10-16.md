# Editorial log 2026-10-16

Two new articles published. No post dated 2026-10-16 was on main at start. Posts dated 06:11Z and 06:12Z; pushed about 06:15Z (commit a22dbbc); cover.jpg added by workflow, alt text corrected after viewing the images (15bd54e).

## Article 1: EPSS data feed (security-operations)
Slug: epss-data-feed-columns-percentile-vs-probability-and-how-to-join-it-to-a-scanner-export
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| EPSS definition, not a complete risk score, base rates, probability vs percentile, mean ~2.8% / median ~0.7%, 0.10 ≈ 95th percentile, 50% threshold deprioritizes 98.8% | FIRST EPSS FAQ and Using EPSS (curl, read 2026-10-16) | undated pages | VERIFIED | FIRST figures undated |
| Three access routes, CSV URL, three columns, percentile definition, archive from 2021-04-14, model versions v1 to v5 and start dates, score-shift warning | FIRST Get the Data | read 2026-10-16 | VERIFIED | |
| API parameters, time-series scope, BETA | api.first.org/epss | read 2026-10-16 | VERIFIED | No rate-limit text found in what was read |
| Sources record activity not success; VulnCheck KEV a partner | FIRST How EPSS Works | read 2026-10-16 | VERIFIED | |
| Aggregation formulas, 99.4% / 5 example, 90th pct ≈ 0.04, High ≈ 0.008 | FIRST Using EPSS; own arithmetic 1-0.95^100=0.99408 | | VERIFIED | FIRST rules of thumb, not reproduced |
| File: v2026.06.15, scored 2026-10-15T12:03:56Z, 389,824 unique CVEs; thresholds, median 0.00649, mean 0.02666, percentile>=0.9 38,987, >=0.99 3,903 | EPSS CSV (downloaded 2026-10-16 06:06Z) | snapshot | QUALIFIED | Own tallies |
| KEV 2026.10.15 released 17:00:11Z, 1,746 entries all scored; 1,470 >=0.9 pct; 870 >=0.5; 61 <0.01; median 0.49166 | KEV JSON + EPSS CSV | snapshot | QUALIFIED | Not evidence of accuracy |
| Log4Shell API values (0.99999 current; 0.94402 on 2022-02-28) | api.first.org | 2026-10-16 | VERIFIED | |
| CVE-2024-1992, CVE-2019-1508 absent from file; CVE-2026-14683 scored 0.0016/0.04694 | CVE Services API + CSV | 2026-10-16 | VERIFIED | |
| Script and output | Run on 5-row CSV | 2026-10-16 | VERIFIED | Not run on a real export |

## Article 2: CVE record states (security-operations)
Slug: cve-record-states-published-rejected-and-disputed-what-each-means-for-vulnerability-triage
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| One cna container, many adp; states Published/Rejected; rejectedReasons required, replacedBy optional; status enum | CVE_Record_Format.json (cve-schema main) | read 2026-10-16 | VERIFIED | |
| Tag definitions (3 CNA tags, ADP disputed only) | schema/tags/cna-tags.json, adp-tags.json | read 2026-10-16 | VERIFIED | |
| Rules 4.5.3.5-4.5.3.11, 4.2.17.1, 5.1.4, 5.1.6, 5.1.8, 5.1.11.1 | CNA Operational Rules v4.1.0 PDF | effective 2025-05-14 | QUALIFIED | Not confirmed to be latest version; dispute policy not read |
| CVE-2024-1992, CVE-2019-1508 rejected, dates, reasons, replacedBy absent | cveawg.mitre.org API | 2026-10-16 | VERIFIED | Two records only |
| CVE-2026-14683 disputed (VulDB), CVE-2020-35235 unsupported-when-assigned | cveawg API; NVD API (vulnStatus Deferred) | 2026-10-16 | VERIFIED | |
| NVD 408,789 records; 390,296 with noRejected; 1,509 cveTag=disputed | NVD API 2.0 | 2026-10-16 | QUALIFIED | Rejected count is subtraction; 472 gap vs EPSS file uninvestigated |
| EPSS values for the two examples | EPSS CSV | scored 2026-10-15 | VERIFIED | |
| Script and output | Run on 5 IDs | 2026-10-16 | VERIFIED | No error handling tested |
| Triage playbook | Own analysis | | QUALIFIED | Untested |

## Corrections made during the run
- Initial draft said the EPSS/KEV files were downloaded on October 15; they were downloaded October 16 (file scored October 15). Fixed throughout.
- Removed an unsupported claim that the CVE Program "does not rule on who is right" in disputes; replaced with what the tag does. Softened a speculative sentence linking the low EPSS score to the dispute.
- Cover alt text corrected after viewing images: draft said "purple tones" (cards are on a pale surface) and "grey filing cabinet with files".

## Known limitations
- No real scanner export; scripts tested on 5-row inputs only.
- Hugo not installed locally; verified via live site.
- GitHub API for CVEProject repos not reachable (out of session scope), so no bulk CVE list counts; NVD API used instead.
- cve.org pages are JavaScript-rendered; rules were read from the v4.1.0 PDF.

## Next-session candidates
1. Kubernetes ValidatingAdmissionPolicy (CEL) as a built-in alternative for rules Pod Security Admission cannot express (kubernetes.io docs).
2. NVD CVE API 2.0: query parameters, vulnStatus values, rate limits with and without an API key, and avoiding gaps in a local mirror (NVD developer docs).
3. CVSS v4.0 metric groups and nomenclature (CVSS-B, CVSS-BT, CVSS-BE) and how to read a vector string (FIRST CVSS v4.0 specification).
