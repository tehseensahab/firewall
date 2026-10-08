# Editorial log 2026-10-08

Mode: AUDIT ONLY. Two posts dated 2026-10-08 (09:00Z) were already on main, so no new articles were written. Audit ran ~06:10 UTC, before they went live. Live-URL checks not possible yet.

## Corrections made
| Article | Claim as found | Source check | Status / change |
|---|---|---|---|
| Password managers | 1Password "meaningfully more expensive per seat" | 1Password business pricing not retrievable | NOT VERIFIED; removed, reader pointed to pricing page |
| Password managers | Travel Mode / Watchtower in 1Password business | Confirmed only on personal-plan pricing page | Qualified |
| Password managers | Bitwarden "lower price point"; SSO on paid tiers | bitwarden.com/pricing/business (2026-10-08): Teams $4, Enterprise $6/user/mo annual; SSO + self-host listed under Enterprise | Replaced with sourced prices |
| Password managers | Vaultwarden "runs on hardware that would struggle" | README: lighter alternative, not associated with Bitwarden | Reworded to README |
| Password managers | Admin gap "generally considered"; "far more common causes of incidents" | No sources | Labelled as editorial judgement |
| Token theft | Evilginx / "works across M365, Google Workspace, most SSO" | Microsoft Threat Intelligence, 2022-07-12: Evilginx2, >10,000 orgs; no Google/SSO coverage | Sourced; platform claim removed |
| Token theft | Mitigation advice | Same Microsoft report: FIDO2, conditional access | Cited |
| Token theft | "produces neither" | General | Hedged ("typically") |

## Known limitations
- 1Password business pricing, SSO and feature tiers unverified. Bitwarden full feature table was truncated in fetch.
- Token-theft detection and session-lifetime advice remains general practice, not cited. Impossible-travel guidance not sourced.
- Password manager post byline "Tehseen Arbab" differs from the "FirewallSync Editorial" used elsewhere; not changed.
- No public fact-check table in either post. Hugo not installed here, so build not tested. Duplicate hero images in covers.tsv from the 10-07 log remain unfixed.

## Next-session candidates
1. Audit 2026-10-09 pair (AWS IAM least privilege; open-source vs commercial SIEM).
2. Fix duplicate hero images in covers.tsv.
3. Source 1Password business pricing and re-verify the comparison.
