# FirewallSync

Hugo static site for firewallsync.com — cybersecurity blog seeded for guest-post demand testing.

## Local dev
```
hugo server
```

## Deploy (Cloudflare Pages)
- Connect this GitHub repo in Cloudflare Pages
- Build command: `hugo --minify`
- Build output directory: `public`
- Set environment variable `HUGO_VERSION` = `0.140.2`
- Point firewallsync.com DNS/nameservers at Cloudflare, add as custom domain in Pages project settings

## Adding a new post
Create a new file in `content/posts/your-slug.md`:
```toml
+++
title = "Your Title"
date = 2026-09-23
tags = ["tag1"]
summary = "One or two sentence summary shown on the homepage/list."
+++

Post body in Markdown.
```
Commit and push — Cloudflare rebuilds automatically.
