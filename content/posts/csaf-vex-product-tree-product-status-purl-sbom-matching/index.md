+++
title = "CSAF VEX product_tree: Resolve Product IDs to SBOM purls"
date = 2026-11-05T04:30:00Z
tags = ["csaf", "vex", "csaf vex", "sbom", "purl", "vulnerability management", "trivy", "security operations"]
categories = ["security-operations"]
summary = "A CSAF VEX file never puts a purl next to a status. Product IDs in product_status point into the product_tree, often through relationships. Here is how to walk branches and relationships, collapse the eight status lists into four VEX answers, and join the result to a CycloneDX SBOM, with a tested Python script."
description = "CSAF VEX product_status lists hold product IDs, not purls. Walk product_tree branches and relationships to purls, then join to your SBOM. Tested Python inside."
author = "John Marshall"
imageAlt = "Thin bare tree branches crossing in a dense tangle against a flat grey-blue sky"
imageCredit = "Photo by [BehindTheTmuna](https://unsplash.com/photos/bare-tree-branches-against-a-gray-sky-sUzKJEfi-dg) on Unsplash"
takeaways = [
  "In CSAF 2.0, product_status holds product IDs. The purl that lets you match your SBOM lives in the product_tree, under branches, full_product_names or relationships, in product_identification_helper.",
  "A relationship such as default_component_of creates a new product ID that means \"this component inside that product\". A status on that ID should only apply when both the component and the parent product match your inventory.",
  "CSAF defines eight product_status lists. For a VEX decision, collapse them to four: affected (first_affected, known_affected, last_affected), not affected, fixed (first_fixed, fixed) and under investigation. Treat recommended as a pointer, not a status.",
  "The VEX profile requires an impact statement (a flag or an impact threat) for every known_not_affected product and an action statement in remediations for every known_affected product. Missing ones mean the file does not satisfy the profile.",
  "Trivy v0.76.1 applies only known_not_affected and fixed from CSAF, matches by purl, and treats default_component_of, installed_on and installed_with the same way. known_affected and under_investigation entries never change its output."
]

[[faq]]
q = "What is the difference between CSAF and CSAF VEX?"
a = "CSAF 2.0 is the OASIS standard for machine-readable security advisories. CSAF VEX is one of its profiles: a CSAF document whose document.category is csaf_vex and which carries a product tree, vulnerabilities with notes and a CVE or other ID, and at least one fixed, known_affected, known_not_affected or under_investigation status, plus impact and action statements where the profile requires them."

[[faq]]
q = "Where is the purl in a CSAF VEX file?"
a = "In the product tree. Each full product name, whether it sits at the end of a branch, in full_product_names or inside a relationship, can carry product_identification_helper.purl. The vulnerability's product_status lists only reference product IDs, so you have to resolve each ID back to its product tree entry."

[[faq]]
q = "Does Trivy use known_affected from a CSAF VEX document?"
a = "No. In Trivy v0.76.1 the CSAF matcher builds its status map from known_not_affected and fixed only. A match on either removes the finding; known_affected and under_investigation statements leave the scanner result as it was."

[[faq]]
q = "Why does a CSAF VEX statement match the wrong products?"
a = "Usually because a status was attached to a bare component ID instead of a relationship ID, or because the consumer matched only the component purl and ignored the parent product. A not_affected statement on a component alone reads as true for that component in every product, which is rarely what the vendor meant."
+++

**Scope.** This is a field-level guide for engineers who consume vendor CSAF VEX files and need to apply them to their own SBOMs. We read the CSAF 2.0 prose and JSON schema in the OASIS CSAF TC's GitHub repository, Red Hat's July 2024 announcement of its CSAF VEX files, and Trivy's CSAF matcher and documentation at tag v0.76.1. The example document and the Python script below are ours; we validated the document against the CSAF 2.0 JSON schema and ran the script with Python 3.13. The script is illustrative, not a production matcher.

## The short answer

