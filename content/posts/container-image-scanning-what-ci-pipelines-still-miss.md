+++
title = "Container Image Scanning: What CI Pipelines Still Miss"
date = 2026-09-28T09:00:00Z
tags = ["appsec", "cloud security"]
summary = "Image scanning in CI catches known CVEs in base layers, but most pipelines still ship vulnerable configs and secrets that scanners aren't tuned to see."
description = "Container image scanning in CI catches CVEs but misses config drift and runtime secrets. Here's what to add to close the gap."
author = "FirewallSync Editorial"
+++

Most teams that added container scanning to CI did it for one reason: catch known CVEs before a vulnerable base image ships to production. That part works well now — scanners are mature and fast. What they consistently miss is everything that isn't a CVE: misconfigurations, embedded secrets, and drift between what was scanned and what actually runs.

## Scanning the image isn't scanning the runtime config

A clean scan on the image itself says nothing about the Kubernetes manifest or Helm chart that deploys it — a container with zero CVEs can still run as root, mount the host filesystem, or expose a debug port to the internet. If your pipeline only gates on image scan results, add a separate policy check on the deployment manifest (tools like Kubernetes admission controllers or policy-as-code frameworks catch this class of issue that image scanners structurally can't).

## Secrets baked in during build, not commit

Scanners tuned to catch secrets in source code miss keys that get pulled in during the Docker build itself — a `COPY .env .` line, a build arg that ends up baked into a layer, or a credential fetched mid-build and never cleaned up. Audit your Dockerfiles specifically for this pattern; it's one of the more common ways a key ends up in a public registry months after anyone remembers it was there.

## The scan-to-deploy gap

A pipeline that scans on merge but deploys hours or days later is scanning against a CVE database that's already stale by deploy time. If a critical CVE gets published for a package already baked into a pending release, nothing in the pipeline re-checks it. Add a scheduled re-scan of images already in your registry, not just at build time — this is the difference between catching a zero-day the week it's disclosed versus the next time someone happens to rebuild.
