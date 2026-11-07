# DAILY.md — owner overrides for the scheduled run

Where this file conflicts with the scheduled prompt, this file wins.

## Hacking-news trial: runs dated 2026-11-08 to 2026-11-22 (15 runs)

Owner decision 2026-11-07: test whether recent hacking news brings traffic. Outside these dates, ignore this section and follow the normal prompt.

### What changes
- **Article A:** unchanged (spec/cluster explainer per SEO FOCUS).
- **Article B:** always one hacking-news story. This replaces SEO FOCUS rule 2 and the "max 2 timely CVE posts per week" cap for these 15 runs.
- Tag every news post `"hacking news"` in tags. Use an existing category (usually security-operations; cloud-security, identity-access or ai-security when it fits). Do not create new categories.
- Add `[news]` at the end of its INDEX.md row so the trial can be measured.

### Picking the story
- A cyber incident publicly reported in the last 72 hours (stretch to 7 days if nothing qualifies): breaches, ransomware that disrupts real services (retail, transport, hospitals, factories), crypto exchange or DeFi hacks, large account takeovers, hacktivist or state-linked operations, outages caused by attacks.
- Prefer stories with mainstream curiosity (well-known brand, visible real-world effect, large sums, many people affected) AND something engineers can learn from.
- Must not repeat a story already in INDEX.md, unless there is a substantial new development (then write a follow-up and link the original).
- Search with WebSearch (try "extended" mode for very recent events), then WebFetch the results.

### Accuracy gate (punchy headline, sourced body)
- Confirm the core event from at least one primary source (victim company statement or filing, regulator, police or government agency, the affected vendor, a court document, or on-chain data cited by a named analytics firm), OR two independent established outlets. If it can't be confirmed, skip the story.
- Every number (users affected, money stolen, stores closed) must be attributed to who said it.
- Attribution to a group or country is stated only as "X claims" or "Y attributes it to"; never as our fact.
- Rumours, leak-site claims and social-media theories go in a clearly labelled "What is not confirmed" section, or are left out. Never present speculation as fact.
- Never link to leak sites, never republish leaked data, never name or expose private individuals.
- If facts change after publishing, add a dated "Update" line at the top rather than rewriting silently.

### Headline and structure
- Title 60 characters or fewer, concrete and curiosity-driven, but every word backed by the body: who + what happened + the hook. Good: "Binance Hot Wallet Drained: What We Know About the $X Hack". Bad: "Is This the Hack That Ends Crypto?"
- Description 140-160 chars, answer-first.
- Suggested body: what happened (2-3 sentences up top) → timeline → confirmed vs not-confirmed table → how the attack worked (only as far as sources say) → what it means for engineers / what to check in your own environment → sources.
- 1-2 internal links to relevant live posts where natural (no forced cluster links); the cluster-link minimum in SEO FOCUS rule 5 still applies to Article A.
- Calm, factual tone in the body; no fear language, no "conspiracy" framing.

### Reporting
- In the editorial log, add a "News trial" line per run: story, why chosen, primary source used.
- After 2026-11-22, the next run notes in its report that the trial has ended and the owner should review GSC for the [news] rows.
