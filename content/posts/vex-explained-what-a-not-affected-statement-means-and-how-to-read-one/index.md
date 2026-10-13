+++
title = "VEX Explained: What a \"Not Affected\" Statement Means and How to Read One"
date = 2026-10-13T06:05:00Z
tags = ["supply chain", "vulnerability management"]
categories = ["appsec"]
summary = "A VEX document is a supplier's signed-off claim about whether a specific product is affected by a specific vulnerability. Here is what the four statuses and five justifications mean in CISA's guidance, how OpenVEX and CSAF express them, and why a VEX claim is something to evaluate, not obey."
description = "VEX (Vulnerability Exploitability eXchange) explained: CISA's four statuses and five not-affected justifications, how OpenVEX and CSAF encode them, and how to decide whether to trust a VEX statement when triaging scanner findings."
author = "FirewallSync Editorial"
imageAlt = "A black magnifying glass, a black spiral notebook with a blank white card, a pencil and an eraser on a white desk"
imageCredit = "Photo by [Mediamodifier](https://unsplash.com/photos/yx17UuZw1Ck) on Unsplash"
takeaways = [
  "VEX (Vulnerability Exploitability eXchange) lets a supplier or other party state whether a particular product is affected by a particular vulnerability. CISA's guidance lists four statuses: NOT AFFECTED, AFFECTED, FIXED and UNDER INVESTIGATION.",
  "A NOT AFFECTED claim may carry one of five CISA justification codes, such as component_not_present or inline_mitigations_already_exist. Under both OpenVEX and CSAF, a not-affected statement must come with a machine-readable justification or a free-text impact statement.",
  "CISA's guidance says VEX fields are assertions made by the document's author, and the consumer may accept them or not. It describes statuses as a way to inform decisions, not a discussion-ending declaration.",
  "An SBOM says what is in a product; VEX says whether a listed vulnerability matters in that product. They are complementary documents, not substitutes.",
  "Of the five justifications, component_not_present is the easiest for a consumer to check; inline_mitigations_already_exist is the hardest to prove, and the OpenVEX specification says so."
]

[[faq]]
q = "What does VEX stand for?"
a = "Vulnerability Exploitability eXchange. CISA's June 2022 status-justification guidance describes it as a form of security advisory that lets a supplier or other party assert the status of specific vulnerabilities in a particular product."

[[faq]]
q = "Is VEX the same as an SBOM?"
a = "No. An SBOM is an inventory of components. A VEX document is a set of statements about the exploitability status of specific vulnerabilities in a specific product. They are often used together: the SBOM tells a scanner what to look for, and VEX tells a reader which findings the supplier says do not apply."

[[faq]]
q = "Should I suppress a scanner finding because a vendor says 'not affected'?"
a = "CISA's guidance says VEX statements are assertions the consumer may accept or reject. A reasonable approach, which is our suggestion rather than a CISA requirement, is to accept statements from suppliers you trust for the exact product version and component you run, to prefer machine-readable justifications over free text, and to keep the original finding recorded alongside the reason it was suppressed."

[[faq]]
q = "Which VEX formats exist?"
a = "This article covers two: OpenVEX, a lightweight JSON format whose specification says it meets CISA's minimum requirements, and CSAF 2.0, an OASIS Standard that includes a VEX profile (Profile 5). CycloneDX can also carry VEX data; we did not review its specification for this article."
+++

**VEX**, short for Vulnerability Exploitability eXchange, is a way for a supplier (or another party) to say, in a structured document, whether a specific product is affected by a specific vulnerability. A VEX statement about a library you find in your scanner output answers the question the scanner cannot: "this component is present, but can the flaw actually be reached?" This article explains the vocabulary CISA defined, shows how two formats (OpenVEX and CSAF) express it, and sets out how to evaluate a "not affected" claim before you let it close a ticket.

We read CISA's June 2022 status-justification guidance, the OpenVEX specification, the CSAF 2.0 standard and parts of Trivy's documentation on October 13, 2026. We did not write or consume a VEX document in a live pipeline for this article, so it is research-based explanation, not hands-on testing.

## The short answer

- A VEX statement ties **one product** to **one vulnerability** and gives a **status**.
- CISA's guidance says the status must be one of **NOT AFFECTED, AFFECTED, FIXED or UNDER INVESTIGATION**.
- A NOT AFFECTED status can carry a **justification** from a fixed list of five, so a tool can act on it.
- It is a claim by whoever wrote the document. CISA says the consumer "may choose to accept it or not."

## What a VEX document must contain

CISA's guidance states that VEX documents must contain four things: VEX metadata, product details, vulnerability details and product status. CISA also published a separate "Minimum Requirements for VEX" document (the CISA page is dated April 21, 2023). We could not download that PDF (CISA's server returned "Access Denied" to our request), so we rely on the OpenVEX specification's statement that it meets those minimum requirements, and on the CISA status-justification guidance quoted above.

## The four statuses

