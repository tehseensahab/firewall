+++
title = "GitHub Actions OIDC: Stop Storing Cloud Credentials in CI/CD"
date = 2026-11-02T09:00:00Z
tags = ["appsec", "iam"]
summary = "A static cloud credential stored as a CI secret is valid until someone notices it's wrong. An OIDC-issued credential is valid for one workflow run and expires whether anyone notices or not."
description = "How GitHub Actions OIDC works technically, how to configure the AWS trust relationship, and why short-lived tokens change the actual risk profile of CI/CD credentials."
author = "FirewallSync Editorial"
+++

A static cloud credential — an AWS access key, a GCP service account key — stored as a GitHub Actions secret has one fundamental property that makes it a standing risk: it remains valid until someone actively notices it shouldn't be and rotates it. OpenID Connect (OIDC) support in GitHub Actions removes that credential from the equation entirely, replacing it with a token that's short-lived by design and requires no manual rotation discipline to stay safe.

## How the exchange actually works

When a workflow configured for OIDC runs, GitHub's Actions runner requests a JSON Web Token (JWT) from GitHub's own OIDC provider (`token.actions.githubusercontent.com`). This token contains claims about the workflow run — which repository, which branch or ref, which workflow file — and is signed by GitHub. The workflow then presents this token to the cloud provider (AWS STS, for example), which has been configured ahead of time to trust GitHub's OIDC provider and to check specific claims in the token before issuing temporary credentials. If the claims match what the trust policy expects, the cloud provider issues short-lived, scoped credentials good only for that specific workflow run.

No static credential is stored anywhere in this flow. The only thing GitHub holds is a role ARN or equivalent identifier telling it which role to request — the actual authentication happens fresh, per run, through the signed token exchange.

## Setting up the AWS side of the trust relationship

Configuring this requires two things in AWS: registering GitHub's OIDC provider as a trusted identity provider in IAM, and creating an IAM role with a trust policy that specifies exactly which GitHub repositories (and optionally, which branches or environments) are allowed to assume it. A typical trust policy condition restricts the `sub` claim to a specific pattern like `repo:your-org/your-repo:ref:refs/heads/main`, meaning only workflow runs on that exact branch, in that exact repository, can successfully assume the role — a workflow run from a fork, or from a different branch, will have a token with a `sub` claim that doesn't match, and the assume-role call will simply fail.

This scoping is what makes OIDC meaningfully more secure than a static credential even beyond the "no long-lived secret" property — the trust relationship itself constrains which workflows can even attempt to use it, rather than relying on the credential's holder being trustworthy by assumption.

## The workflow-side configuration

The workflow needs explicit `permissions: id-token: write` set — this is the permission that allows the job to request an OIDC token from GitHub in the first place, and it's not granted by default even when other broad permissions are set. Combined with an action like `aws-actions/configure-aws-credentials`, specifying the target role's ARN, the workflow requests the token, performs the exchange with AWS STS, and receives temporary credentials scoped to that role — all without a static `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` appearing anywhere in the workflow or in GitHub's secret storage.

## Why the "short-lived" property matters beyond convenience

A leaked static credential is a live problem until someone notices and rotates it — which could be minutes or months, depending entirely on whether monitoring catches the exposure. An OIDC-issued credential, even if somehow captured mid-flight during a specific run, expires on its own shortly after that run completes, typically within the hour. This changes the actual risk calculus: the attacker's usable window is bounded by design, rather than bounded by however quickly your team happens to detect and respond to a leak.

## What OIDC does not solve

OIDC removes the specific risk of a long-lived credential leaking from CI storage. It doesn't address other CI/CD security concerns: a compromised workflow can still assume the role and act with whatever permissions that role grants during its valid window, so scoping the IAM role's own permissions narrowly still matters exactly as much as it did with static credentials. It also doesn't protect against a malicious pull request modifying the workflow file itself to add unauthorized steps, if the workflow's trigger configuration allows untrusted code to influence what runs — that's a separate class of risk (`pull_request_target` misuse, in particular) that OIDC doesn't touch.

## Multi-cloud and cross-provider considerations

AWS, Google Cloud, and Azure all support this pattern under slightly different names (AWS calls it "Web Identity Federation," GCP calls it "Workload Identity Federation") but the underlying mechanism — trusting GitHub's OIDC provider and issuing short-lived credentials based on token claims — is conceptually the same across all three. If your pipeline deploys to multiple clouds, this pattern is worth implementing consistently across all of them rather than only for whichever provider had the most convenient existing tutorial.

## A practical checklist

- Register GitHub's OIDC provider in your cloud provider's IAM configuration
- Write the trust policy's conditions narrowly — specific repository, specific branch or environment, not a broad wildcard match
- Set `permissions: id-token: write` explicitly on any workflow using OIDC
- Remove any existing static cloud credentials stored as GitHub secrets once OIDC is confirmed working, rather than leaving both in place indefinitely
- Scope the IAM role's own permissions narrowly — OIDC changes how the credential is obtained, not how much access the resulting credential should have

Migrating from static credentials to OIDC is one of the highest-leverage changes available for CI/CD security, precisely because it eliminates an entire category of leak (a long-lived secret sitting in storage) rather than just making that category harder to exploit.