A CSAF VEX file never puts a purl next to a status. It says "product ID `GW-4.2.1:LIB-1.8.0` is `known_not_affected`", and you have to work out what that ID is:

1. Find the ID in the `product_tree`: at the end of a `branches` path, in `full_product_names`, or as the `full_product_name` of a `relationships` entry.
2. If it is a relationship, resolve both sides: `product_reference` (the component) and `relates_to_product_reference` (the product it sits in).
3. Read `product_identification_helper.purl` (or `cpe`) for each side.
4. Apply the status only when your SBOM contains the component **and** the parent matches the product you are assessing.
5. Collapse the eight `product_status` lists to the four VEX answers before you write anything to a ticket.

The rest of this article goes through each step, shows a schema-valid example, and gives a script that does the join.

## What the VEX profile requires

CSAF 2.0 has been an OASIS Standard since 18 November 2022. The VEX profile is section 4.5. A document satisfies it when `/document/category` is `csaf_vex` and it contains:

- a `product_tree` "which lists all products referenced later on in the CSAF document regardless of their state";
- `vulnerabilities`, each with `notes` and at least one of `cve` or `ids`;
- at least one of the `fixed`, `known_affected`, `known_not_affected` or `under_investigation` lists.

Two conditions are per product, and they are the ones consumers should check:

- Every product in `known_not_affected` needs an impact statement, either "as machine readable flag in `/vulnerabilities[]/flags` or as human readable justification in `/vulnerabilities[]/threats`" with `category` set to `impact`.
- Every product in `known_affected` needs "additional product specific information" in `remediations` "as an action statement". The categories `no_fix_planned` and `none_available` count.

The five flag labels are the CISA justification codes: `component_not_present`, `vulnerable_code_not_present`, `vulnerable_code_cannot_be_controlled_by_adversary`, `vulnerable_code_not_in_execute_path` and `inline_mitigations_already_exist`. If you need the meaning of each one, the [VEX explainer](/posts/vex-explained-what-a-not-affected-statement-means-and-how-to-read-one/) covers them. The [CycloneDX VEX mapping guide](/posts/cyclonedx-vex-analysis-state-justification-openvex-csaf-mapping/) covers converting between CSAF and other VEX formats. This article is about something they do not cover: finding the products a CSAF statement actually refers to.

## Step 1: walk the product tree

The `product_tree` can name products in three places. A consumer has to read all three.

| Where | What it holds | Product ID comes from |
|---|---|---|
| `branches` (nested) | A hierarchy such as `vendor` → `product_name` → `product_version`. A leaf branch has a `product` object. | `branches[]...product.product_id` |
| `full_product_names` | Flat list of products with no hierarchy | `full_product_names[].product_id` |
| `relationships` | A new product made of two existing ones, such as a library inside an image | `relationships[].full_product_name.product_id` |

Every one of these is a "full product name": `name` and `product_id` are required, and `product_identification_helper` is optional. That helper is where `purl`, `cpe`, hashes and SBOM URLs go. The CSAF schema only checks the purl against a loose pattern (`^pkg:[A-Za-z\.\-\+][A-Za-z0-9\.\-\+]*/.+`) and says it "does not completely evaluate whether a PURL is valid", so validate purls yourself before matching on them.

There is also `product_groups`, which bundles product IDs under a group ID. Product status lists only hold product IDs, but `flags`, `threats` and `remediations` can reference groups through `group_ids`, so expand groups when you collect impact and action statements.

The spec recommends the `vendor` → `product_name` → `product_version` shape "whenever possible to support the identification and matching of products on the consumer side". It also allows `product_version_range` branches, but recommends enumerating versions instead. If you meet a range branch, you need a version-range parser for whatever scheme it uses; the purl join below will not help.

## Step 2: treat relationships as "component in product"

