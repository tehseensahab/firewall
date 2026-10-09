# Editorial log 2026-10-09

Mode: AUDIT ONLY. Two posts dated 2026-10-09 (AWS IAM least privilege; open source vs commercial SIEM) were already on main, so no new articles were written. Both were re-dated 05:00Z so they build on this push (previously 09:00Z). Live-URL check not possible from this run before the Cloudflare build finishes.

## Corrections made
| Article | Claim as found | Source check | Status / change |
|---|---|---|---|
| AWS IAM | Access Analyzer "can generate a refined policy based on actual access activity" | AWS docs, policy generation: CloudTrail-based, up to 90 days, no action-level data events, no iam:PassRole, includes denied actions, needs a trail | Qualified; limits and link added |
| AWS IAM | Unused access analysis lists unused roles, keys, passwords, actions | Search results quoting AWS docs (access-analyzer-create-unused, findings pages); direct page fetch returned no body | Qualified (secondary retrieval of AWS doc text) |
| AWS IAM | (omitted) tracking period and cost | Tracking period 1-365 days; paid per role/user analyzed per month; external access free. Per-role rate NOT retrieved | Added, no dollar figure given |
| AWS IAM | "continuously analyzes" | Not directly confirmed | Left as is; NOT VERIFIED |
| SIEM | Commercial rule libraries, volume-based pricing, "no licensing fee" for OSS | No sources in post; Elastic license terms not checked | Labelled as editorial analysis; license caveat added; NOT VERIFIED as fact |
| Both | Hero alt text | Opened cover.jpg: server racks with cables; web performance dashboard | Alt text rewritten in post and covers.tsv |

## Known limitations
- SIEM post has no cited sources and no vendor pricing; claims remain general industry judgement.
- Byline differs between posts ("FirewallSync Editorial" vs "Tehseen Arbab"); not changed.
- SIEM hero image is a web-performance dashboard, not a security tool; accurate alt text, weak topical fit.
- No public fact-check table; Hugo build not tested here.

## Next-session candidates
1. Source the SIEM post: Microsoft Sentinel and Splunk pricing models, Elastic/Wazuh licenses.
2. Fix duplicate hero images in covers.tsv (carried over from 10-07 log) and 1Password business pricing re-verification.
3. New topic: CISA KEV catalog entries added this week, or Access Analyzer unused-access setup walkthrough.
