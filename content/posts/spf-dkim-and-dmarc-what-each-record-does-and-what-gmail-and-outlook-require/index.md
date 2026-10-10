+++
title = "SPF, DKIM and DMARC: What Each Record Does and What Gmail and Outlook Require"
date = 2026-10-10T06:00:00Z
tags = ["authentication", "compliance"]
categories = ["security-operations"]
summary = "SPF, DKIM and DMARC answer three different questions about a message. Here is what each record checks, how alignment ties them together, what Google and Microsoft require from high-volume senders, and a rollout order that avoids blocking your own mail."
description = "What SPF, DKIM and DMARC each verify, how DMARC alignment works, the Gmail and Outlook.com bulk sender requirements, and the DMARC update in RFC 9989."
author = "FirewallSync Editorial"
imageAlt = "Five vintage handwritten postcards with stamps and postmarks spread on a black surface"
imageCredit = "Photo by [rc.xyz NFT gallery](https://unsplash.com/photos/oathFTcFigc) on Unsplash"
takeaways = [
  "SPF checks whether the sending server's IP address is authorized for the envelope sender domain. DKIM checks a cryptographic signature added by a signing domain. DMARC requires one of them to pass and to align with the domain in the visible From address.",
  "A DMARC record with policy p=none satisfies the Gmail and Outlook.com requirements for high-volume senders, but it asks receivers to take no action on spoofed mail. Protection starts at quarantine or reject.",
  "Google's requirements have applied since February 1, 2024 to senders of more than 5,000 messages per day to Gmail accounts. Microsoft's Outlook.com requirements took effect May 5, 2025 for domains sending more than 5,000 emails per day.",
  "SPF allows at most 10 DNS-querying terms per evaluation. Exceeding that returns a permanent error, which is why stacking vendor include entries eventually breaks the record.",
  "In May 2026 the IETF published RFC 9989, a Standards Track version of DMARC that obsoletes RFC 7489. It replaces the pct tag with a t tag and adds np and psd tags."
]

[[faq]]
q = "Do I need all three of SPF, DKIM and DMARC?"
a = "To meet Google's bulk sender requirements (more than 5,000 messages per day to Gmail accounts) you need SPF, DKIM and a DMARC record, and the From domain must align with the SPF or DKIM domain. Microsoft's Outlook.com requirements for domains sending more than 5,000 emails per day also name all three. Below those volumes the requirements differ, but the three records together are what let a receiver tell your mail from a forgery."

[[faq]]
q = "Is p=none enough?"
a = "It is enough to satisfy the DMARC requirement in both the Google and Microsoft high-volume sender rules, which accept a policy of none. It does not ask receivers to quarantine or reject mail that fails DMARC, so it does not stop someone spoofing your domain. Its value is the reporting you receive while you find every legitimate sender."

[[faq]]
q = "What is the SPF 10-lookup limit?"
a = "RFC 7208 section 4.6.4 limits SPF evaluation to 10 DNS-querying terms: the include, a, mx, ptr and exists mechanisms and the redirect modifier. The ip4, ip6 and all mechanisms do not count. Going over the limit produces a permerror result, and DMARC then cannot use SPF as the passing method."

[[faq]]
q = "Why does SPF often fail for forwarded mail?"
a = "SPF compares the connecting server's IP address with the list published by the envelope sender domain. A forwarding server is not on your list, so the check does not pass at the final recipient unless the forwarder rewrites the envelope sender. DKIM signatures usually survive simple forwarding because they travel inside the message, which is one reason to deploy both."

[[faq]]
q = "Does RFC 9989 replace my existing DMARC record?"
a = "RFC 9989 (May 2026) obsoletes RFC 7489 and changes some tags: pct is replaced by t, and np and psd are added. We did not test how individual receivers handle the new tags. Check each tag against your mail receivers' documentation before relying on a change."
+++

