+++
title = "Dependency Confusion: How Package Managers Can Become an Attack Path"
date = 2026-10-31T09:00:00Z
tags = ["supply chain", "appsec"]
summary = "Dependency confusion doesn't exploit a vulnerability in any package. It exploits a resolution assumption most package managers share, and it was proven against 35+ major companies without a single CVE."
description = "How dependency confusion attacks work, why they compromised Apple, Microsoft, and PayPal without a single CVE, and how to actually close the gap."
author = "FirewallSync Editorial"
+++

In February 2021, security researcher Alex Birsan demonstrated a technique that compromised build systems at Apple, Microsoft, PayPal, Tesla, Uber, Yelp, and more than 30 other major companies — earning over $130,000 in bug bounties in the process. None of it involved a zero-day exploit, stolen credentials, or malware hidden inside a legitimate package. It exploited a single, widely shared assumption in how package managers resolve dependency names.

## The assumption being exploited

Many organizations use internal, unscoped package names for private code — something like `auth-utils` or `internal-logger`, hosted on a private registry alongside public packages resolved from npm, PyPI, or similar. Several package managers, when configured to check both public and private registries, will resolve to whichever source has the higher version number, or will check the public registry as part of normal resolution regardless of whether a private package with the same name exists. If an attacker publishes a public package with the exact same name as your private one, at a deliberately high version number, some build configurations will pull the attacker's public package instead of your legitimate internal one — with no error, and no obvious signal that anything went wrong.

## How Birsan actually found the names

The hardest part of this attack isn't the publishing step — it's knowing what internal package names to target in the first place. Birsan's research found that internal package names leaked through remarkably mundane channels: `package.json` files accidentally committed to public repositories, internal package names appearing inside minified JavaScript bundled and shipped to production (since build tools sometimes embed dependency manifests into bundled output), error messages exposing internal paths, and even job postings or forum discussions mentioning internal tooling by name. None of this required any kind of breach — it was all information organizations had, in effect, published themselves without realizing what it enabled.

## Why this isn't caught by normal vulnerability scanning

A dependency confusion package has no known vulnerability associated with it — it's often a brand-new package with no CVE, no flagged malicious signature, and nothing that would trip a traditional CVE-based scanner. The "vulnerability" isn't in any package's code at all; it's in the resolution logic deciding which package to install. This is why teams that already run vulnerability scanning in CI can still be fully exposed to this attack — the two problems are structurally different, and one doesn't provide any coverage for the other.

## Closing the gap

**Scope your private packages** using your registry's namespace/scope feature (npm's `@your-org/package-name` scoping, for example) rather than unscoped names — a properly scoped private package doesn't collide with anything in the public registry's global namespace, closing the ambiguity the attack depends on.

**Explicitly configure your package manager to resolve specific scopes only from your private registry**, rather than allowing it to check public sources as a fallback or alongside private ones for anything internal. Most package managers support this configuration (a `.npmrc` scope-to-registry mapping, for example), and it removes the resolution ambiguity at the source rather than relying on naming conventions alone.

**Register placeholder packages for your internal names on public registries**, even if they contain nothing but a notice — a defensive squatting move that closes the door on an attacker registering that name later, though this doesn't scale well as an organization's internal package count grows and shouldn't be relied on as the primary defense.

**Audit what your internal package names actually are, and whether any have already leaked** through the same channels Birsan documented — committed manifest files, bundled minified output, error messages. This audit is worth doing once deliberately, since these leaks tend to be historical accidents rather than ongoing practices, and finding them after the fact still closes future exposure.

## Why this attack pattern hasn't gone away

Once Birsan's technique became public, hundreds of copycat packages appeared on public registries using names patterned after other companies' likely internal package naming — some from researchers replicating the technique for further bug bounties, some with less benign intent. The underlying resolution ambiguity in package managers that don't enforce strict scope-based routing hasn't been universally fixed at the tooling level, which means the exposure Birsan demonstrated in 2021 remains present in any organization that hasn't specifically configured against it, regardless of how much time has passed since the original disclosure.

## A practical checklist

- Use registry scoping for all internal/private packages, never unscoped names
- Configure your package manager to route specific scopes exclusively to your private registry
- Audit historical leaks of internal package names in committed files, bundled output, and public discussions
- Treat this as a distinct control from vulnerability scanning — one does not provide coverage for the other
- Consider defensive registration of internal package names on public registries as a secondary, not primary, mitigation
