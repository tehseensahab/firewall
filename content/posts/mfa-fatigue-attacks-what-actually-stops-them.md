+++
title = "MFA Fatigue Attacks: What Actually Stops Them"
date = 2026-09-25T09:00:00Z
tags = ["authentication", "iam"]
summary = "Push-notification bombing keeps working because most MFA rollouts treat every factor as equally trustworthy. Here's what actually closes the gap."
description = "MFA fatigue attacks exploit push notifications, not passwords. Here's why number matching and phishing-resistant MFA actually stop them."
author = "FirewallSync Editorial"
+++

MFA fatigue attacks — also called push bombing — don't exploit a technical flaw. They exploit the fact that most MFA rollouts treat "any second factor" as good enough, when the factor's design determines whether an exhausted employee at 11pm taps "approve" just to make the notifications stop.

## Number matching isn't optional anymore

Plain push approval ("tap yes or no") is the weakest form of MFA still in wide use, precisely because it asks the user to make zero cognitive effort. Number matching — where the user has to type a code shown on the login screen into the push prompt — adds just enough friction to break the autopilot response that makes bombing effective. If your identity provider supports it, this is a config change, not a project, and it should be the default for every account, not an opt-in.

## Phishing-resistant factors change the incentive, not just the defense

Number matching reduces bombing success rates, but it doesn't touch attacks that pair the push spam with a live phishing page relaying real-time codes. FIDO2 security keys and passkeys remove this entire class of attack because the cryptographic challenge is bound to the origin domain — there's no code to relay. Rolling these out for admin and finance roles first (the accounts actually worth targeting) gets you most of the risk reduction without a company-wide hardware rollout.

## Rate-limit and alert on push volume, not just failed logins

Most detection stacks are tuned to flag failed authentication attempts, but a bombing attack looks like a string of *successful* prompt deliveries with no failures at all — the attacker already has valid credentials, they're just waiting for a mis-tap. Add a specific alert for unusual push notification volume per user per hour, independent of your failed-login alerting, and rate-limit repeated prompts to the same device to cut off the exhaustion tactic entirely.
