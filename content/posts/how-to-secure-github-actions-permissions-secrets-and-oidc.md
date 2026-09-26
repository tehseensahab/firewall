+++
title = "How to Secure GitHub Actions: Permissions, Secrets, and OIDC"
date = 2026-11-01T09:00:00Z
tags = ["appsec", "supply chain"]
summary = "A GitHub Actions workflow often runs with more access than the task actually requires, simply because the defaults are permissive and nobody scoped them down before shipping."
description = "How to secure GitHub Actions: workflow permissions, third-party action risk, secrets scoping, and using OIDC instead of long-lived cloud credentials."
author = "FirewallSync Editorial"
+++

A GitHub Actions workflow, by default, often runs with more access than the task it performs actually requires — not because anyone deliberately over-provisioned it, but because the defaults are permissive and narrowing them down takes deliberate configuration that's easy to skip while getting a pipeline working.

## Scope the GITHUB_TOKEN's permissions explicitly

Every workflow run gets an automatically generated `GITHUB_TOKEN` with permissions to the repository, and its default scope has historically been broad (write access to most repository resources) unless explicitly restricted. Setting explicit `permissions` at the workflow or job level — for example, `contents: read` for a job that only needs to check out code, without write access it doesn't use — limits what a compromised or misbehaving step in that workflow could actually do. Treat "no permissions block at all" as equivalent to "unreviewed, possibly excessive default access," and set it explicitly on every workflow rather than relying on whatever the default happens to be.

## Third-party actions run with your workflow's access

An action referenced with `uses: someorg/some-action@v1` executes with the same permissions and secrets access as the rest of your workflow — it isn't sandboxed away from your repository's context. A compromised or malicious action has the same practical reach as a line of code you wrote directly into the workflow yourself. Pin third-party actions to a specific commit SHA rather than a mutable version tag; a tag can be moved to point at different code without your workflow file changing at all, while a commit SHA cannot be silently swapped underneath you.

## Be deliberate about pull_request vs pull_request_target

Workflows triggered by `pull_request` from a fork do not have access to repository secrets by default — this is intentional, specifically to prevent a malicious fork PR from exfiltrating secrets through a workflow run. `pull_request_target`, by contrast, does grant secrets access and runs with the target repository's permissions, which is necessary for some legitimate use cases (like commenting on PRs from forks) but requires careful handling of any code checked out from the fork, since that code is now running with elevated access it wouldn't otherwise have. Mixing this up — using `pull_request_target` without the corresponding caution around what fork-supplied code gets executed — is a well-documented way workflows get exploited.

## OIDC removes the need for long-lived cloud credentials entirely

Storing static cloud credentials (an AWS access key, a GCP service account key) as a GitHub secret means that credential is a standing target — if it leaks, through any of the usual channels, it remains valid until someone notices and manually rotates it. GitHub Actions supports OpenID Connect (OIDC), which lets a workflow request a short-lived token from GitHub's OIDC provider and exchange it for temporary cloud credentials at request time, without any static credential stored in GitHub at all. AWS, GCP, and Azure all support configuring a trust relationship that allows this exchange, scoped to specific repositories or even specific branches.

This is a meaningfully different security posture, not just a convenience improvement: there's no long-lived credential to leak, because none exists in GitHub's secret storage in the first place — the token issued for each workflow run is scoped to that run and expires shortly after.

## Secrets scoping beyond just using GitHub Secrets

Even with secrets correctly stored (rather than hardcoded), using repository-level secrets for everything means every workflow in the repo has access to every secret, regardless of whether that specific workflow needs it. GitHub's environment-level secrets, combined with required reviewers or branch restrictions on that environment, let you scope a deployment credential so it's only accessible to workflow runs specifically targeting a protected environment — meaningfully narrower than blanket repository-level access.

## Reusable and self-hosted runner risks

Self-hosted runners execute workflow code on infrastructure you control, which means a compromised workflow (through a malicious PR, a compromised dependency pulled in during the job, or a compromised action) can potentially affect that underlying infrastructure directly, not just an ephemeral GitHub-hosted VM that's destroyed after the run. If self-hosted runners are used for anything handling untrusted input (like workflows triggered by external contributions), the isolation and cleanup between runs needs explicit attention that GitHub-hosted runners provide automatically.

## A practical checklist

- Set explicit, minimal `permissions` on every workflow rather than relying on defaults
- Pin third-party actions to a commit SHA, not a mutable tag
- Understand the secrets-access difference between `pull_request` and `pull_request_target`, and handle fork-supplied code with corresponding caution in the latter
- Adopt OIDC for cloud provider authentication instead of storing long-lived static credentials as secrets
- Use environment-level secrets with protection rules for anything tied to deployment, rather than defaulting to repository-level scope
- Treat self-hosted runner isolation as something requiring explicit configuration, not something GitHub-hosted runners' automatic cleanup provides for you

None of these individually make a pipeline "secure" — together, they reduce a CI/CD system's blast radius from "one compromised link exposes everything" to something meaningfully more contained.
