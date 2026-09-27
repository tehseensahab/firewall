+++
title = "SaaS Security: How to Audit OAuth Apps Connected to Your Company"
date = 2026-11-23T09:00:00Z
tags = ["third-party risk", "iam"]
summary = "Every time an employee clicks 'Allow' on an OAuth consent screen, a third-party application gets standing access to company data — and most organizations have no consolidated view of how many of these grants actually exist."
description = "How to audit OAuth apps connected to your company's core SaaS platforms, find overprivileged and abandoned integrations, and build this into a recurring process."
author = "FirewallSync Editorial"
+++

Every time an employee clicks "Allow" on an OAuth consent screen — connecting a scheduling tool to their calendar, a productivity app to their email, a survey tool to their file storage — that third-party application gets standing access to company data, persisting until someone explicitly revokes it. Most organizations have no consolidated inventory of how many of these grants actually exist across their user base, which is exactly what makes this one of the least visible categories of third-party risk in a typical SaaS-heavy environment.

## Why this accumulates invisibly

Unlike a vendor procurement process, granting OAuth access typically requires no approval workflow at all — an individual employee can connect a new application to their Google Workspace or Microsoft 365 account with a few clicks, entirely outside whatever vendor review process governs officially procured software. Multiply this across every employee, over years, and the result is a long tail of OAuth grants that nobody centrally tracks, many connected to applications that stopped being actively used long ago but whose access was never revoked.

## Where to actually find this data

**Google Workspace's admin console** provides a view of third-party apps with access to your domain's data, including the specific OAuth scopes each app has been granted and which users have authorized it.

**Microsoft 365 / Entra ID's enterprise applications view** provides the equivalent for Microsoft-connected OAuth apps, including consent grants and the specific permissions each app holds.

**Dedicated SaaS security posture management (SSPM) tools** aggregate this across multiple platforms simultaneously and often add risk scoring, which matters once the raw list of connected apps across a large organization reaches into the hundreds or thousands — a scale where manual review of each one stops being practical.

## What to actually check for each connected app

**Scope of access granted, not just that access exists.** An app with read-only access to a single calendar carries a very different risk than one with full read/write access to email and file storage — the raw count of connected apps matters less than understanding what the highest-scoped ones can actually do.

**How many users have authorized it, and whether that's consistent with legitimate use.** A single employee having connected an obscure scheduling tool is a very different risk profile than dozens of employees having authorized the same application, particularly if it's one the organization never formally reviewed or approved.

**Whether the app or its publisher is still active and legitimate.** Some connected apps are abandoned projects, defunct startups, or tools whose ownership has changed since the original authorization — an OAuth grant doesn't get revisited just because the app it was authorized for stopped being maintained or changed hands, and a defunct or acquired app with standing access to your data is a real, if easily overlooked, risk.

**Whether the scopes requested actually match the app's stated function.** A note-taking app requesting broad access to send email on the user's behalf, or a calendar tool requesting access to file storage, is requesting scope beyond what its function would reasonably require — worth specific scrutiny regardless of how legitimate the app's core function appears.

## Prioritizing what you find

Not every connected app needs the same level of scrutiny or urgency. A reasonable triage:

- **High priority**: broad scopes (full mailbox access, broad file storage access, admin-level permissions) combined with many users, or any app that's clearly abandoned/unmaintained but still holds active access
- **Medium priority**: narrow scopes but many users, or broad scopes with very few users — worth reviewing but less urgent than the combination of broad scope and wide usage
- **Lower priority**: narrow, specific scopes with a single or few users, particularly for well-known, actively maintained applications with a legitimate business use case

## Building this into a recurring process, not a one-time audit

A single cleanup pass addresses the current backlog but doesn't prevent new ungoverned OAuth grants from accumulating going forward, since the underlying gap — no approval workflow required to connect a new app — remains in place afterward. A recurring review cadence (quarterly is reasonable for most organizations), combined with alerting on new OAuth grants above a certain scope threshold as they happen rather than only discovering them at the next audit, keeps the backlog from silently rebuilding between reviews.

## A practical checklist

- Pull the full list of OAuth-connected applications from each major SaaS platform's admin console, or use an SSPM tool if managing this across many platforms
- Prioritize review by scope of access granted and number of users, not by app name recognition
- Specifically check for abandoned or defunct apps that still hold active access
- Flag scope requests that don't match an app's stated function for closer review
- Establish a recurring audit cadence, and where possible, real-time alerting for new high-scope grants rather than relying solely on periodic review

The goal isn't zero third-party OAuth connections — that's unrealistic and would eliminate real productivity value. It's having an actual, current inventory of what's connected and what it can do, so overprivileged and abandoned integrations get caught and revoked before they become the access path an incident is traced back to.