A relationship has four required fields: `category`, `product_reference`, `relates_to_product_reference` and `full_product_name`. The categories are `default_component_of`, `external_component_of`, `installed_on`, `installed_with` and `optional_component_of`. The spec gives the reason relationships exist: a product may be "vulnerable only when installed together with another", or you may need "to describe operating system components".

This is the part consumers get wrong. In our example below, `LIB-1.8.0` is the library on its own and `GW-4.2.1:LIB-1.8.0` is "libexample 1.8.0 as shipped in Example Gateway 4.2.1". A vendor that marks the second ID `known_not_affected` is saying the gateway does not reach the vulnerable code. It is not saying libexample 1.8.0 is safe everywhere. If your matcher resolves the relationship ID to the component purl alone, you will suppress the CVE for every other image that ships libexample 1.8.0. That is the false negative VEX is supposed to prevent.

The rule we use: for a relationship ID, apply the status only when the component purl matches a component in the SBOM **and** the parent purl matches the SBOM's subject (for CycloneDX, `metadata.component`).

Red Hat's VEX files are a real case of this structure. Red Hat publishes one CSAF VEX file per CVE. Its July 2024 announcement says each file has a `product_tree` object listing "products, their components, and the relationships between them". In the general-availability release Red Hat "extended the scope of the `purl` identifiers to unfixed components as well" for rpm, oci and rpmmod components. In the October 2023 beta, only fixed components carried a purl. Check which one you are parsing.

## Step 3: collapse eight status lists into four answers

CSAF defines eight `product_status` lists. VEX consumers need four answers. The spec's own test for contradicting statuses (section 6.1.6) gives the grouping, and the sets "MUST be pairwise disjoint" within one vulnerability:

| VEX answer | CSAF `product_status` lists | What to do |
|---|---|---|
| Affected | `first_affected`, `known_affected`, `last_affected` | Open or keep the ticket. Read `remediations` for the action statement. |
| Not affected | `known_not_affected` | Suppress for that product only, and keep the flag or impact text as evidence. |
| Fixed | `first_fixed`, `fixed` | Close if you run that version. The spec says these versions "may not be the recommended fixed versions". |
| Under investigation | `under_investigation` | Keep the scanner finding and re-pull the document later. |
| (none) | `recommended` | Not part of any contradiction group. The spec notes an issuer might recommend a version "from any group - also from the affected group". Use it to choose an upgrade target, not to decide status. |

If you find one product ID in two groups for the same CVE, the document fails the CSAF mandatory test. Reject the statement for that product rather than picking one.

For affected products, the remediation categories tell you what kind of action is available: `vendor_fix`, `workaround`, `mitigation`, `none_available` or `no_fix_planned`. `vendor_fix` cannot be combined with `none_available` or `no_fix_planned` for the same product.

## A schema-valid example

This document is ours, written for this article. It has one product version where a library is not reachable and a later version where it was updated. It passes validation against the CSAF 2.0 JSON schema from the OASIS repository (Python `jsonschema`, Draft 2020-12, format checks on; 0 errors). Schema validation does not run CSAF's mandatory tests, so it does not prove the profile rules are met. We checked those by hand.