| Status (CISA name) | Meaning | OpenVEX value | CSAF 2.0 field under `product_status` |
|---|---|---|---|
| NOT AFFECTED | No remediation is required for this vulnerability in this product | `not_affected` | `known_not_affected` |
| AFFECTED | The product is affected; remediation or mitigation is recommended | `affected` | `known_affected` |
| FIXED | These product versions contain a fix | `fixed` | `fixed` |
| UNDER INVESTIGATION | Impact is not yet known | `under_investigation` | `under_investigation` |

Sources: [CISA, VEX Status Justifications (June 2022)](https://www.cisa.gov/sites/default/files/2023-01/VEX_Status_Justification_Jun22.pdf); [OpenVEX specification](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md); [CSAF 2.0 standard](https://docs.oasis-open.org/csaf/csaf/v2.0/os/csaf-v2.0-os.html). The column pairing is our mapping of equivalent concepts; each source defines its own values. CSAF defines further categories (for example `first_affected` and `last_affected`) that have no direct CISA counterpart.

The OpenVEX specification uses a hypothetical timeline to show why the statuses exist. A vendor learns of a new CVE and publishes `under_investigation`; later it finds the product affected and publishes `affected` with mitigation advice; when it ships a patch it publishes `fixed`. Without that sequence, the spec notes, a scanner user "will simply get a third party alert with no details on how the status is evolving," and the alert becomes a false positive once the product is patched.

## The five "not affected" justifications

A justification is the machine-readable reason behind a NOT AFFECTED claim. CISA lists five. The definitions below paraphrase CISA's June 2022 document; the examples in the last column are CISA's.

| Justification | What the supplier is asserting | CISA example |
|---|---|---|
| `component_not_present` | The vulnerable component is not in the product | A Python and Elixir product with no Java code cannot be affected by Log4j |
| `vulnerable_code_not_present` | The component is present, but the specific vulnerable code is not | The compiler stripped the relevant function, or the vulnerable code was added in a later version than the one shipped |
| `vulnerable_code_not_in_execute_path` | The vulnerable code is present but can never run in this product | An application that uses OpenSSL only for random-number generation is not exposed to Heartbleed, which was never called from that function |
| `vulnerable_code_cannot_be_controlled_by_adversary` | The code runs, but an attacker cannot influence it enough to trigger the flaw without another vulnerability | A hard-coded variable denies user input to the vulnerable function |
| `inline_mitigations_already_exist` | Built-in protections that an attacker or user cannot bypass or disable prevent exploitation | Input is sanitized further upstream within the product |

Two caveats from CISA's own text are easy to miss:

1. For `vulnerable_code_not_in_execute_path`, CISA warns that "a single path of execution should not be assumed since the attacker may be able to divert the path of execution."
2. For `inline_mitigations_already_exist`, CISA notes that mitigations are effective "only in the scenario where the threat model of the software allows it," and a mitigation that works in one product may not in another. The OpenVEX specification adds that this justification "could be difficult to prove conclusively."

CISA also distinguishes the last two. With `vulnerable_code_cannot_be_controlled_by_adversary`, nothing the attacker does can reach the vulnerable code in a way that triggers it. With `inline_mitigations_already_exist`, the attacker can influence execution, but another control blocks the attack. Both, CISA says, "rely on an expert analysis of the structure of the code."

## How the formats express it

### OpenVEX

OpenVEX is a JSON format. Per its specification, a document requires `@context`, `@id`, `author`, `timestamp`, `version` and `statements`. Each statement needs a vulnerability, a status and at least one product (these can be inherited from the document in some cases, and the specification says a document with incomplete statements is not valid). For `not_affected`, the statement must include either a justification or an `impact_statement`, which is free text. The specification says free-text impact statements are "highly discouraged for automated systems." For `affected`, it must include an `action_statement` describing how to remediate or mitigate.

A minimal not-affected statement looks like this. Everything below is an invented placeholder: the CVE number, the product identifier and the author are not real.

```json
{
  "@context": "https://openvex.dev/ns/v0.2.0",
  "@id": "https://example.com/vex/2026-0001",
  "author": "Example Product Security Team",
  "timestamp": "2026-10-13T06:00:00Z",
  "version": 1,
  "statements": [
    {
      "vulnerability": { "name": "CVE-2026-00000" },
      "products": [{ "@id": "pkg:oci/example-app@1.4.2" }],
      "status": "not_affected",
      "justification": "vulnerable_code_not_in_execute_path"
    }
  ]
}
```

The `version` field, the specification says, must be incremented when any content of the document changes, which is how a supplier moves from `under_investigation` to `fixed` over time.

### CSAF 2.0

CSAF (Common Security Advisory Framework) is an OASIS Standard, approved November 18, 2022, with an errata release dated January 26, 2024 that changes only an aggregator schema. Its **Profile 5: VEX** requires a product tree, a list of vulnerabilities, and at least one of the `fixed`, `known_affected`, `known_not_affected` or `under_investigation` product-status lists. It also sets two content rules:

- For each product in `known_not_affected`, an impact statement must exist, either as a machine-readable **flag** or as a human-readable `impact` entry in `threats`.
- For each product in `known_affected`, product-specific action information must be given in `remediations`; the categories `no_fix_planned` and `none_available` are permitted.

CSAF's flag labels are the same five justification values as CISA's list.

## Reading a VEX statement critically

A scanner that supports VEX can hide findings based on these documents. That is the point, and also the risk. These are our practical checks, not requirements from CISA, OpenVEX or OASIS:

1. **Match the product exactly.** Check that the product identifier and version in the statement are the ones you deploy, not a sibling image or a different build.
2. **Check who signed it.** OpenVEX says the author's identity "SHOULD be cryptographically associated with the signature of the VEX document." An unsigned file fetched from an arbitrary location is a weaker basis than a signed statement from the supplier.
3. **Prefer machine-readable justifications.** A bare `not_affected` with free text gives your tooling, and a future auditor, little to evaluate.
4. **Weigh the justification type.** `component_not_present` is something you can verify against your own SBOM. `inline_mitigations_already_exist` relies on the supplier's threat model, which is hard to check from outside.
5. **Treat known-exploited vulnerabilities with extra care.** If a vulnerability is on CISA's Known Exploited Vulnerabilities list, a wrong "not affected" is expensive. Our article on [CVSS, EPSS and KEV](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/) covers how to use that signal.
6. **Keep the audit trail.** Record which VEX document suppressed which finding, and re-evaluate when the document's version changes.

CISA's guidance also notes that VEX statements cover *known* vulnerabilities and that attackers often chain flaws; new vulnerabilities may emerge that do affect a product. A "not affected" for one CVE says nothing about the next.

## Using VEX with scanners

Tool support varies. As one example, Trivy's documentation says VEX can be used "to filter vulnerabilities based on their status," and shows the `--vex` option with four sources: a VEX repository, a local file, a VEX attestation stored in an OCI registry, or VEX files referenced in an SBOM. That page was marked "EXPERIMENTAL" when we read it and warned that the feature "might change without preserving backwards compatibility." We did not test Trivy or any other scanner's VEX handling, and we did not check which formats each scanner accepts, so confirm support for your chosen format and version before relying on it.

## Where VEX fits

- **With an SBOM:** the SBOM lists components; VEX says which vulnerabilities in them matter. See our article on the [2026 SBOM minimum elements](/posts/sbom-minimum-elements-2026-what-cisa-and-partners-changed-from-the-2021-ntia-baseline/).
- **With provenance:** signing and provenance tell you who built an artifact and how, not whether a given CVE affects it. See [SLSA build levels and provenance attestations](/posts/slsa-build-levels-and-provenance-attestations-what-they-prove-and-what-they-dont/).
- **With image scanning:** VEX is one way to reduce noise from scanners; see [what container image scanning still misses](/posts/container-image-scanning-what-ci-pipelines-still-miss/).

## Limits of this article

We could not read CISA's "Minimum Requirements for VEX" PDF (access denied). The CISA status-justification document is from June 2022 and its own text says it is not exhaustive and that CISA may add justifications later; we did not look for later revisions. We did not review the CycloneDX VEX specification, or the details of any scanner's VEX support beyond the Trivy page above. The OpenVEX specification page is titled v0.2.0 but also contains an older revision-table entry using a different version number, so check the version your tools implement.

## Sources and verification

Checked on October 13, 2026.

| Important claim | Source | Verification |
|---|---|---|
| VEX documents must contain metadata, product details, vulnerability details and product status; four statuses; five not-affected justifications; statements are the author's assertions the consumer may accept or not | [CISA, VEX Status Justifications, June 2022](https://www.cisa.gov/sites/default/files/2023-01/VEX_Status_Justification_Jun22.pdf) | Verified |
| Definitions and examples for each justification; the caveats on execution path and inline mitigations | Same document, sections 3.3 to 3.7 | Verified |
| CISA published "Minimum Requirements for VEX," page dated April 21, 2023 | [CISA resource page](https://www.cisa.gov/resources-tools/resources/minimum-requirements-vulnerability-exploitability-exchange-vex) | Qualified: PDF itself could not be downloaded |
| OpenVEX required fields; justification or impact statement required for `not_affected`; free text discouraged for automation; `action_statement` for `affected`; author signature recommendation; version incrementing | [OpenVEX specification](https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md) | Verified |
| OpenVEX says it meets CISA's April 2023 minimum requirements | Same specification, overview | Qualified: the OpenVEX project's own claim |
| CSAF 2.0 is an OASIS Standard dated November 18, 2022; errata dated January 26, 2024 | [CSAF 2.0 errata 01](https://docs.oasis-open.org/csaf/csaf/v2.0/csaf-v2.0.html) | Verified |
| CSAF Profile 5 requirements; `product_status` categories; flag labels | [CSAF 2.0 standard](https://docs.oasis-open.org/csaf/csaf/v2.0/os/csaf-v2.0-os.html) | Verified |
| Trivy `--vex` options; page marked experimental | [Trivy VEX documentation](https://trivy.dev/latest/docs/supply-chain/vex/) | Qualified: read October 13, 2026; may change |
| Status mapping table; reading checklist | Our analysis | Qualified: editorial judgment, labelled as such |
