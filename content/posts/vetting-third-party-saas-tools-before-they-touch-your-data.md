+++
title = "Vetting Third-Party SaaS Tools Before They Touch Your Data"
date = 2026-10-04T09:00:00Z
tags = ["third-party risk", "iam"]
summary = "Most SaaS vetting stops at a security questionnaire the vendor's sales team fills out. Here's what actually predicts third-party risk in practice."
description = "Third-party SaaS risk assessment usually stops at a vendor questionnaire. A more useful vetting process focused on what actually predicts incidents."
author = "FirewallSync Editorial"
+++

A security questionnaire filled out by a vendor's sales or solutions team, then filed away unread, is the default third-party risk process at most companies — and it predicts almost nothing about actual risk, because the person answering it usually isn't the person who built the system or knows its real failure modes.

## Scope data access before you evaluate anything else

The single most useful vetting question isn't "do you have SOC 2" — it's "what data does this tool actually need, and does the integration request more than that." OAuth scopes and API permissions requested during setup routinely exceed what the tool's stated function requires, because broad defaults are easier for the vendor to build than granular ones. Reviewing the actual requested scopes against the tool's job description, before granting access, catches over-permissioned integrations that a compliance questionnaire never asks about.

## Compliance certifications tell you about process, not about your specific risk

SOC 2 and ISO 27001 are useful signals that a vendor has *a* security process, but they don't tell you whether that process covers the specific way you're using the tool, or whether a breach at the vendor would actually expose your data versus just their infrastructure. Ask vendors directly what a breach on their end would mean for your specific data — the quality and specificity of that answer is a better risk signal than the certification badge itself.

## Offboarding is where most third-party risk actually lives

Vetting focuses entirely on the point of approval, but a large share of real incidents trace back to tools that were approved once, integrated deeply, and never revisited — accumulating access and dormant integrations for accounts nobody uses anymore. Build a recurring review (even annual) of what's still connected and what access it still has, not just a one-time approval gate. An unused integration with live credentials is functionally identical to a live vulnerability, and most companies have several they've forgotten about.
