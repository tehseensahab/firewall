+++
title = "How to Audit Unused Cloud Accounts, Roles, and Service Identities"
date = 2026-11-04T09:00:00Z
tags = ["iam", "cloud security"]
summary = "An unused identity with live credentials is functionally identical to a vulnerability sitting unpatched — nobody's using it, but it still works exactly as well for whoever finds it."
description = "How to audit unused cloud accounts, roles, and service identities systematically, using activity data rather than manual review, before they become someone else's access."
author = "FirewallSync Editorial"
+++

An unused cloud identity — an IAM user nobody logs into anymore, a service account for a decommissioned integration, a role created for a migration that finished a year ago — is functionally identical to an unpatched vulnerability. It doesn't matter that nobody on your team is using it. What matters is that its credentials still work, exactly as well, for anyone who happens to find them.

## Why unused identities accumulate

Identities get created deliberately and removed by nobody's default responsibility. Offboarding processes, when they exist, usually focus on disabling a departed employee's primary login — they less consistently catch the service accounts that person set up, the API keys they generated for a one-off script, or the IAM role created specifically for a project that's since been shelved. Each of these represents a valid credential that continues to function indefinitely unless something explicitly removes it, and nothing about normal operations naturally surfaces "this hasn't been used in months" as a signal anyone acts on.

## Finding unused identities with activity data, not assumption

**AWS IAM Access Analyzer's unused access findings** directly surface unused IAM roles, unused access keys on IAM users, and unused passwords, based on actual observed activity rather than requiring manual review of every identity. This turns "which of our hundreds of IAM users and roles are stale" from a guessing exercise into a query against real usage data.

**Cloud provider "last accessed" and "last used" metadata** exists across most major providers for service accounts, API keys, and roles — checking this directly, even without a dedicated unused-access tool, gives a concrete date rather than relying on institutional memory about whether something is still needed.

**Cross-referencing identity lists against current employee and vendor rosters** catches accounts that should have been disabled during offboarding but weren't — this requires connecting your identity provider's audit data to your HR or vendor management system, which isn't automatic in most setups but is one of the highest-value manual checks available.

## Service identities deserve more scrutiny than human ones, not less

Service accounts and machine identities often get created with broader permissions than strictly necessary, because there's no individual human whose access needs feel personally accountable — nobody wants to be the reason a batch job fails from insufficient permissions, so the path of least resistance is granting broadly. Combined with the fact that service accounts don't have an obvious "this person left the company" trigger to prompt review, they tend to accumulate both excess permission and staleness at a higher rate than human accounts, while receiving less routine attention.

## What to do once you've found unused identities

**Don't delete immediately — deactivate first, and observe.** An identity that appears unused in your analysis window might back an infrequent process (a quarterly compliance export, an annual data migration script) that simply hasn't run recently. Deactivating (disabling the credential without deleting the identity) and monitoring for any access failures over a follow-up period is safer than immediate deletion, and still closes the exposure during the observation window.

**Extend your observation window for anything ambiguous.** Thirty days of "unused" data is a reasonable default for continuously-running services, but insufficient for anything tied to quarterly, annual, or on-demand processes — check with the team that would own the process before treating a longer-cycle identity as confirmed unused.

**Prioritize by permission scope, not just by staleness.** An unused identity with narrow, low-impact permissions is a lower-priority cleanup than an unused identity holding broad administrative access — if you can only tackle a subset immediately, start with the ones that would matter most if found and used maliciously.

## Building this into an ongoing process, not a one-time cleanup

A single cleanup pass reduces the current backlog but doesn't stop new unused identities from accumulating going forward, since the same organizational gaps that created the current backlog — no clear ownership of removing access when it's no longer needed — remain in place afterward. A recurring quarterly (at minimum) review, ideally automated through a tool that surfaces unused-access findings continuously rather than requiring someone to remember to run an audit, keeps the backlog from silently rebuilding.

## A practical checklist

- Run cloud-native unused access tooling (like AWS IAM Access Analyzer) as a recurring process, not a one-time audit
- Cross-reference identity lists against current employee and vendor rosters to catch offboarding gaps
- Apply extra scrutiny to service and machine identities specifically, since they accumulate excess more often and get reviewed less
- Deactivate before deleting, with an observation period for anything not obviously safe to remove immediately
- Prioritize cleanup by permission scope and blast radius, not purely by how long an identity has been idle
- Establish a recurring cadence for this review, not a one-time project, since the conditions that create unused identities don't go away after a single cleanup

The goal isn't a one-time reduction in identity count. It's closing the gap between "how many valid credentials exist" and "how many are actually needed," on an ongoing basis, since that gap is where a meaningful share of real incidents originate.
