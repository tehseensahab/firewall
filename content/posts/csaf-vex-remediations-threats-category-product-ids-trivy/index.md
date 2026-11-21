+++
title = "CSAF VEX Remediations and Threats: What Trivy Gets Wrong"
date = 2026-11-21T04:30:00Z
tags = ["csaf", "csaf vex", "vex", "trivy", "gocsaf", "vulnerability management", "sbom"]
categories = ["appsec"]
summary = "CSAF 2.0 puts the fix, the workaround, the restart cost and the reason a product is not affected in two arrays: remediations and threats. Here is what each field means, how to resolve them per product, and three places where Trivy v0.76.2 and gocsaf v3.7.0 diverge from the spec."
description = "CSAF VEX remediations and threats: 5 remediation categories, restart_required, impact threats per product, and why Trivy v0.76.2 rejects product_groups."
author = "Craig Leslie"
imageAlt = "A set of chrome combination wrenches in a black rack, lying on rusty metal in a sunlit workshop"
imageCredit = "Photo by [David Thielen](https://unsplash.com/photos/3lbyg_6ApHQ) on Unsplash"
takeaways = [
  "In CSAF 2.0, remediations and threats each need a category and details, plus product_ids or group_ids to say which products they apply to. A remediation with neither fails mandatory test 6.1.29.",
  "Remediation category has five values in CSAF 2.0: vendor_fix, workaround, mitigation, none_available and no_fix_planned. vendor_fix cannot sit alongside none_available or no_fix_planned for the same product.",
  "Threat category impact is where a CSAF VEX file explains why a known_not_affected product is not affected, if it does not use a flag. Resolve it per product: one vulnerability can carry several impact threats.",
  "Trivy v0.76.2 records the first impact threat in a vulnerability as the statement for every product it filters, whatever that threat's product_ids say, and never reads remediations.",
  "Trivy decodes CSAF with gocsaf v3.7.0, which models product_tree.product_groups as an object, not the array the schema requires. In our test, a schema-valid CSAF 2.0 file with product_groups failed to decode, and Trivy's loader returns that error instead of applying the file."
]

[[faq]]
q = "What are the CSAF remediation categories?"
a = "CSAF 2.0 defines five: vendor_fix (an official fix from the product's author), workaround (a configuration or deployment change that avoids exposure), mitigation (reduces risk without resolving the flaw), none_available (no fix or remediation yet) and no_fix_planned (no fix will ever be provided). The CSAF 2.1 Committee Specification adds fix_planned and optional_patch."

[[faq]]
q = "Where does a CSAF VEX file explain why a product is not affected?"
a = "For each product in known_not_affected, the VEX profile requires either a machine-readable flag in vulnerabilities[].flags or a threat with category impact whose details say why the vulnerability cannot be exploited. Check that the flag or threat lists that product, directly or through a product group."

[[faq]]
q = "Does Trivy use CSAF remediations?"
a = "No. In Trivy v0.76.2 the CSAF matcher acts only on known_not_affected and fixed in product_status. It reads threats only to copy the first impact threat's details into the modified finding. Remediations, including vendor_fix URLs and restart_required, are never read."

[[faq]]
q = "Why does Trivy fail to load my CSAF VEX file?"
a = "Three causes we reproduced against gocsaf v3.7.0, the library Trivy v0.76.2 uses: the file uses product_tree.product_groups, which gocsaf expects as an object rather than an array; the file declares csaf_version 2.1; or a remediation uses a CSAF 2.1 category such as fix_planned. Each makes JSON decoding fail."
+++

**Short answer:** In a CSAF 2.0 VEX document, `product_status` says *whether* each product is affected. Two arrays under each vulnerability say *what to do about it*: **`remediations`** (category, details, date, URL, entitlements, restart cost) and **`threats`** (impact, exploit status, target set). Both apply to products only through their own `product_ids` or `group_ids`, so you have to resolve them per product. Trivy v0.76.2 does not: it ignores remediations, takes the first `impact` threat for every product it filters, and, through the gocsaf v3.7.0 library, fails to decode any file that uses `product_groups`.

