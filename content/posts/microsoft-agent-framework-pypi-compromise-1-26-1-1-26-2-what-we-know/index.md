+++
title = "Microsoft agent-framework PyPI Compromise: What We Know"
date = 2026-11-19T04:25:00Z
tags = ["hacking news", "supply chain", "pypi", "python", "credential theft", "github actions", "azure", "ai agents"]
categories = ["ai-security"]
summary = "Two malicious releases of Microsoft's agent-framework Python package, 1.26.1 and 1.26.2, were on PyPI for under an hour on November 17, 2026. Both installed a .pth file that ran a credential stealer on every Python start. What is confirmed, what is not, and how to check your environments."
description = "agent-framework 1.26.1 and 1.26.2 on PyPI carried a credential stealer that ran on every Python start. Timeline, IOCs, what is unconfirmed and how to check."
author = "John Marshall"
imageAlt = "A heap of brown cardboard boxes and open cartons stacked against wooden shelving in a dim storeroom"
imageCredit = "Photo by [Tim Mossholder](https://unsplash.com/photos/RI_VrbUngcA) on Unsplash"
takeaways = [
  "Two releases of Microsoft's agent-framework package on PyPI, 1.26.1 and 1.26.2, were published on November 17, 2026 and were gone by about 21:30 UTC, according to Wiz. PyPI now lists 1.26.0 (November 12) as the latest release.",
  "Both releases dropped a .pth file into site-packages. Python executes import lines in .pth files at interpreter start, so the stealer ran on any Python start in that environment, even if nothing imported agent_framework.",
  "Researchers say the stealer collected cloud, CI and package-registry secrets, including GitHub Actions and Azure DevOps OIDC tokens and Azure managed-identity tokens, and posted them to a webhook.site URL.",
  "How the attacker got publishing access is not confirmed. Wiz says it appears a client certificate and private key for Microsoft's ESRP publishing service were compromised.",
  "If either version was installed anywhere, remove the payload files without starting that Python, rotate every secret the environment could read, and review Azure and GitHub federated identities."
]

[[faq]]
q = "Which agent-framework versions are malicious?"
a = "Versions 1.26.1 and 1.26.2 of the agent-framework package on PyPI, both published on November 17, 2026. Wiz names 1.26.0, published November 12, as the most recent safe version, and PyPI lists 1.26.0 as the latest release."

[[faq]]
q = "Was I affected if I never imported agent_framework?"
a = "Possibly. Both releases installed a .pth file into site-packages, and Python runs import lines in .pth files every time the interpreter starts. Any Python process in an environment where 1.26.1 or 1.26.2 was installed could run the stealer."

[[faq]]
q = "Is uninstalling the package with pip enough?"
a = "No. Starting Python in the affected environment can run the payload again, so Chainguard advises removing the files with shell tools first. Because the stealer sends data out on first run, you also need to rotate every credential the environment could read."

[[faq]]
q = "Who was behind the agent-framework compromise?"
a = "No one has been publicly attributed as of November 19, 2026. SecurityWeek reports that the publishing method remains unknown."
+++