SPF, DKIM and DMARC are three DNS-based email authentication methods, and each answers a different question. SPF asks whether the server that delivered a message is allowed to send for a domain. DKIM asks whether a signature on the message verifies against a public key the signing domain published. DMARC asks whether at least one of those two checks passed *for the same domain the reader sees in the From address*, and tells receivers what to do if neither did. If you send more than 5,000 messages a day to Gmail or Outlook.com consumer addresses, you need all three. If you send less, they are still how a receiver tells your mail from a forgery.

This article explains what each record checks, where they commonly break, what Google and Microsoft require, and a rollout order that does not block your own mail. It is a research-based explainer: we did not send test mail through Gmail or Outlook.com, and where we could not confirm a detail from a primary source we say so.

## What each record checks

| | SPF | DKIM | DMARC |
|---|---|---|---|
| Full name | Sender Policy Framework | DomainKeys Identified Mail | Domain-based Message Authentication, Reporting and Conformance |
| What it checks | The connecting server's IP address against the domain's published list | A cryptographic signature in a message header, checked against a public key in DNS | That SPF or DKIM passed **and** that the passing domain aligns with the From domain |
| Which domain | The HELO name and the envelope sender (MAIL FROM) domain | The domain in the signature's `d=` tag | The domain in the visible From header |
| DNS record | TXT record at the domain | TXT record at `<selector>._domainkey.<domain>` | TXT record at `_dmarc.<domain>` |
| Defined in | RFC 7208 (April 2014) | RFC 6376 (September 2011) | RFC 9989 (May 2026), replacing RFC 7489 (March 2015) |

Two terms need defining. The **envelope sender** is the address given to the receiving mail server in the SMTP conversation, also called MAIL FROM or the reverse-path. It is not the same as the **From header** your mail client displays. RFC 7208 specifies that SPF verifiers check the HELO and MAIL FROM identities, and that checking other identities is not recommended. SPF on its own therefore says nothing about the From address a person reads, which is the gap DMARC closes.

### SPF

An SPF record lists who may send for a domain. A minimal example for a domain that sends through Google Workspace and one other provider:

```
example.com.  TXT  "v=spf1 include:_spf.google.com include:mail.provider.example -all"
```

The ending is a qualifier plus the `all` mechanism. RFC 7208 defines `+` (pass), `-` (fail), `~` (softfail) and `?` (neutral); with no qualifier, `+` is assumed. `-all` says anything not listed should fail. `~all` (softfail) is weaker. We did not verify how individual receivers treat the two when SPF is combined with DMARC, so do not assume they behave identically.

The constraint that surprises teams is the lookup limit. RFC 7208 section 4.6.4 says implementations must limit DNS-querying terms to 10 per evaluation. The `include`, `a`, `mx`, `ptr` and `exists` mechanisms and the `redirect` modifier count; `ip4`, `ip6` and `all` do not. Exceeding 10 produces a `permerror`. The same section says implementations should allow no more than two void lookups (queries returning an empty answer or NXDOMAIN) and also returns `permerror` past that. Each `include` can itself contain more terms that count, so a record with several marketing, support and billing vendors can pass review and still fail at evaluation. Count the terms after expanding every include.

### DKIM

DKIM signs selected headers and the body of each message. The signing domain is named in the `d=` tag and the selector in the `s=` tag; RFC 6376 combines them to build the DNS name of the public key. Its example is `d=example.com` with `s=foo.bar`, which is looked up at `foo.bar._domainkey.example.com`. Selectors let one domain hold several keys at once, which is how you run separate keys for separate vendors and rotate them without downtime.

Because the signature travels inside the message, DKIM usually survives plain forwarding, whereas SPF is tied to the connecting IP address. That explains the standard advice to deploy both rather than choose one. We did not find, and do not claim, a figure for how often each method survives forwarding in practice.

### DMARC and alignment

A DMARC record is published at `_dmarc.<domain>`:

```
_dmarc.example.com.  TXT  "v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com"
```

