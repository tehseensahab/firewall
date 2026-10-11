+++
title = "SBOM Minimum Elements 2026: What CISA and Its Partners Changed From the 2021 NTIA Baseline"
date = 2026-10-11T06:05:00Z
tags = ["supply chain", "appsec"]
categories = ["appsec"]
summary = "On July 29, 2026, CISA and international partners published updated minimum elements for a software bill of materials, replacing the 2021 NTIA document. Here is what changed in the data fields and practices, what did not, and what to ask your suppliers and your tooling for."
description = "CISA's 2026 SBOM Minimum Elements explained: the 17 data fields, ten new ones, removed elements, the Coverage and unknown-information rules, SPDX and CycloneDX, and what the guidance does not require."
author = "FirewallSync Editorial"
imageAlt = "Tall stacks of wooden crates in a warehouse, with open crates of oranges in the foreground"
imageCredit = "Photo by [Hemerson Coelho](https://unsplash.com/photos/iqEOJiBs1o8) on Unsplash"
takeaways = [
  "The 2026 Minimum Elements for a Software Bill of Materials (SBOM) was published on July 29, 2026 by CISA with the NSA, the FBI and other national agencies. It updates and replaces NTIA's 2021 document (version 2.1; the 2025 version was a public-comment draft).",
  "The 2021 document listed seven baseline data fields. The 2026 document's data-field table lists 17, and its own Notable Updates section names ten as new, including component hash, component license, SBOM tool name and SBOM generation context.",
  "The guidance says it does not create new requirements; it refines how organizations should generate and request SBOMs. It is not legal or compliance advice.",
  "Depth is replaced by Coverage: an SBOM should include all components, including transitive dependencies, with no minimum depth. Unknown data must be marked as unknown or withheld, not left blank.",
  "SPDX and CycloneDX are named as the two widely used machine-processable formats. SWID tags, listed in 2021, were removed from the list."
]

[[faq]]
q = "Is the 2026 SBOM minimum elements guidance a legal requirement?"
a = "The document says the minimum elements do not create new requirements and that it is not advice for compliance, regulatory or legal purposes. It is guidance on what an SBOM should contain and how organizations should request and generate one. Whether a specific contract, procurement rule or regulation requires it is a separate question to check for your situation."

[[faq]]
q = "What is the difference between the SBOM Author and the Component Producer?"
a = "Per the 2026 document, the SBOM Author is the entity that creates the SBOM data (the entity operating the tool, not the tool itself). The Component Producer is the entity that created or developed the component. They can be the same organization or different ones, for example when a customer generates an SBOM for software someone else made."

[[faq]]
q = "Should an SBOM be SPDX or CycloneDX?"
a = "The document names both as the two data formats currently widely used and says producers may choose based on organizational or sector factors. It says organizations should accept any widely used, interoperable, machine-processable format, and should avoid accepting SBOMs for new software generated in deprecated versions of any format."

[[faq]]
q = "Does an SBOM list vulnerabilities?"
a = "No. The guidance describes an SBOM as an inventory of components. Vulnerability status is communicated through separate security advisories such as VEX (Vulnerability Exploitability eXchange) and CSAF (Common Security Advisory Framework) documents, which can be matched against the components an SBOM lists."

[[faq]]
q = "What happened to the Depth element?"
a = "The 2021 Depth element was replaced by Coverage. The 2026 document says an SBOM should include all components that make up the target software, including transitive dependencies, and that there is no minimum depth."
+++

A software bill of materials (SBOM) is, in the words of the guidance itself, "a nested inventory, a list of ingredients that make up software applications and systems." On **July 29, 2026**, the U.S. Cybersecurity and Infrastructure Security Agency (CISA), the National Security Agency (NSA), the Federal Bureau of Investigation (FBI) and agencies from other countries published the *2026 Minimum Elements for a Software Bill of Materials*. It "updates and replaces" the *Minimum Elements For a Software Bill of Materials* that the U.S. National Telecommunications and Information Administration (NTIA) published on **July 12, 2021**. If you buy, build or operate software and you ask anyone for an SBOM, this is now the reference list of what to ask for.

This article is research-based: we read the full 2026 document, the 2021 NTIA document, and CISA's announcement. We did not generate SBOMs with any tool or check how specific tools map to these fields.

## What this document is, and what it is not

- **Who published it:** CISA with the NSA, the FBI and, according to the document's header, 15 further organizations from other countries (among them Australia, Canada, France, Germany, India, Italy, Japan, the Netherlands, New Zealand, Poland, South Korea, Slovakia and the Czech Republic). Its acknowledgements note that the European Commission's DG CONNECT contributed, but that the document does not interpret EU law and does not bind the Commission.
- **Version history:** version 1.0 was the NTIA document of July 12, 2021; version 2.0 was a public-comment draft of August 22, 2025; version 2.1, dated July 29, 2026, incorporates the comments received. CISA's announcement says more than 90 comments were received.
- **Not a mandate:** the document states the minimum elements "do not create new requirements; they refine how organizations should generate and request SBOMs," and its disclaimer says it is not advice for compliance, regulatory or legal purposes. Do not read it as a law. Individual contracts or regulations may point to it, but that is separate.
- **Scope:** it applies to SBOMs for all software, including open source, AI software and software as a service (SaaS). It says AI systems and SaaS may need additional elements, which are out of scope. For AI it points to separate G7 joint guidance published in May 2026.