```json
{
  "document": {
    "category": "csaf_vex",
    "csaf_version": "2.0",
    "publisher": {"category": "vendor", "name": "Example Vendor", "namespace": "https://vendor.example"},
    "title": "Example Gateway: CVE-2099-0001 in libexample",
    "tracking": {"id": "EXV-2099-0001", "status": "final", "version": "2", "...": "..."}
  },
  "product_tree": {
    "branches": [{"category": "vendor", "name": "Example Vendor", "branches": [
      {"category": "product_name", "name": "Example Gateway", "branches": [
        {"category": "product_version", "name": "4.2.1",
         "product": {"name": "Example Gateway 4.2.1", "product_id": "GW-4.2.1",
           "product_identification_helper": {"purl": "pkg:oci/example-gateway@sha256%3A1111?tag=4.2.1"}}}
      ]},
      {"category": "product_name", "name": "libexample", "branches": [
        {"category": "product_version", "name": "1.8.0",
         "product": {"name": "libexample 1.8.0", "product_id": "LIB-1.8.0",
           "product_identification_helper": {"purl": "pkg:deb/debian/libexample@1.8.0-1"}}}
      ]}
    ]}],
    "relationships": [
      {"category": "default_component_of",
       "product_reference": "LIB-1.8.0",
       "relates_to_product_reference": "GW-4.2.1",
       "full_product_name": {"name": "libexample 1.8.0 in Example Gateway 4.2.1",
                             "product_id": "GW-4.2.1:LIB-1.8.0"}}
    ]
  },
  "vulnerabilities": [{
    "cve": "CVE-2099-0001",
    "notes": [{"category": "description", "text": "Illustrative vulnerability in libexample's XML parser."}],
    "product_status": {"known_not_affected": ["GW-4.2.1:LIB-1.8.0"], "fixed": ["GW-4.3.0:LIB-1.8.2"]},
    "flags": [{"label": "vulnerable_code_not_in_execute_path", "product_ids": ["GW-4.2.1:LIB-1.8.0"]}],
    "threats": [{"category": "impact", "details": "Example Gateway never calls the XML parser in libexample.",
                 "product_ids": ["GW-4.2.1:LIB-1.8.0"]}]
  }]
}
```

The excerpt trims the tracking block and the 4.3.0 / 1.8.2 branches and relationship, which follow the same pattern. The CVE ID is a placeholder.

## Step 4: join to the SBOM

The script resolves every product ID in `product_status` to purls, follows relationships, and checks both sides against a CycloneDX SBOM. For purl comparison it uses the matching rules Trivy documents, which Trivy itself notes "are not formally defined within the current official PURL specification": a VEX purl without a version matches every version; every qualifier in the VEX purl must be present in the SBOM purl; extra SBOM qualifiers are ignored.

```python
#!/usr/bin/env python3
"""Resolve CSAF VEX product_status entries to purls and join them to a CycloneDX SBOM.
Illustrative: purl matching follows the rules in purl_match(); no version-range logic."""
import json, sys
from urllib.parse import unquote

def parse(p):
    """Split a purl into (type/namespace/name, version or None, qualifiers dict). Subpath ignored."""
    p = p.split("#")[0]
    core, _, q = p.partition("?")
    quals = dict(kv.split("=", 1) for kv in q.split("&") if "=" in kv)
    path, _, ver = core.rpartition("@") if "@" in core.rsplit("/", 1)[-1] else (core, "", "")
    return unquote(path).lower(), unquote(ver) or None, {k.lower(): unquote(v) for k, v in quals.items()}

def purl_match(vex_purl, sbom_purl):
    """Community matching rules (as documented by Trivy): a VEX purl without a version matches
    every version; VEX qualifiers must all be present in the SBOM purl; extra SBOM qualifiers are ignored."""
    vp, vv, vq = parse(vex_purl)
    sp, sv, sq = parse(sbom_purl)
    return vp == sp and (vv is None or vv == sv) and all(sq.get(k) == v for k, v in vq.items())

def walk_branches(branches, out):
    for b in branches or []:
        if "product" in b:
            fpn = b["product"]
            out[fpn["product_id"]] = fpn.get("product_identification_helper", {}).get("purl")
        walk_branches(b.get("branches"), out)

def load_products(doc):
    tree = doc["product_tree"]
    purls = {}
    walk_branches(tree.get("branches"), purls)
    for fpn in tree.get("full_product_names", []):
        purls[fpn["product_id"]] = fpn.get("product_identification_helper", {}).get("purl")
    rels = {}
    for r in tree.get("relationships", []):
        rels[r["full_product_name"]["product_id"]] = (
            r["category"], r["product_reference"], r["relates_to_product_reference"])
    groups = {g["group_id"]: g["product_ids"] for g in tree.get("product_groups", [])}
    return purls, rels, groups

def main(vex_path, sbom_path):
    doc = json.load(open(vex_path))
    assert doc["document"]["category"] == "csaf_vex", "not a VEX profile document"
    purls, rels, groups = load_products(doc)
    sbom = json.load(open(sbom_path))
    parent = sbom["metadata"]["component"]["purl"]
    inventory = [c["purl"] for c in sbom.get("components", []) if c.get("purl")]
    in_sbom = lambda vex_purl: any(purl_match(vex_purl, s) for s in inventory)

    for v in doc["vulnerabilities"]:
        flags = {pid: f["label"] for f in v.get("flags", [])
                 for pid in f.get("product_ids", []) + sum((groups[g] for g in f.get("group_ids", [])), [])}
        for status, pids in v.get("product_status", {}).items():
            for pid in pids:
                if pid in rels:                      # component-in-product: match BOTH sides
                    cat, comp, prod = rels[pid]
                    comp_p, prod_p = purls.get(comp), purls.get(prod)
                    hit = bool(comp_p and prod_p and purl_match(prod_p, parent) and in_sbom(comp_p))
                    target = f"{comp_p} {cat} {prod_p}"
                else:                                # standalone product
                    p = purls.get(pid)
                    hit = bool(p and (in_sbom(p) or purl_match(p, parent)))
                    target = p
                print(f"{v.get('cve')}\t{status}\t{flags.get(pid, '-')}\t{'MATCH' if hit else 'no match'}\t{target}")

if __name__ == "__main__":
    main(*sys.argv[1:3])
```

