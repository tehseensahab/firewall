+++
title = "How to Find Overprivileged AWS IAM Users and Roles"
date = 2026-10-10T09:00:00Z
tags = ["iam", "cloud security"]
summary = "Overprivileged IAM identities aren't usually the result of one bad decision. They're the accumulated residue of a hundred small, reasonable-seeming ones. Here's how to actually find them."
description = "How to find overprivileged AWS IAM users and roles using Access Analyzer, CloudTrail activity, and policy comparison — before an incident finds them for you."
author = "FirewallSync Editorial"
+++

Overprivileged IAM identities rarely come from one obviously bad decision. They come from a hundred individually reasonable ones — a broad policy attached during setup, a permission added to unblock a deploy, a role copied from a template that itself was never trimmed. The result is an environment where almost every identity has more access than it uses, and nobody can say with confidence which ones without checking.

## Start with what's provably unused, not what looks risky

Guessing which roles are overprivileged by reading policy documents doesn't scale and misses the point — a policy can look reasonable on paper and still grant access nothing has touched in a year. IAM Access Analyzer's unused access findings are built for exactly this: it surfaces unused roles, unused access keys, unused passwords, and — most usefully — the specific unused services and actions within an otherwise-active identity's policy, based on real activity data rather than a manual read of the JSON.

This reframes the question from "does this policy look too broad" to "what has this identity actually never used," which is both more concrete and harder to argue with when you bring findings to a team that owns the resource.

## Cross-reference with CloudTrail for the identities Access Analyzer won't fully cover

Access Analyzer's unused-access findings are strong for standing IAM users and roles but won't capture every nuance of activity, especially for identities used inconsistently or through cross-account access patterns. For those, CloudTrail's event history lets you query what a specific principal has actually called over a given window — filtering by user identity ARN and looking at the distinct set of API actions invoked is a direct way to compare "granted" against "used" for any identity you're specifically concerned about.

## Compare against role purpose, not just activity

An identity can be actively using every permission it has and still be overprivileged, if the permissions it's using go beyond what its actual job requires. This shows up most often in service roles: a Lambda function that only needs to read from one S3 bucket but was granted broad `s3:*` access because it was faster to configure. Activity-based tooling won't flag this, because the access is being used — just more broadly than necessary. This requires pairing the automated findings with a manual pass asking "does this identity's actual function justify this scope," particularly for any role with wildcard resources or actions.

## Prioritize by blast radius, not by count

Once you have a list of overprivileged identities, tackling them in the order you found them wastes effort on low-stakes fixes while high-risk ones wait. Rank by what the identity could do if compromised, not by how many unused permissions it has — a role with three unused but highly sensitive permissions (like `iam:CreateUser` or `kms:Decrypt` on a broad key set) deserves attention before a role with twenty unused but low-impact ones.

## A practical checklist

- Run IAM Access Analyzer's unused access analysis across every account, not just production
- Query CloudTrail directly for any identity Access Analyzer's findings don't fully cover
- Cross-check active-but-broad permissions against the identity's actual functional purpose, not just usage data
- Rank remediation by potential blast radius, not by finding volume
- Treat any identity with wildcard actions or resources as a priority review, regardless of what usage data shows

Finding overprivileged identities is a data problem before it's a policy-writing problem. The tooling to answer "what's actually being used" already exists in most AWS accounts — the gap is usually that nobody's running it on a recurring basis, not that the answer is hard to get.
