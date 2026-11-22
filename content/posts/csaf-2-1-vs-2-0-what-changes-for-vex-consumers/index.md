+++
title = "CSAF 2.1 vs 2.0: Field Changes VEX Consumers Must Handle"
date = 2026-11-22T04:30:00Z
tags = ["csaf", "csaf 2.1", "vex", "vulnerability management", "provider-metadata.json", "json schema"]
categories = ["appsec"]
summary = "CSAF 2.1 (Committee Specification 01, 9 November 2026) renames, moves and adds fields a CSAF 2.0 parser relies on: scores becomes metrics, relationships becomes product_paths, cwe becomes cwes, TLP:WHITE becomes TLP:CLEAR, and vendor_fix on a fixed product is now prohibited. Here is the field-by-field diff from the TC's own schemas, the provider-metadata.json transition paths, and a check you can run."
description = "CSAF 2.1 moves scores to metrics, relationships to product_paths and cwe to cwes, adds EPSS, SSVC and CVSS v4, and serves metadata under a v2.1 path."
author = "Craig Leslie"
imageAlt = "A tall stack of printed papers bristling with pink, orange, yellow and green sticky tabs on a desk"
imageCredit = "Photo by [Tanja Tepavac](https://unsplash.com/photos/81ikZZG7_AA) on Unsplash"
takeaways = [
  "CSAF 2.1 is at Committee Specification 01 (dated 9 November 2026 in the OASIS CSAF TC's repository), not yet an OASIS Standard. Its schema only accepts csaf_version '2.1', so 2.0 parsers that check the version will reject 2.1 files outright.",
  "Our diff of the two official JSON schemas: vulnerabilities[].scores is replaced by metrics[] (which adds cvss_v4, epss, ssvc_v2 and qualitative_severity_rating), product_tree.relationships by product_paths, cwe by a cwes array with a version, release_date by disclosure_date, and involvements by a document-level involvement block.",
  "Product status gains an 'unknown' group, remediations gain fix_planned and optional_patch, and the branch category 'legacy' is gone. A vendor_fix remediation on a product listed as fixed or known_not_affected is now prohibited by a mandatory test.",
  "During the transition a provider SHOULD serve /.well-known/csaf/v2.0/provider-metadata.json and /.well-known/csaf/v2.1/provider-metadata.json side by side, with the unversioned path switching from 2.0 to 2.1 at a roll-over date, and without redirects.",
  "gocsaf v5.0.0-pre.1 (the 5 November 2026 pre-release) is the first gocsaf tag that reads 2.1; the stable v3.7.1 line and Trivy v0.76.2 do not."
]

[[faq]]
q = "Is CSAF 2.1 an official standard yet?"
a = "Not yet. The prose in the OASIS CSAF TC's GitHub repository is headed 'Committee Specification 01' and dated 9 November 2026. A Committee Specification is approved by the technical committee but still has to go through the OASIS Standard ballot. CSAF 2.0 remains the current OASIS Standard, and text in 2.1 can still change."

[[faq]]
q = "What is the biggest breaking change in CSAF 2.1 for parsers?"
a = "The version and the scores. document.csaf_version must be '2.1' and the $schema property is required. Per-vulnerability scores move from vulnerabilities[].scores (cvss_v2 and cvss_v3 only) to vulnerabilities[].metrics[].content, which can hold cvss_v2, cvss_v3, cvss_v4, epss, ssvc_v2 and qualitative_severity_rating. A 2.0 parser that reads scores will find nothing in a 2.1 file."

[[faq]]
q = "What does optional_patch mean in CSAF 2.1?"
a = "The spec says optional_patch is a patch from the product's author whose 'application is not necessary, but might be desired by the user', for example to quiet a scanner when a bundled dependency is technically vulnerable but the product is not affected. Unless noted otherwise it does not change the vulnerability state, so it should not open a remediation ticket."