### Test run

We ran it (`python3 -I csaf_vex_join.py vex.json sbom.cdx.json`) against the full example document and three small CycloneDX 1.6 SBOMs.

**SBOM 1**, image 4.2.1 (`metadata.component.purl` = `pkg:oci/example-gateway@sha256%3A1111?tag=4.2.1`), containing `pkg:deb/debian/libexample@1.8.0-1?arch=amd64&distro=debian-12`:

```text
CVE-2099-0001  known_not_affected  vulnerable_code_not_in_execute_path  MATCH     pkg:deb/debian/libexample@1.8.0-1 default_component_of pkg:oci/example-gateway@sha256%3A1111?tag=4.2.1
CVE-2099-0001  fixed               -                                    no match  pkg:deb/debian/libexample@1.8.2-1 default_component_of pkg:oci/example-gateway@sha256%3A2222?tag=4.3.0
```

The SBOM's extra `arch` and `distro` qualifiers did not block the match, because the VEX purl has none.

**SBOM 2**, image 4.3.0 with libexample 1.8.2: the results flip. The `fixed` statement matches and the `known_not_affected` one does not.

**SBOM 3**, the 4.2.1 SBOM again, but with the VEX component purl changed to `...libexample@1.8.0-1?arch=arm64`: `no match`, because the VEX purl now requires a qualifier value the SBOM lacks.

What the script does not do: version ranges (`product_version_range`), CPE-only products, hashes, `product_groups` in status lists (the schema does not allow them there), or the mandatory-test checks. It also prints matches and nothing else; it does not decide what to do with a CVE your scanner found but the VEX file does not mention.

## How Trivy applies CSAF VEX

Trivy is a common place engineers first meet CSAF VEX. At tag v0.76.1, its documentation says CSAF works for container images, filesystems, code repositories, VM images, Kubernetes and SBOM targets, passed with `--vex`. Its matcher (`pkg/vex/csaf.go`) shows three things worth knowing:

- **Only two statuses act.** The status map holds `known_not_affected` and `fixed`. A match on either filters the finding. `known_affected` and `under_investigation` statements never change the result.
- **Matching is by purl.** If the detected package has no purl, or the vulnerability has no `product_status`, nothing is filtered.
- **Relationship categories are not distinguished.** The documentation says "the specified relationship category is not taken into account" and that `default_component_of`, `installed_on` and `installed_with` "are treated internally as `depends_on`". For a relationship, the code requires the parent purl to match a product higher in the dependency tree (such as the scanned image) and the component purl to match the sub-component, which is the both-sides rule from Step 2. `external_component_of` and `optional_component_of` relationships are skipped. A status on a plain product ID, with no relationship, is matched against the package's own purl, so it applies wherever that package appears.

