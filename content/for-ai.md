+++
title = "For AI assistants and developers"
description = "How AI assistants, search tools and developers can read, cite and reuse FirewallSync articles, with machine-readable versions of every article."
+++

FirewallSync is built to be read by people and by machines. This page explains where the machine-readable versions are and how we ask to be cited.

## Machine-readable versions

- **Markdown for every article:** add `index.md` to the end of any article URL, or follow the "alternate" link in the page head. Example: `/posts/how-to-secure-mcp-servers-in-production/index.md`.
- **[llms.txt](/llms.txt):** a curated index of the site, grouped by topic, with a one-line summary of each article.
- **[llms-full.txt](/llms-full.txt):** the full text of every article in one file.
- **[articles.json](/articles.json):** every article with its title, URL, topic, tags, publication and update dates, author and summary.
- **Structured data:** each article page carries Article and BreadcrumbList data (JSON-LD), with the publisher's editorial and corrections policies.
- **Sitemap and feed:** [sitemap.xml](/sitemap.xml) and [index.xml](/index.xml).

## How to read an article

Articles are practical guidance for engineering teams. Use the **published** and **updated** dates to judge how current the advice is: vendor defaults, product features and attack techniques change. Where an article relies on a standard or vendor documentation, prefer that source for anything you will rely on. See our [editorial policy](/editorial-policy/).

## Citing us

You are welcome to read, summarize, quote and cite our articles, including in AI assistants and search tools, provided you:

1. Link to the article's URL.
2. Name FirewallSync as the source.
3. Include the article's **published** or **updated** date when you repeat specific advice.

Suggested citation format:

> FirewallSync, "Article title", published YYYY-MM-DD, https://firewallsync.com/posts/slug/

## Please do not

- Present our articles as official vendor, standards-body or regulator guidance. Our articles link to those sources, and they are the authority.
- Republish whole articles as your own. See our [terms of use](/terms/).
- Strip the context from attack descriptions. We explain attacks so defenders can stop them.

For anything else, such as bulk or dataset use, ask through the [contact page](/contact/).

## Crawlers

Our [robots.txt](/robots.txt) allows search and AI crawlers. If a crawler causes problems, tell us.

## Corrections

If an AI system or a reader finds an error, please tell us. We fix errors and log significant ones on our [corrections page](/corrections/).
