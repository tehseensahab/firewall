# Editorial log 2026-10-07

Mode: AUDIT ONLY. Two posts dated 2026-10-07 (09:00Z) were already on main before this run, so no new articles were written. The Project's earlier editorial logs were not accessible from this session.

## Corrections made (commit on main)
| Article | Claim as found | Source check | Status / change |
|---|---|---|---|
| OAuth tokens | RFC 9700 "requires" PKCE for all client types | RFC 9700 s2.1.1: public clients MUST; confidential RECOMMENDED | Corrected |
| OAuth tokens | RFC 9700 "formally deprecates" implicit grant; OAuth 2.1 "removes" it | s2.1.2: SHOULD NOT unless injection prevented; OAuth 2.1 still an IETF Internet-Draft | Corrected, qualified |
| OAuth tokens | RFC says invalidate the whole token family on refresh-token reuse | s4.14.2: AS revokes the active refresh token; family revocation is an implementation reading | Corrected, labelled as interpretation |
| OAuth tokens | Rotation applies generally | s2.2.2: public clients MUST be sender-constrained or rotated | Qualified |
| OAuth tokens | Token logging/lifetime advice, "more codebases than it should be" | Not found in RFC text read | Labelled general practice / removed |
| PII | Birthdate+gender+ZIP identifies "large majority" of US | Sweeney 87% (1990 census); Golle 63% (2000 census) | Sourced, qualified |
| PII | GDPR scope of IPs/device IDs | Art. 4(1), Recital 30 | Cited, hedged |
| PII | "Treat session tokens as PII" / "most frameworks" | Opinion | Reworded as policy, not legal conclusion |
| OAuth tokens | Hero alt text | Image inspected | Made more specific |

## Known limitations
- Only the first ~100k characters of RFC 9700 plus s4.14.2 were read via fetch; token-lifetime/logging guidance not verified.
- Posts are scheduled for 09:00Z; deploy hook runs 09:15Z. Live URLs not yet checkable at audit time (06:xx UTC).
- scripts/covers.tsv: photo ids 1594915440248-1e419eba6611 and 1698668975271-2ba9a323be6b are each used by two posts (api-rate-limiting / citrix-netscaler; zero-trust-vs-vpn / ssrf-explained). Not fixed.
- Pre-existing, future-dated posts run through 2026-12-03; their facts were not audited.

## Next-session candidates
1. Audit the 2026-10-08 pair (password manager comparison; token theft vs MFA) before they go live.
2. Replace duplicate hero images in covers.tsv.
3. A new topic only when a date has no two posts scheduled.