## What changed in the data fields

The 2021 document listed seven baseline data fields: Supplier Name, Component Name, Version of the Component, Other Unique Identifiers, Dependency Relationship, Author of SBOM Data and Timestamp. The 2026 document's Appendix A table lists **17** data fields, in two groups: SBOM Metadata (about the SBOM document) and Component Data (about each component).

CISA's announcement names four new elements: Component Hash Algorithm, Component License, SBOM Tool Name and SBOM Generation Context. The document itself is more complete. Its Notable Updates section lists **ten** new elements: SBOM Author Signature, SBOM Data Format Name, SBOM Data Format Version, SBOM Generation Context, SBOM Tool Name, SBOM Tool Version, SBOM Version, Component Hash Value, Component Hash Algorithm and Component License. We count ten from that list; the announcement's four are a subset, not a conflict.

| 2026 data field | Group | Status vs 2021 | What it is (paraphrased from the document) |
|---|---|---|---|
| SBOM Author | Metadata | Major update (was Author of SBOM Data) | Entity that created the SBOM data; the operator of the tool, not the tool |
| SBOM Author Signature | Metadata | New | Digital signature attributable to the author, to show the data was not modified |
| SBOM Data Format Name / Version | Metadata | New | Which format (and format version) the SBOM uses |
| SBOM Generation Context | Metadata | New | Lifecycle phase when generated, such as before build, build, or after build |
| SBOM Timestamp | Metadata | Minor update | Date and time of the most recent update; should follow RFC 9557 |
| SBOM Tool Name / Version | Metadata | New | The tool that generated or amended the SBOM, and its version |
| SBOM Version | Metadata | New | Identifies a change from a previous version of the SBOM |
| Component Producer | Component | Major update (was Supplier Name) | Entity that created or developed the component; one organization per component |
| Component Name | Component | Minor update | Name assigned by the producer; multiple entries allowed for alternate names |
| Component Version | Component | Major update | Producer's identifier for the version; mark unknown if not provided |
| Component Identifiers | Component | Major update (was Other Unique Identifiers) | At least one common identifier, such as CPE or Package-URL (PURL) |
| Component Dependency Relationship | Component | Minor update | One component is necessary for the operation of another |
| Component Hash Value / Algorithm | Component | New | Hash of the executable component artifact and the algorithm used |
| Component License | Component | New | License identifiers, such as SPDX license identifiers |

A few details worth knowing:

- **Why "Supplier" became "Component Producer":** the document says Supplier Name "has proven ambiguous in practice, particularly around distributors of software," and that some ambiguity will remain even with the new name.
- **Hashes:** the Component Hash Value is computed over the executable component artifact. If the SBOM author does not have access to it, the document says to indicate the value is unknown. The algorithm should be identified using IANA Hash Function Textual Names and be approved by a relevant authority such as NIST.
- **Generation context matters:** the document's example is that an SBOM generated from source code is "before build," while one produced by binary analysis tools is "after build." The same software can have different component data depending on when the SBOM is generated, so this field tells a reader how much to trust the data.
- **Identifiers:** a field may carry multiple identifiers; if there are several, the author should include all of them.

## What changed in practices and processes

| Element | 2026 expectation (paraphrased) | Change from 2021 |
|---|---|---|
| Coverage | Include all components, including transitive dependencies. "There is no minimum depth." Duplicate instances with different metadata are listed separately. | Replaces Depth, which was defined as top-level dependencies only |
| Explicitly Identifying Unknown Information | If a field is not provided, state whether it is unknown to the author or withheld. An SBOM may be considered incomplete if essential data is withheld. | Replaces Known Unknowns |
| Frequency | Each software version or update should have an associated SBOM; issue a revised one when errors or new details are found | Rewritten; intent unchanged per the document |
| Distribution and Delivery | Available promptly to those who need them; access controls must not block authorized parties or trusted security tools | Simplified; absorbs the removed Access Control element |
| Accommodation of Updates to SBOM Data | Accommodate corrections; correct errors promptly; errors may feed risk decisions | Replaces Accommodation of Mistakes |
| Machine-Processable Data | Use widely used, open, machine-processable formats; avoid accepting new-software SBOMs in deprecated format versions | Replaces Automation Support; SWID tags dropped |