So if a vendor's CSAF file uses `optional_component_of` for a component, Trivy will not apply that status through the relationship. That is safe in direction (no false suppression), but it can surprise you if you expect the finding to drop.

## Common mistakes

- **Matching the component alone.** Covered above. It turns a statement about one product into a statement about all of them.
- **Trusting `known_not_affected` with no impact statement.** The profile requires a flag or an impact threat for each such product. If neither exists, the document does not satisfy the profile; send it back to the vendor rather than suppressing.
- **Reading only `branches`.** Products in `full_product_names` and relationships carry IDs too. A parser that only walks branches will report "unknown product" for most relationship-heavy files.
- **Treating `recommended` as fixed.** The spec allows recommending a version from the affected group.
- **Ignoring `tracking.version` and `current_release_date`.** VEX files are revised as investigations finish. Store the version you applied, and re-apply when it changes.

## Where this fits

VEX is one input to a patch decision, not the decision. In our [vulnerability prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/), a supplier VEX statement is the step that can close a ticket before KEV, EPSS or SSVC are weighed. For the SBOM side of the join, the [SBOM minimum elements guide](/posts/sbom-minimum-elements-2026-what-cisa-and-partners-changed-from-the-2021-ntia-baseline/) covers which identifiers your SBOM should carry in the first place. Without purls in the SBOM, none of this matching works.

## Limits of this article

We read CSAF 2.0 from the OASIS TC's GitHub repository (the editor's draft prose, headed "OASIS Standard, 18 November 2022", and the JSON schema) rather than the copy hosted on docs.oasis-open.org. CSAF 2.1 is still a draft in that repository and may change field names or add statuses. We did not download a Red Hat VEX file; Red Hat's structure is described from its own announcements. The purl matching rules are a community convention, not part of the purl standard. Our test document is synthetic.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| CSAF 2.0 is an OASIS Standard dated 18 November 2022; VEX profile requirements (section 4.5) | [CSAF 2.0 prose, OASIS TC repository](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/prose/csaf-v2-editor-draft.md) | Qualified (TC repository copy) |
| Eight product_status lists and their definitions; flag labels; remediation categories; relationship categories | Same document, sections 3.2.3.9, 3.2.3.5, 3.2.3.12.1, 3.2.2.4 | Verified |
| Contradiction groups must be pairwise disjoint; recommended may come from any group | Same document, section 6.1.6 | Verified |
| purl helper pattern and "does not completely evaluate" note | Same document, section 3.1.3.3.4 | Verified |
| Example document is schema-valid | [CSAF 2.0 JSON schema](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.0/json_schema/csaf_json_schema.json), validated with Python jsonschema | Verified (our test) |
| Red Hat VEX files: per CVE, product_tree with relationships, purls extended to unfixed rpm/oci/rpmmod components at GA | [Red Hat blog, 10 July 2024](https://www.redhat.com/en/blog/red-hat-vex-files-cves-are-now-generally-available); [beta announcement, 16 October 2023](https://www.redhat.com/en/blog/vulnerability-exploitability-exchange-vex-beta-files-now-available) | Qualified (vendor announcement; GA post read via a localized copy) |
| Trivy CSAF matcher uses known_not_affected and fixed; three relationship categories | [Trivy v0.76.1 pkg/vex/csaf.go](https://github.com/aquasecurity/trivy/blob/v0.76.1/pkg/vex/csaf.go) | Verified |
| Trivy CSAF targets, relationship handling and purl matching rules | [Trivy v0.76.1 VEX file documentation](https://github.com/aquasecurity/trivy/blob/v0.76.1/docs/guide/supply-chain/vex/file.md) | Verified |