[[faq]]
q = "Where will a vendor publish CSAF 2.1 provider metadata?"
a = "The 2.1 transition section recommends /.well-known/csaf/v2.1/provider-metadata.json for 2.1 and /.well-known/csaf/v2.0/provider-metadata.json for 2.0, both listed in security.txt. The unversioned /.well-known/csaf/provider-metadata.json carries 2.0 until the provider's roll-over date and 2.1 after it. 2.1 metadata can also carry maintained_from and maintained_until dates."
+++

**Short answer:** CSAF 2.1 is not a drop-in update. A CSAF 2.0 parser that reads `vulnerabilities[].scores`, `product_tree.relationships`, `cwe` or `release_date` will silently miss data in a 2.1 file, because each of those has been replaced. The 2.1 schema also only accepts `"csaf_version": "2.1"`, so any parser that validates the version will reject the file before it gets that far.

This guide is for engineers who ingest vendor CSAF VEX or advisory files into a scanner, SBOM pipeline or ticketing flow. It lists what changed between the two official JSON schemas, how vendors are told to run both versions in parallel, and which tools read 2.1 today. Everything below comes from the [OASIS CSAF TC repository](https://github.com/oasis-tcs/csaf) at commit `e8fdccc7` (18 November 2026). Where we ran code against those files, we say so.

**Status:** The repository's rendered 2.1 prose is headed "Committee Specification 01" and dated 9 November 2026. That is a TC-approved stage, not yet an OASIS Standard, so text can still change. CSAF 2.0 remains the current standard.

## The field-level diff

We walked both schemas (`csaf_2.0/json_schema/csaf_json_schema.json` and `csaf_2.1/json_schema/csaf.json`) with a short Python script. It resolves `$ref`s and compares property names and enums at every path. These are the changes a consumer has to handle:

| CSAF 2.0 path | CSAF 2.1 path | What to change in your parser |
|---|---|---|
| `document.csaf_version` enum `["2.0"]` | const `"2.1"` | Branch on the version before parsing anything else |
| no `$schema` property | required, const `https://docs.oasis-open.org/csaf/csaf/v2.1/schema/csaf.json` | Use it to choose the schema to validate against |
| `vulnerabilities[].scores[]` (`cvss_v2`, `cvss_v3`, `products`) | `vulnerabilities[].metrics[]` (`content`, `products`, `source`) | Read `content.cvss_v4`, `content.epss`, `content.ssvc_v2`, `content.qualitative_severity_rating` as well as v2/v3 |
| `product_tree.relationships[]` (`product_reference`, `relates_to_product_reference`, `category`) | `product_tree.product_paths[]` (`beginning_product_reference`, `subpaths[].next_product_reference`, `subpaths[].category`) | Rewrite product-ID resolution (see below) |
| `vulnerabilities[].cwe` (one object) | `vulnerabilities[].cwes[]` with `id`, `name`, `version` | Treat CWE as a list |
| `vulnerabilities[].release_date` | `vulnerabilities[].disclosure_date` | Rename |
| `vulnerabilities[].involvements[]` | `document.involvement` (`actions`, `entities`, `entity_groups`) | Coordination history moves to document level |
| — | `vulnerabilities[].first_known_exploitation_dates[]` | New exploitation signal per product |
| `product_status` (8 groups) | adds `unknown` | Map it explicitly; don't let it fall through |
| remediation `category` (5 values) | adds `fix_planned`, `optional_patch` | Map both; see the next section |
| `document.distribution.tlp.label` incl. `WHITE` | `CLEAR`, `AMBER+STRICT` added, `WHITE` removed | TLP v2.0 labels |
| `document.publisher.contact_details` (string) | `document.publisher.contact` (`details`, `email`, `public_openpgp_key_url`, `url`) | Rename and restructure |
| branch `category` incl. `legacy` | `legacy` removed, `platform` added | |
| — | `x_extensions` at document, vulnerability and product level | Ignore unknown extensions rather than failing |

`document.notes`, `vulnerabilities[].notes` and `vulnerabilities[].ids` can now also carry `product_ids` and `group_ids`. A note or an ID can therefore apply to only some of the products in the file.

### product_paths replaces relationships

This matters most if you follow our [CSAF VEX product_tree guide](/posts/csaf-vex-product-tree-product-status-purl-sbom-matching/) to resolve product IDs to purls. In 2.0, a relationship joined two references. The CS01 converter rules say how that maps to 2.1: "The value of `product_reference` is set as the value of `beginning_product_reference`." The first `subpaths` item then gets the old `category` and takes `relates_to_product_reference` as its `next_product_reference`.

So the 2.0 relationship "component X is `default_component_of` platform Y" becomes a path that starts at X with one hop to Y. The new combined product ID still lives in `full_product_name.product_id`. In the TC's converted Red Hat example (`rhsa-2022_0011.json`), IDs such as `7Server-7.6.AUS:telnet-1:0.17-65.el7_6.x86_64` survive unchanged. Only the structure around them moves.

A 2.1 path can hold several subpaths, so one product path can describe a chain rather than a single pair.

## Remediations: the change that affects tickets

CSAF 2.1 adds two remediation categories. It also prohibits combinations that 2.0 allowed, and that is the change most likely to show up in your triage numbers.

The CS01 definitions:

- **`optional_patch`**: a patch from the product's author whose "application is not necessary, but might be desired by the user, e.g. to calm a security scanner". Unless noted otherwise, "it is assumed that this does not change the state regarding the vulnerability."
- **`fix_planned`**: "there is a fix for the vulnerability planned but not yet ready." The `details` field SHOULD give a date when customers can expect the fix.

The spec adds a table of remediation categories and the product-status groups they may appear with. A mandatory test, 6.1.36 "Contradicting Product Status Remediation Combination", enforces the prohibited cells. Among them:

| Remediation | Not Affected | Fixed | Affected |
|---|---|---|---|
| `vendor_fix` | prohibited | prohibited | allowed |
| `optional_patch` | allowed | discouraged | prohibited |
| `fix_planned` | discouraged | prohibited | allowed |
| `none_available` | prohibited | prohibited | allowed |

In plain terms, a 2.1 file can no longer say "vendor fix" against a product it also lists as fixed or not affected. A patch offered for a not-affected product has to be `optional_patch`. For a [VEX consumer](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/), that is useful: `optional_patch` on a `known_not_affected` product is a hygiene update, not a fix ticket.

Our [CSAF remediations and threats post](/posts/csaf-vex-remediations-threats-category-product-ids-trivy/) covers the 2.0 categories and how they map to ticket actions. Under 2.1, add two rules:

1. `fix_planned` means "affected, no fix yet". Open or keep the ticket, and record the date from `details`.
2. `optional_patch` means "no exposure change". Do not raise priority because of it.

### What the converter does to old vendor_fix entries

The CS01 "CSAF 2.0 to CSAF 2.1 Converter" conformance clause sets the migration rules. Of a `vendor_fix` on a product in the Not Affected or Fixed group, it says the converter "SHALL convert" it "into the category `optional_patch`". It turns `none_available` into `fix_planned` if the same product also has a `vendor_fix` with a future date or no date. And if a `csaf_security_advisory` can't be made valid under 2.1, the converter "SHALL set the `category` value to `csaf_deprecated_security_advisory`". The spec says that profile "matches the definition of profile 'Security Advisory' in CSAF 2.0."

So expect to see `csaf_deprecated_security_advisory` in real feeds. Treat it as a 2.0-era advisory, not as a withdrawal. The TC's own examples show this. Three of the six converted non-VEX advisories in `csaf_2.1/examples/csaf/` (the Red Hat RHSA-2021:5186, 2021:5217 and 2022:0011 files) carry that category.

## A check you can run: schema plus test 6.1.36

We validated every 2.1 example in the TC repository offline against the CS01 schema. We used Python `jsonschema` 4.26 with a `referencing` registry that maps the FIRST CVSS and CERT/CC SSVC schema URLs to the copies in `csaf_2.1/referenced_schema/`. We also ran our own port of mandatory test 6.1.36. The port is illustrative: it covers that one test, not the full 2.1 test suite. Its core:

```python
# Port of CSAF 2.1 CS01 mandatory test 6.1.36 (illustrative; Python 3.13)
GROUP = {"first_affected": "Affected", "known_affected": "Affected", "last_affected": "Affected",
         "known_not_affected": "Not Affected", "first_fixed": "Fixed", "fixed": "Fixed",
         "under_investigation": "Under Investigation", "unknown": "Unknown", "recommended": "Recommended"}
PROHIBITED = {"workaround": {"Not Affected", "Fixed"}, "mitigation": {"Not Affected", "Fixed"},
              "vendor_fix": {"Not Affected", "Fixed"}, "optional_patch": {"Affected"},
              "none_available": {"Not Affected", "Fixed"}, "fix_planned": {"Fixed"},
              "no_fix_planned": {"Fixed"}}

def test_6_1_36(doc):
    groups = {g["group_id"]: g["product_ids"] for g in doc.get("product_tree", {}).get("product_groups", [])}
    failures = []
    for i, v in enumerate(doc.get("vulnerabilities", [])):
        status = {}
        for key, ids in v.get("product_status", {}).items():
            for pid in ids:
                status.setdefault(pid, set()).add(GROUP[key])
        for j, r in enumerate(v.get("remediations", [])):
            ids = set(r.get("product_ids", []))
            for gid in r.get("group_ids", []):
                ids |= set(groups.get(gid, []))
            for pid in ids:
                if status.get(pid, set()) & PROHIBITED[r["category"]]:
                    failures.append((i, j, r["category"], pid))
    return failures
```

Results across the 20 example files (6 advisories, 14 VEX):

- All 20 validate against the CS01 schema with zero errors.
- All 14 `csaf_vex` examples pass the 6.1.36 port.
- The three files marked `csaf_deprecated_security_advisory` fail it: 6, 1 and 15 product-level hits. Each is a `vendor_fix` on a product also listed as fixed or known_not_affected. That is the pattern the converter can't resolve without guessing, which is consistent with those files being downgraded rather than converted.

The point for your pipeline: once you accept 2.1, run 6.1.36 (or a validator that implements it) before you act on remediations. A contradicting file tells you the vendor's data needs human review.

## Two versions in parallel: provider-metadata.json paths

The CS01 section "Transition between CSAF 2.0 and CSAF 2.1" describes how a provider SHOULD run both versions during migration. The provider announces three dates: when 2.1 serving begins, a roll-over date when 2.1 becomes authoritative, and an end date after which 2.0 is no longer maintained.

| Path | Content |
|---|---|
| `/.well-known/csaf/v2.0/provider-metadata.json` | 2.0 metadata, `canonical_url` pointing at this path |
| `/.well-known/csaf/v2.1/provider-metadata.json` | 2.1 metadata, optional `maintained_from` |
| `/.well-known/csaf/provider-metadata.json` | equal to the v2.0 file until roll-over, then equal to the v2.1 file; "Redirects SHALL NOT be used" (a symlink is allowed) |
| `/.well-known/csaf/archive/v2.0.tar.zst` (or `.tar.bz2`, `.tar.xz`) | optional archive of retired 2.0 documents, with a hash |

Both versioned URLs SHALL also be listed in `security.txt` if the provider uses one. 2.1 provider metadata adds `maintained_from` and `maintained_until`. 2.0 had neither, so you can't read an end date from a 2.0 metadata file. Aggregators follow the same pattern under `/.well-known/csaf-aggregator/`, and "A CSAF 2.1 aggregator SHALL only sync and list CSAF 2.1 publishers and providers."

For a downloader, this means one rule. If you need a specific version, ask for the versioned path. Don't rely on the unversioned one, because its content will change under you on the roll-over date.

## Which tools read 2.1 today

| Tool | Version checked | CSAF 2.1 |
|---|---|---|
| gocsaf (`csaf_downloader`, `csaf_validator`, `csaf_provider`) | v5.0.0-pre.1 (tag dated 5 Nov 2026) | Yes. README: "Version 5 adds support for CSAF 2.1 alongside CSAF 2.0". Downloader takes `--csaf_version=2.0` or `2.1` and warns when `maintained_until` is within 90 days; remote validation is 2.0 only |
| gocsaf | v3.7.1 (latest stable tag) | No. The library defines only `CSAFVersion20 = "2.0"` |
| Trivy | v0.76.2 | No. It decodes CSAF VEX with gocsaf v3.7.0, which rejected a 2.1 file in our [21 November test](/posts/csaf-vex-remediations-threats-category-product-ids-trivy/) |

We read the gocsaf source and docs at the v5 tag. We didn't run the v5 binaries.

The gocsaf v5 downloader docs say it uses "the first valid `provider-metadata.json` that is found from well-known URL, security.txt or DNS in that order without version specificity". By default it rejects documents whose `csaf_version` doesn't match the metadata version. During a vendor's transition, pin `--csaf_version` if your downstream tooling only understands one version.

## What to do now

1. **Branch on `csaf_version` first.** Route `2.1` files to a 2.1 parser, or quarantine them, rather than letting a 2.0 parser read them and silently drop scores.
2. **Read `metrics[]`, not just CVSS.** 2.1 files can carry a vendor's EPSS and SSVC values next to CVSS v4. Feed them into the same decision flow you use for CVE-level signals. Our [prioritization workflow from CVE record to ticket](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/) shows where each one fits.
3. **Map `unknown`, `fix_planned` and `optional_patch` explicitly.** Unknown status is not the same as not affected.
4. **Run test 6.1.36 before acting on remediations.** Contradictions mean manual review.
5. **Pin versioned metadata URLs** for scheduled downloads during vendor transitions.
6. **Expect `csaf_deprecated_security_advisory`.** Handle it like a 2.0 security advisory.

## Limits of this article

- CSAF 2.1 is at Committee Specification 01. Field names and test numbers could change before it becomes an OASIS Standard.
- Our schema diff compares property names and enums. It does not cover every pattern, `minItems` or format change; read the schemas before you ship a validator.
- Our test port covers one mandatory test out of many. It is not a conformant CSAF validator.
- We haven't checked which vendors publish 2.1 files in production today.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| 2.1 prose is "Committee Specification 01", dated 09 November 2026 | [csaf-v2.1-draft.md (rendered CS01) in oasis-tcs/csaf](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.1/prose/share/csaf-v2.1-draft.md) | Verified (TC repository; OASIS publication page not checked) |
| Field renames, new enums, removed `legacy` and `WHITE` | [CSAF 2.1 csaf.json](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.1/json_schema/csaf.json) vs [CSAF 2.0 schema](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/json_schema/csaf_json_schema.json) | Verified by our schema diff |
| optional_patch / fix_planned definitions, remediation-status table, test 6.1.36 | CS01 prose, vulnerabilities property and mandatory tests sections | Verified (verbatim) |
| Converter rules: vendor_fix to optional_patch, deprecated category, relationships to product_paths, default TLP:CLEAR | CS01 Conformance Clause 18 | Verified (verbatim) |
| Transition paths, no redirects, aggregator rule | CS01 "Transition between CSAF 2.0 and CSAF 2.1" | Verified (verbatim) |
| 20 examples validate; 3 deprecated files fail the 6.1.36 port (6, 1, 15 hits) | Our run against [csaf_2.1/examples/csaf](https://github.com/oasis-tcs/csaf/tree/master/csaf_2.1/examples/csaf) at commit e8fdccc7 | Verified (our test) |
| gocsaf v5.0.0-pre.1 supports 2.1; v3.7.1 is 2.0 only | [gocsaf/csaf](https://github.com/gocsaf/csaf) README and `csaf/advisory.go` at those tags | Verified (source read, binaries not run) |