If you consume CSAF VEX from a vendor such as Red Hat or from an internal team, these two arrays are where the patch-or-wait decision lives. This article reads the [CSAF 2.0 specification](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/prose/csaf-v2-editor-draft.md) and [JSON schema](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/json_schema/csaf_json_schema.json), [Trivy v0.76.2](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/csaf.go) and [gocsaf v3.7.0](https://github.com/gocsaf/csaf/blob/v3.7.0/csaf/advisory.go), the version pinned in Trivy's go.mod. For resolving product IDs to purls first, see [CSAF VEX product_tree](/posts/csaf-vex-product-tree-product-status-purl-sbom-matching/); this piece picks up where that one stops.

## Remediations: the fields

Every remediation item has two mandatory properties, `category` and `details`. The spec adds: "At least one of the optional elements Group IDs (`group_ids`) and Product IDs (`product_ids`) MUST be present to state for which products or product groups this remediation is applicable." A remediation with neither fails mandatory test 6.1.29, *Remediation without Product Reference*.

| Field | Type | What it tells you |
|---|---|---|
| `category` | enum (required) | What kind of action this is (table below) |
| `details` | string (required) | "a thorough human-readable discussion of the remediation" |
| `product_ids` / `group_ids` | ID lists | Which products the remediation covers; at least one must be present |
| `date` | date-time | "the date from which the remediation is available" |
| `url` | URI | "the URL where to obtain the remediation" |
| `entitlements` | string list | "vendor-defined constraints for obtaining fixed software or hardware", such as a support contract |
| `restart_required` | object | `category` (required) and `details`: what must restart for the remediation to take effect |

### The five remediation categories

| `category` | Spec meaning (CSAF 2.0, 3.2.3.12.1) | Ticket action |
|---|---|---|
| `vendor_fix` | "an official fix that is issued by the original author of the affected product. Unless otherwise noted, it is assumed that this fix fully resolves the vulnerability." | Schedule the upgrade; use `url` and `date` |
| `workaround` | a configuration or deployment scenario "that can be used to avoid exposure to the vulnerability" | Apply now, keep the ticket open for the fix |
| `mitigation` | "helps to reduce the risk of the vulnerability but that does not resolve the vulnerability on the affected product" | Compensating control; the finding stays open |
| `none_available` | "there is currently no fix or other remediation available" | Track; the spec suggests the issuer include an expected date |
| `no_fix_planned` | no fix "and it is not planned to provide one at any time", often for end-of-life products | Replace, isolate or accept the risk |

Two consistency rules matter for parsers. `vendor_fix` "contradicts with the categories `none_available` and `no_fix_planned` for the same product", so a document should never carry both for one product. And the difference between `workaround` and `mitigation` is the difference between "avoids exposure" and "reduces risk": do not close a finding on a mitigation.

### restart_required

This is the field operations teams want and scanners rarely show. CSAF 2.0 defines nine values: `none`, `vulnerable_component`, `service`, `parent`, `dependencies`, `connected`, `machine`, `zone` and `system`. They escalate from "No restart required" through `machine` ("This is the value which SHOULD be used if an OS needs to be restarted") to `system`, a restart of "the whole system", which "MAY include multiple security zones". If you build change tickets automatically, map `machine`, `zone` and `system` to a maintenance window rather than a rolling restart.

## Threats: impact, exploit_status, target_set

Threat items also need `category` and `details`, take optional `date`, `product_ids` and `group_ids`, and describe information that "can change as the vulnerability ages". There are three categories:

- **`impact`**: an assessment of the impact if the vulnerability is exploited "or a description why it cannot be exploited".
- **`exploit_status`**: "the degree to which an exploit for the vulnerability is known", which the spec says can mirror CVSS exploitability or use a contextual status such as "Weaponized".
- **`target_set`**: "the currently known victim population", for example platform, product type, user segment or geography.

For threats, `date` is "the date when the assessment was done or the threat appeared", so an old `exploit_status` is a reason to check [KEV](/posts/cisa-kev-json-feed-what-each-field-means-and-how-to-match-it-against-a-scanner-export/) and EPSS rather than trust it.

### What the VEX profile requires

The `csaf_vex` profile (section 4.5) ties both arrays to product status:

- Every product in `known_not_affected` needs an impact statement, "as machine readable flag in `/vulnerabilities[]/flags` or as human readable justification in `/vulnerabilities[]/threats`". For a threat, "the `category` value for such a statement MUST be `impact`".
- Every product in `known_affected` needs "additional product specific information" in `remediations` "as an action statement". `no_fix_planned` and `none_available` are allowed.
- Group IDs may be used, but "it MUST be ensured that for each Product ID the required information according to its product status as stated in the two points above is available".

That last sentence is the important one: the requirement is per product. A vulnerability can, and in multi-product advisories usually does, carry several impact threats with different `product_ids`.

## Resolving remediations and threats per product

The file below is an illustrative CSAF 2.0 VEX document: one CVE (a placeholder ID, CVE-2099-0001), two container images, one product group. `example-worker` is affected and has a vendor fix; `example-api` is not affected, and its impact threat says why. It validates with zero errors against the CSAF 2.0 JSON schema (Python `jsonschema`, with the FIRST CVSS schemas the CSAF repository ships under `csaf_2.0/referenced_schema`).

```json
"product_groups": [
  {"group_id": "CSAFGID-ALL", "product_ids": ["CSAFPID-API", "CSAFPID-WORKER"]}
],
...
"product_status": {
  "known_affected": ["CSAFPID-WORKER"],
  "known_not_affected": ["CSAFPID-API"]
},
"threats": [
  {"category": "impact", "product_ids": ["CSAFPID-WORKER"],
   "details": "example-worker parses uploaded XML with libexample; a crafted file can crash the worker."},
  {"category": "impact", "product_ids": ["CSAFPID-API"],
   "details": "example-api ships libexample but never calls its XML parser."},
  {"category": "exploit_status", "group_ids": ["CSAFGID-ALL"],
   "details": "No public exploit known to Example Corp.", "date": "2026-11-21T00:00:00Z"}
],
"remediations": [
  {"category": "vendor_fix", "product_ids": ["CSAFPID-WORKER"],
   "details": "Upgrade to example-worker 1.8.1.", "date": "2026-11-21T00:00:00Z",
   "url": "https://example.com/releases/worker-1.8.1",
   "restart_required": {"category": "service", "details": "Restart the worker deployment."}},
  {"category": "mitigation", "group_ids": ["CSAFGID-ALL"],
   "details": "Reject XML uploads at the gateway until upgraded."}
]
```

This Python 3 script (standard library only) expands `group_ids` and prints, for each product and status, the threats and remediations that actually apply to it:

```python
import json, sys

def expand(item, groups):
    ids = set(item.get("product_ids", []))
    for g in item.get("group_ids", []):
        ids |= set(groups.get(g, []))
    return ids

doc = json.load(open(sys.argv[1]))
groups = {g["group_id"]: g["product_ids"]
          for g in doc["product_tree"].get("product_groups", [])}

for vuln in doc["vulnerabilities"]:
    status = vuln.get("product_status", {})
    for state in ("known_affected", "known_not_affected", "fixed", "under_investigation"):
        for pid in status.get(state, []):
            rem = [r for r in vuln.get("remediations", []) if pid in expand(r, groups)]
            thr = [t for t in vuln.get("threats", []) if pid in expand(t, groups)]
            print(f"{vuln.get('cve')} {pid} {state}")
            for t in thr:
                print(f"  threat  {t['category']:<15} {t['details']}")
            for r in rem:
                restart = r.get("restart_required", {}).get("category", "-")
                print(f"  remedy  {r['category']:<15} date={r.get('date', '-')} restart={restart}")
```

Run against the full example file, it prints:

```text
CVE-2099-0001 CSAFPID-WORKER known_affected
  threat  impact          example-worker parses uploaded XML with libexample; a crafted file can crash the worker.
  threat  exploit_status  No public exploit known to Example Corp.
  remedy  vendor_fix      date=2026-11-21T00:00:00Z restart=service
  remedy  mitigation      date=- restart=-
CVE-2099-0001 CSAFPID-API known_not_affected
  threat  impact          example-api ships libexample but never calls its XML parser.
  threat  exploit_status  No public exploit known to Example Corp.
  remedy  mitigation      date=- restart=-
```

The script reads only `product_ids` and `group_ids` on plain products. Products defined through `relationships` need the full-product-name resolution described in the [product_tree article](/posts/csaf-vex-product-tree-product-status-purl-sbom-matching/) first. Treat it as a starting point, not a complete CSAF consumer.

## Where Trivy v0.76.2 diverges

Trivy is a common first consumer of CSAF VEX files. Reading its source at v0.76.2, and running the same decoding path against the files above, shows three gaps. We could not run Trivy itself in our build environment; instead we compiled gocsaf v3.7.0's `csaf` package from its source files, unmodified, and called it the way Trivy's `decodeCSAF` does (`json.NewDecoder(r).Decode(&adv)`), together with a Go port of Trivy's `statement()` function.

### 1. Files with product_groups do not decode

The CSAF 2.0 schema defines `product_tree.product_groups` as `"type": "array"` of group objects. gocsaf v3.7.0 declares the field as `ProductGroups *ProductGroups`, where `ProductGroups` is a struct with a `product_group_ids` list. Decoding the schema-valid example fails:

```text
decode error: json: cannot unmarshal array into Go struct field ProductTree.product_tree.product_groups of type csaf.ProductGroups
```

In Trivy, `decodeVEX` collects that error, `NewDocument` returns it as "unable to load VEX from file", and the VEX filter wraps it as a "VEX error". None of the file's statements are applied. The struct is unchanged in gocsaf v3.7.1 and on the main branch as of November 21, 2026, and Trivy's main branch still pins v3.7.0. Until that changes, a workaround is to expand groups into `product_ids` before handing the file to Trivy; the same document with groups expanded decoded cleanly.

### 2. One impact threat for every filtered product

When Trivy filters a finding, it attaches a statement taken by `statement()`, which returns the `details` of the first threat whose category is `impact`, and does not look at that threat's `product_ids`. With groups expanded, our example decodes, and Trivy would filter `example-api` (known_not_affected) with this statement:

```text
example-worker parses uploaded XML with libexample; a crafted file can crash the worker.
```

That is the impact text for the *affected* product, recorded as the justification for suppressing the unaffected one. The suppression itself is correct (it comes from `product_status`), but anyone auditing modified findings reads the wrong reason. Order your impact threats with this in mind if Trivy is your consumer, and do not use Trivy's statement field as your audit record for multi-product files.

### 3. Remediations are never read

Trivy's matcher builds its status map from `known_not_affected` and `fixed` only. `known_affected` findings pass through unchanged, and nothing in `pkg/vex/csaf.go` reads `remediations`. The vendor fix URL, the availability `date`, `entitlements` and `restart_required` never reach the scan output. If you want them in tickets, parse them separately, as above, and join on CVE and product.

## CSAF 2.1 adds two remediation categories

The OASIS CSAF TC's repository now carries CSAF 2.1 prose headed "Committee Specification 01", dated 9 November 2026; it is not yet an OASIS Standard. Its schema has seven remediation categories, adding:

- **`fix_planned`**: "there is a fix for the vulnerability planned but not yet ready". This takes over the "fix is being developed" use that CSAF 2.0 put under `none_available`.
- **`optional_patch`**: a patch from the original author whose "application is not necessary, but might be desired by the user, e.g. to calm a security scanner". The spec adds: "Unless otherwise noted, it is assumed that this does not change the state regarding the vulnerability."

`optional_patch` is the category a vendor would attach to a `known_not_affected` product that still ships a flagged library version. Do not treat it as a `vendor_fix`.

Tooling has not caught up. gocsaf v3.7.0 accepts only `csaf_version` "2.0" and the five 2.0 remediation categories; in our test, a file declaring 2.1 failed with `2.1 not in [2.0]`, and a 2.0 file with a `fix_planned` remediation failed with `fix_planned not in [mitigation|no_fix_planned|none_available|vendor_fix|workaround]`. Both also fail the CSAF 2.0 JSON schema, as expected.

## Common mistakes

- **Applying a remediation to every product in the vulnerability.** Remediations and threats are scoped by their own `product_ids` and `group_ids`, not by `product_status`.
- **Closing a finding on `mitigation` or `workaround`.** Only `vendor_fix` is assumed to resolve the flaw, and only once you have applied it.
- **Forgetting group expansion.** A product named only through a group ID still has its remediation. A parser that reads only `product_ids` misses it.
- **Reading an old exploit_status as current.** Check its `date` against fresher exploitation signals.

## Where this fits

Remediations and threats answer the last questions in the [CVE-record-to-ticket workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/): once VEX tells you a product is affected, what is the fix, when is it available and what will it cost to apply. For the meaning of the VEX statuses themselves, see [VEX explained](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/); for the equivalent OpenVEX fields, see [OpenVEX statement fields](/posts/openvex-statement-fields-status-notes-action-statement-version-trivy/).

## Limits of this article

- The Trivy findings come from reading v0.76.2 source and running gocsaf v3.7.0's decoding code, not from running the Trivy binary. Behaviour in later Trivy releases may differ.
- The example document is illustrative; CVE-2099-0001 and Example Corp are placeholders.
- CSAF 2.1 text is quoted from the TC's Committee Specification 01 draft in the oasis-tcs/csaf repository and may change before it becomes an OASIS Standard.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Remediation and threat fields, required properties, five categories, restart_required values, field meanings | [CSAF 2.0 prose, 3.2.3.12 and 3.2.3.14](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/prose/csaf-v2-editor-draft.md) | Verified |
| VEX profile impact and action statement rules; tests 6.1.27.9, 6.1.27.10, 6.1.29 | Same document, sections 4.5 and 6.1 | Verified |
| product_groups is an array in the schema; example validates | [CSAF 2.0 JSON schema](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/json_schema/csaf_json_schema.json), run with Python jsonschema | Verified (run) |
| Trivy acts on known_not_affected and fixed; statement() takes first impact threat; decodeCSAF uses json.Decoder | [Trivy v0.76.2 pkg/vex/csaf.go](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/csaf.go), [document.go](https://github.com/aquasecurity/trivy/blob/v0.76.2/pkg/vex/document.go) | Verified (source) |
| Trivy pins gocsaf v3.7.0; ProductGroups is a struct; version and category enums | [Trivy go.mod](https://github.com/aquasecurity/trivy/blob/v0.76.2/go.mod), [gocsaf v3.7.0 advisory.go](https://github.com/gocsaf/csaf/blob/v3.7.0/csaf/advisory.go) | Verified (source, run) |
| CSAF 2.1 CS01 dated 9 November 2026; fix_planned and optional_patch text | [oasis-tcs/csaf csaf_2.1 prose](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.1/prose/share/csaf-v2.1-draft.md) | Qualified (Committee Specification, not OASIS Standard) |