Coverage carries the biggest practical change. The document's own illustration: from a vulnerability management view, the recipient of an SBOM "should be able to conclude that a newly reported vulnerability does not affect them if the SBOM does not list the component associated with the vulnerability." That only works if the SBOM is comprehensive, including transitive dependencies (dependencies of your dependencies). It also allows linking to separate SBOMs for subcomponents, provided the recipient has access to all of them.

## SPDX, CycloneDX and the format question

The document names two data formats as widely used: SPDX (System Package Data eXchange), cited with ISO/IEC 5962:2021, and CycloneDX, cited with ECMA-424, which it dates December 2025. It does not tell you to pick one. Producers choose "based on factors that may be specific to organizations, industries, or sectors," while consumers "should accept any widely used, interoperable, and machine-processable SBOM format."

For current version numbers, the CycloneDX specification overview showed version 1.7, released October 21, 2025, when we checked. The SPDX specifications page identified SPDX Document Version 3.0 as the current version; it shows no release dates for versions. We did not verify how each tool's output maps onto the 17 fields. When evaluating a generator, check whether its output actually includes, for example, hash values, license identifiers and generation context, rather than assuming it does.

## What this means in practice

These are our suggestions based on the guidance, not requirements in it:

1. **Update the SBOM request language** in vendor questionnaires. Instead of "provide an SBOM," ask for one that satisfies the 2026 Minimum Elements, in a named format and version, with Coverage including transitive dependencies. See our [guide to vetting third-party SaaS tools](/posts/vetting-third-party-saas-tools-before-they-touch-your-data/) for the wider vendor review.
2. **Check your generation tooling** for the new metadata: tool name and version, generation context, timestamp, and a signature if you share SBOMs externally.
3. **Generate at more than one point** if you can. Because components differ by lifecycle phase, a source-based SBOM and a post-build SBOM are not interchangeable.
4. **Pair SBOMs with vulnerability prioritization.** An SBOM tells you whether you have a component; it does not tell you whether the flaw is exploitable in your product. The guidance points to VEX and CSAF for that. Our comparison of [CVSS, EPSS and KEV](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/) covers prioritization, and [dependency audits without slowing releases](/posts/dependency-audits-without-slowing-down-releases/) and [container image scanning](/posts/container-image-scanning-what-ci-pipelines-still-miss/) cover where the component data comes from in CI.
5. **Treat unknowns as data.** Mark fields you cannot fill as unknown rather than omitting them, as the guidance asks, and treat "unknown" in a vendor SBOM as a follow-up question, not a pass.

## Limits of this article

We did not verify the claims of third-party summaries that count the changes differently; we counted from the document. We did not check whether the U.S. federal procurement rules, the EU Cyber Resilience Act or any other regime now references the 2026 document. The document itself only notes that the EU Cyber Resilience Act (Regulation (EU) 2024/2847) requires manufacturers of products with digital elements to provide an SBOM as part of technical documentation, and states that it does not interpret EU law. Check your own contractual and regulatory obligations separately.

## Sources and verification

Checked on October 11, 2026.

| Important claim | Source | Verification |
|---|---|---|
| 2026 Minimum Elements published July 29, 2026; version history 1.0 (July 12, 2021), 2.0 (August 22, 2025), 2.1 (July 29, 2026); updates and replaces NTIA 2021 | [CISA, 2026 Minimum Elements for a SBOM (PDF)](https://www.cisa.gov/sites/default/files/2026-07/2026_cisa_sbom_minimum_elements_508c.pdf) and [CISA resource page](https://www.cisa.gov/resources-tools/resources/2026-minimum-elements-software-bill-materials-sbom) | Verified |
| 17 data fields in Appendix A; ten elements listed as new; definitions; Access Control removed; SWID removed; Depth replaced by Coverage; unknown-information rules; no new requirements; not compliance advice | Same PDF | Verified: counts are our own from the document's tables and lists |
| CISA announcement names four new elements and says 90+ comments were received | [CISA announcement, July 29, 2026](https://www.cisa.gov/news-events/news/cisa-and-partners-unveil-updated-software-bill-materials-resource-improves-transparency-security-and) | Verified |
| 2021 baseline had seven data fields; published July 12, 2021 | [NTIA, The Minimum Elements For a Software Bill of Materials (PDF)](https://www.ntia.gov/files/ntia/publications/sbom_minimum_elements_report.pdf) | Verified |
| CycloneDX 1.7 released October 21, 2025; developed with Ecma International as ECMA-424 | [CycloneDX specification overview](https://cyclonedx.org/specification/overview/) | Qualified: current as of the date we read it |
| SPDX specifications page identifies 3.0 as the current document version and links ISO/IEC 5962:2021 | [SPDX specifications](https://spdx.dev/use/specifications/) | Qualified: page shows no release dates for versions |
| Practical recommendations in "What this means in practice" | Our analysis of the above | Qualified: editorial judgment, not requirements of the guidance |