RFC 7489 defines three policies in the `p` tag: `none` (no specific action requested), `quarantine` (treat failing mail as suspicious) and `reject` (reject failing mail, ideally during the SMTP transaction). The `sp` tag sets a different policy for subdomains and, if absent, `p` applies. The `rua` tag lists where to send aggregate reports; per RFC 7489, if `rua` is absent, no aggregate reports are generated.

**Alignment** is the part that makes DMARC more than "SPF or DKIM passed." RFC 7489 requires that the From domain match the domain that SPF or DKIM authenticated. In *relaxed* mode, the two only need the same Organizational Domain (for example `mail.example.com` aligns with `example.com`). In *strict* mode, only an exact match of the fully qualified domain names counts. The `aspf` and `adkim` tags choose the mode for SPF and DKIM separately and both default to relaxed.

This is why mail from a third-party platform can pass SPF yet fail DMARC. If the vendor sends with its own envelope sender domain, SPF passes for the vendor's domain, which does not align with your From domain. The fix is usually to have the vendor sign with a DKIM key under your domain, or to configure a custom return-path domain, so that at least one method passes *and* aligns.

## What Google and Microsoft require

Both providers state requirements for high-volume senders. The thresholds and scope are specific, so read them before assuming they apply to you.

| | Google (Gmail) | Microsoft (Outlook.com) |
|---|---|---|
| Who is covered | Senders of more than 5,000 messages per day to Gmail accounts | Domains sending more than 5,000 emails per day to Outlook.com consumer domains (hotmail.com, live.com, outlook.com) |
| Effective | February 1, 2024 | May 5, 2025 |
| SPF and DKIM | Required for the sending domain | SPF must pass; DKIM must pass |
| DMARC | Required; the enforcement policy "can be set to none" | Policy of at least `p=none`, aligned with SPF or DKIM (both preferred) |
| Alignment | From domain must align with the SPF domain or the DKIM domain | Same, per the announcement |
| Other | Spam rate in Postmaster Tools kept below 0.30%; TLS; valid forward and reverse DNS; one-click unsubscribe for marketing and subscribed messages | Non-compliant mail is routed to Junk from May 5, 2025; Microsoft says rejection will follow on a date to be announced |

Two cautions on that table. First, Google's page also recommends keeping the spam rate below 0.10% and avoiding 0.30% or higher; the two figures are a recommendation and a threshold, not one rule. Second, for Microsoft we read the announcement published April 2, 2025 and updated April 30, 2025. It says rejected messages will carry the code `550; 5.7.515 Access denied, sending domain [SendingDomain] does not meet the required authentication level`, but we found no later official Microsoft statement giving a rejection date. Third-party sources disagree about whether and when rejection began, so we treat the date as unconfirmed. Planning to the stricter outcome costs little.

These rules apply by volume and recipient, not by who you are. A 200-message-per-day sender is outside the stated thresholds but still benefits from the same records, because the records are what stop other people using your domain.

## The DMARC update: RFC 9989

In May 2026 the IETF published RFC 9989, which is on the Standards Track and obsoletes RFC 7489 (an Informational document published in March 2015) and RFC 9091. The reporting formats move to companion documents, RFC 9990 and RFC 9991. From the parts of RFC 9989 we read, the changes that affect a record are:

- The `pct` tag is replaced by a `t` tag for DMARC policy test mode.
- An `np` tag sets the policy for non-existent subdomains.
- A `psd` tag lets public suffix operators flag a Public Suffix Domain.
- The Organizational Domain is no longer found using the Public Suffix List. A "DNS Tree Walk" with a limit of eight DNS queries replaces it.

We could not read the whole document, including its "Changes from RFC 7489" appendix, so this is not a complete change list. We also did not test how Gmail, Outlook.com or other receivers treat the new tags. Until a receiver documents otherwise, keep `v=DMARC1` records that you have verified working, and change tags deliberately rather than all at once.

## A rollout order that does not block your own mail

