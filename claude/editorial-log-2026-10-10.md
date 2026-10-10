# Editorial log 2026-10-10

Two new articles published (no articles dated 2026-10-10 were on main at start). Dates 06:00Z and 06:05Z; pushed 06:08Z (the CSP post was first dated 06:10Z, which was in the future, so it was re-dated 06:05Z in a second push).

## Article 1: SPF, DKIM and DMARC (security-operations)
Slug: spf-dkim-and-dmarc-what-each-record-does-and-what-gmail-and-outlook-require
| Claim | Primary source | Source date / effective | Status | Scope or limitation |
|---|---|---|---|---|
| Gmail: >5,000 msgs/day to Gmail accounts need SPF, DKIM, DMARC (p=none allowed), alignment; spam rate <0.30%; TLS; one-click unsubscribe; PTR | Google email sender guidelines (support.google.com/a/answer/81126) | Effective 2024-02-01 | VERIFIED | Google also recommends <0.10%; both stated |
| Outlook.com: >5,000/day, SPF, DKIM, DMARC >= p=none aligned; Junk from 2025-05-05; rejection later, date TBA; 550 5.7.515 text | Microsoft Tech Community post | 2025-04-02, updated 2025-04-30 | VERIFIED | |
| Whether Microsoft has begun rejecting | No later official statement found; third parties conflict | | QUALIFIED | Stated as unconfirmed |
| SPF: HELO/MAIL FROM identities; 10 DNS terms; counted terms; 2 void lookups; permerror; qualifiers | RFC 7208 | 2014-04 | VERIFIED | First ~100k chars read |
| DKIM d=/s= and key lookup; Standards Track | RFC 6376 | 2011-09 | VERIFIED | STD number not confirmed, not stated |
| DMARC p/sp/rua, alignment, aspf/adkim, pct; RFC 7489 Informational | RFC 7489 | 2015-03 | VERIFIED | |
| RFC 9989 Standards Track, obsoletes 7489 and 9091; pct->t; np, psd; DNS Tree Walk (8 queries); reporting in 9990/9991 | RFC 9989 | 2026-05 | QUALIFIED | Appendix "Changes from RFC 7489" not read; no complete change list claimed; receiver behavior untested |
| SPF vs DKIM and forwarding | Derived from RFC definitions | | QUALIFIED | Explanation, no measured rate |

## Article 2: Content Security Policy (appsec)
Slug: content-security-policy-a-strict-nonce-based-policy-and-how-to-roll-it-out-safely
| Claim | Primary source | Status | Limitation |
|---|---|---|---|
| Strict CSP recommended; nonce per response/unpredictable; hashes for static; strict-dynamic cost; unsafe-inline guidance; Report-Only; Reporting-Endpoints/report-to; report-uri deprecated; frame-ancestors | MDN CSP guide | VERIFIED | MDN is a documentation source, not a standard |
| Strict CSP leading practice; middleware nonce warning; hash fragility; object-src/base-uri; fail-open report-only; not sole XSS defense | OWASP CSP Cheat Sheet | VERIFIED | |
| Report-only not in meta; CSP3 is a W3C Working Draft dated 2026-09-16 | W3C CSP3 | QUALIFIED | First part read; date as shown on fetch |
| Nonce differs per response and matches page | Own Node 22 test | QUALIFIED | Header mechanics only, no browser test |

## Corrections made during the run
- CSP post: removed a link claiming the REST API checklist covers security headers (it does not); linked the API misconfigurations post, which does.
- Removed an unsupported statement about SPF qualifier handling under DMARC.
- Re-dated CSP post from 06:10Z to 06:05Z (future-dated relative to push).
- Hero alt text rewritten after viewing cover.jpg: postcards on black (not envelopes); open padlock on a grille gate, black and white (not a closed padlock).

## Known limitations
- No live DNS or mail tests; no browser CSP tests; Hugo not installed, so build not tested locally.
- Microsoft rejection timing unconfirmed; RFC 9989 appendix unread.
- Postcard hero image is loosely related to email; padlock image is generic.
- Live-URL check results are in the run report, not in this log.

## Next-session candidates
1. HTTP security headers beyond CSP: HSTS, X-Content-Type-Options, Referrer-Policy, Permissions-Policy (MDN/OWASP).
2. SBOMs: CycloneDX vs SPDX and what CISA/NTIA minimum elements require.
3. Source the SIEM post (Sentinel/Splunk pricing models, Elastic/Wazuh licenses) or CISA KEV additions this week.