**What happened:** On November 17, 2026, two releases of `agent-framework`, the Python package for Microsoft Agent Framework, were published to PyPI with a credential stealer inside. Versions 1.26.1 and 1.26.2 were available for under an hour, according to [Wiz](https://www.wiz.io/blog/malicious-version-of-microsofts-agent-framework-published-to-pypi). Both installed a `.pth` file that ran the stealer whenever Python started in that environment, and it collected cloud, CI and registry credentials. [SecurityWeek](https://www.securityweek.com/microsoft-agent-framework-releases-poisoned-with-credential-stealer/) reports that an Agent Framework maintainer confirmed on GitHub that the releases were removed and that an investigation is underway.

The package is not niche: SecurityWeek puts it at about 190,000 downloads a month. Any environment that resolved `agent-framework` without a pin in that window, on a developer laptop, a CI runner or a container build, may have installed one of the bad versions.

## Timeline (UTC)

| Time | Event | Source |
|---|---|---|
| Nov 12, 18:25 | Legitimate 1.26.0 published | Wiz; PyPI upload time 18:24:57 to 18:25:37 |
| Nov 17, 20:35:20 | Malicious 1.26.1 published | Chainguard (Wiz: 20:35) |
| Nov 17, 21:08:39 | Malicious 1.26.2 published, after PyPI had quarantined 1.26.1 | Chainguard (Wiz: about 21:08) |
| Nov 17, about 21:30 | Both versions no longer available on PyPI | Wiz |
| Nov 19, about 05:00 | PyPI's JSON API lists 1.26.0 as the latest version; 1.26.1 and 1.26.2 are absent | Our check of `pypi.org/pypi/agent-framework/json` |

[Chainguard](https://www.chainguard.dev/unchained/microsoft-agent-framework-compromised-on-pypi-november-2026) says its Chainguard Libraries mirror blocked 1.26.1 48 seconds after publication and 1.26.2 42 seconds after.

## Confirmed vs not confirmed

| Claim | Status | Who says so |
|---|---|---|
| 1.26.1 and 1.26.2 were malicious and removed from PyPI | Confirmed | Wiz, Chainguard, SecurityWeek; PyPI no longer lists them |
| 1.26.0 is the latest clean release | Stated by Wiz and SecurityWeek | Chainguard (writing earlier) did not name a safe version and advised suspicion of any release on Nov 17 or 18 |
| Microsoft is investigating | Reported | SecurityWeek, citing a maintainer's GitHub post; we found no Microsoft blog or advisory |
| How publishing access was obtained | **Not confirmed** | Wiz: the attacker "appears to have compromised a client certificate and private key" for Microsoft's ESRP signing and publishing service. SecurityWeek: "The method used to publish the malicious packages remains unknown." |
| A PyPI account created on the day of the attack was involved | **Not confirmed** | SafeDep, as reported by SecurityWeek, found a new maintainer account with publishing rights; its role in the uploads is unconfirmed |
| Victim data was stolen | Partly reported | Wiz says the webhook.site endpoint was on a free tier that caps at 50 requests, and it identified three unique successful exfiltrations among them |
| Who is behind it | **Not confirmed** | No attribution published |

Wiz also mentions an earlier, separate compromise of a Microsoft package (durabletask) and says the two incidents have not been linked.

## How the stealer ran

Both wheels added a `.pth` file to `site-packages`: `agent_framework_meta.pth` in 1.26.1 and `af_runtime_diag.pth` in 1.26.2. Python's [`site` module documentation](https://docs.python.org/3/library/site.html) explains why that is enough: in a `.pth` file, "lines starting with `import` (followed by space or tab) are executed with `exec()`." The `site` module processes these files at every interpreter start, so the payload ran on any `python` invocation in that environment, including test runs, linters and unrelated scripts. Python 3.15 deprecates `import` lines in `.pth` files, but they still execute during the deprecation period.

Per Wiz's analysis:

- **1.26.1** loaded `agent_framework_meta`, which called `_telemetry._start()`. It detached into a separate session or daemon thread and set `_AF_TEL=1` so it would not run twice.
- **1.26.2** loaded a new `af_runtime_diag.py` and restored the package's `__init__.py` to the clean 1.26.0 version. Hunting only for 1.26.1's file names misses it.

What it collected, as described by Wiz and Chainguard:

- Environment variables whose names contain words such as TOKEN, SECRET, KEY, AZURE, AWS, GITHUB and NPM, plus secrets read from other processes' `/proc/<pid>/environ`.
- Credential files including Azure CLI configuration, `.npmrc`, `pip.conf`, `.netrc`, `.git-credentials`, Docker `config.json` and Hugging Face tokens.
- Azure DevOps OIDC tokens and Azure managed-identity tokens. Wiz counts 12 Azure resources; Chainguard says nine resource types.
- In 1.26.2, GitHub Actions OIDC tokens for `api://AzureADTokenExchange` and `https://management.azure.com/`.

The data went out in one HTTPS POST to a webhook.site URL. Wiz notes that stolen Azure tokens may stay valid for up to 24 hours.

## Indicators of compromise

From Wiz's write-up:

| Type | Value |
|---|---|
| Files | `agent_framework_meta.pth`, `agent_framework_meta/_telemetry.py`, `af_runtime_diag.pth`, `af_runtime_diag.py` |
| Environment | `_AF_TEL=1` |
| Network | `webhook[.]site/d381fd80-ec62-42ad-8f5c-d1b15103c9bb`; User-Agents `af-runtime-diagnostics/1` (1.26.1) and `runtime-diagnostics/1` (1.26.2) |
| 1.26.1 wheel SHA-256 | `d27fa34414e6201d5e03e559ef634f020057554d7b3f4898dd5d7cd3e989e110` |
| 1.26.2 wheel SHA-256 | `3d20a8bc91351a9a16b6db243b848ceca0206b7a8623b02d2af553a9c9f7e0a9` |
| `af_runtime_diag.pth` SHA-256 | `325e7e9f0ec94e41ad1a1b7a3f18a6b8b5bffece2e2b97b8d3369eb967452f93` |
| `af_runtime_diag.py` SHA-256 | `54d885b7d7161c9ed96489c66364c4bfbf635929166843bba10d97d46b5a2e1f` |

Chainguard advises blocking the full webhook.site path rather than the whole domain if your teams use webhook.site for legitimate testing.

## What to check in your environment

**1. Find installs without starting Python.** Running `pip` or any Python tool in an affected environment starts the interpreter and can run the payload. Search the filesystem with shell tools instead. These commands use GNU `find` and `grep`; we tested them against a mock directory tree containing the IOC file names, not against the real malware.

```bash
# Files the two malicious wheels drop (search every filesystem you care about)
find / -xdev \( -name 'agent_framework_meta.pth' -o -name 'af_runtime_diag.pth' \
  -o -name 'af_runtime_diag.py' -o -type d -name 'agent_framework_meta' \
  -o -type d -name 'agent_framework-1.26.[12].dist-info' \) -print 2>/dev/null

# Pins and lockfile entries for the bad versions in a source tree
grep -rnE 'agent[-_]framework[ =<>~!"]*1\.26\.[12]\b' \
  --include='*.txt' --include='*.lock' --include='*.toml' --include='*.cfg' .
grep -rn -A1 'name = "agent-framework"' --include='*.lock' . | grep -E 'version = "1\.26\.[12]"'
```

Also check places a filesystem search will not cover: CI job logs from November 17-18 (look for `agent-framework-1.26.1` or `1.26.2` in resolver output), container image layers built in that window, and internal package mirrors that may have cached the wheels.

**2. Check egress.** Search proxy and DNS logs for the webhook.site path above. Wiz reads an HTTP 200 as data accepted and 410 or 429 as rejected, but treat any attempt as a reason to rotate.

**3. Clean, then rotate.** Remove the `.pth` and module files, then rebuild the environment from a pinned, known-good set (`agent-framework==1.26.0`). Rotate everything the environment could read: Azure CLI sessions, Azure DevOps PATs and service connections, npm, PyPI, NuGet, Docker and Hugging Face tokens, git credentials and cloud keys. Our guide to [detecting and rotating leaked API keys](/posts/how-to-detect-and-rotate-leaked-api-keys-before-attackers-use-them/) covers the order of operations.

**4. Review federated identities.** For GitHub Actions workflows that installed 1.26.2 with `id-token: write`, Wiz says to treat the OIDC tokens as exposed and review the Azure federated credentials that trust those workflows. Check Azure sign-in and activity logs for managed identities reachable from affected hosts.

## What engineers can take from it

- **Pin and hash-lock dependencies** in CI and image builds (`pip install --require-hashes`, or a lockfile with hashes). A floating `agent-framework` requirement pulled whatever was newest during the window.
- **A delay on brand-new versions helps.** Both releases were gone within about an hour. A mirror or resolver rule that waits before accepting fresh uploads would have skipped them. Chainguard's 42 to 48 second blocks show what a curated mirror can do.
- **Keep OIDC scopes narrow.** Grant `id-token: write` only to jobs that deploy, and bind cloud federated credentials to specific repositories, branches or environments. Our overview of [where build pipelines break](/posts/software-supply-chain-attacks-where-modern-build-pipelines-break/) covers the wider pattern.
- **Trusted publishers are not proof of safety.** If Wiz's reading of the ESRP credentials is right, the releases came through Microsoft's own publishing path. Provenance tells you where a package was built; it does not tell you the build was intended. See [what SLSA provenance does and does not prove](/posts/slsa-build-levels-and-provenance-attestations-what-they-prove-and-what-they-dont/).

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| Affected versions, timeline, ESRP credential reading, payload behaviour, IOCs, three exfiltrations | [Wiz](https://www.wiz.io/blog/malicious-version-of-microsofts-agent-framework-published-to-pypi) | Qualified (researcher analysis) |
| Second-level timeline, .pth mechanism, "remove the payload before starting Python again" | [Chainguard](https://www.chainguard.dev/unchained/microsoft-agent-framework-compromised-on-pypi-november-2026) | Qualified (researcher analysis) |
| Maintainer confirmation, ~190,000 monthly downloads, publishing method unknown, SafeDep account finding | [SecurityWeek](https://www.securityweek.com/microsoft-agent-framework-releases-poisoned-with-credential-stealer/) | Qualified (press report) |
| 1.26.0 is the latest listed release; 1.26.1 and 1.26.2 absent | PyPI JSON API for agent-framework, checked Nov 19, 2026 | Verified |
| `.pth` import lines are executed at startup | [Python `site` documentation](https://docs.python.org/3/library/site.html) | Verified (verbatim) |
