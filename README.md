# FirewallSync

Hugo site for firewallsync.com — practical cybersecurity writing for engineering teams.

## Local preview

```
hugo server --buildFuture
```
Visit http://localhost:1313 (`--buildFuture` shows scheduled posts too).

## Add a post

Posts are leaf bundles (`content/posts/<slug>/index.md`, optionally with `cover.jpg`):

```
hugo new content posts/my-post-slug
scripts/cover.sh <image-url> content/posts/my-post-slug   # optional cover
```

Front matter used by the templates: `title`, `date`, `summary` (lead and card text), `description` (meta description, llms.txt), `categories` (exactly one of the slugs below), `tags`, `author`, plus optional `imageAlt`, `imageCredit`, `takeaways` (list) and `faq` (list of `q`/`a`, emitted as FAQPage JSON-LD).

Categories: `ai-security`, `appsec`, `identity-access`, `cloud-security`, `security-operations`, `privacy-risk`, `fundamentals`. Their titles and descriptions live in `content/categories/<slug>/_index.md`. A category with no published posts yet is hidden from the nav and topic grid until its first post goes live. Tag display names live in `content/tags/<tag>/_index.md`.

Covers are processed with `.Fill "1200x630 webp q80"` (needs Hugo extended); without `cover.jpg` the card shows a styled placeholder and social tags fall back to `/og-default.jpg`.

## Scheduled posts

Future-dated posts publish when the site is rebuilt after their date. `.github/workflows/daily-rebuild.yml` calls the Cloudflare Pages deploy hook (`CLOUDFLARE_DEPLOY_HOOK_URL` secret) daily at 09:15 UTC.

## AI-friendly outputs

- `/llms.txt` — curated index by topic; `/llms-full.txt` — full text of every article
- `/articles.json` — every article with metadata
- `<article-url>index.md` — plain-markdown version of each page
- `/for-ai/` — citation guidance; `robots.txt` allows search and AI crawlers

## Deploy (Cloudflare Pages)

- Build command: `hugo --minify`
- Build output directory: `public`
- Environment variable `HUGO_VERSION` = `0.140.2` (the extended build is used by Cloudflare's Hugo preset)