1. **Inventory senders.** List every system that sends mail with your domain in the From address: corporate mail, marketing platform, help desk, billing, CRM, monitoring alerts, applications. The shadow senders are the usual cause of surprises. Our guide to [auditing SaaS apps connected to your company](/posts/saas-security-how-to-audit-oauth-apps-connected-to-your-company/) is a useful starting point for finding them.
2. **Publish DMARC at `p=none` with a `rua` address.** This changes no delivery behavior and starts aggregate reports. Use a mailbox or reporting service that can parse them; the reports are XML.
3. **Fix alignment per sender.** For each source in the reports, make DKIM sign with your domain or align the return-path. Check the SPF lookup count after each addition.
4. **Move to `quarantine`, then `reject`.** Do it when reports show your legitimate sources aligned. Under RFC 7489 the `pct` tag can apply the policy to a share of mail while you gain confidence; under RFC 9989 the `t` test-mode tag takes that role, so confirm which your receivers honor.
5. **Set `sp` (and `np` if your receivers support it) deliberately** so unused subdomains cannot be spoofed.
6. **Watch the reports continuously.** New vendors appear without anyone telling security. Reports are how you learn about them before a customer does.

Email authentication reduces spoofing of *your domain*. It does not detect phishing from lookalike domains, compromised legitimate accounts, or stolen sessions; for the latter see [how session hijacking works even after MFA](/posts/how-session-hijacking-works-even-after-mfa/) and [phishing-resistant MFA](/posts/phishing-resistant-mfa-passkeys-vs-fido2-security-keys/).

## Sources and verification

Checked on October 10, 2026. We did not send test messages or inspect any live DNS records.

| Important claim | Source | Verification |
|---|---|---|
| Google requirements for senders of more than 5,000 messages per day to Gmail accounts, effective February 1, 2024: SPF, DKIM, DMARC (policy may be none), alignment, spam rate below 0.30%, TLS, one-click unsubscribe, forward and reverse DNS | [Google, Email sender guidelines](https://support.google.com/a/answer/81126) | Verified |
| Google recommends spam rate below 0.10% and avoiding 0.30% or higher | Same page, monitoring section | Verified |
| Outlook.com requirements for domains sending more than 5,000 emails per day: SPF, DKIM, DMARC at least p=none; effective May 5, 2025; Junk routing; later rejection date to be announced; 550 5.7.515 text | [Microsoft, Strengthening email ecosystem: Outlook's new requirements for high-volume senders](https://techcommunity.microsoft.com/blog/microsoftdefenderforoffice365blog/strengthening-email-ecosystem-outlooks-new-requirements-for-high%E2%80%90volume-senders/4399730) (April 2, 2025, updated April 30, 2025) | Verified |
| Whether Microsoft has begun rejecting non-compliant mail | No later official statement found; third-party sources conflict | Qualified: stated in the article as unconfirmed |
| SPF checks HELO and MAIL FROM; 10 DNS-querying terms; which terms count; two void lookups; permerror; qualifiers | [RFC 7208](https://datatracker.ietf.org/doc/html/rfc7208) (April 2014) | Verified (sections 2, 4.6.4 and the qualifier text read; later sections not read) |
| DKIM `d=` and `s=` tags and key lookup; Standards Track, September 2011 | [RFC 6376](https://www.rfc-editor.org/rfc/rfc6376.html) | Verified |
| DMARC policy values, `sp`, `rua`, alignment modes, `aspf`/`adkim` defaults, `pct`; RFC 7489 is Informational, March 2015 | [RFC 7489](https://datatracker.ietf.org/doc/html/rfc7489) | Verified |
| RFC 9989 is Standards Track, May 2026, obsoletes RFC 7489 and RFC 9091; pct replaced by t; np and psd added; DNS Tree Walk with eight-query limit; reporting in RFC 9990 and RFC 9991 | [RFC 9989](https://www.rfc-editor.org/rfc/rfc9989.html) | Qualified: first part of the document read; appendix of changes not read |
| SPF is usually tied to the connecting IP and DKIM travels with the message | Follows from the RFC 7208 and RFC 6376 definitions; no survey data cited | Qualified: explanation, not a measured rate |
