+++
title = "Vanderbilt BYOD Ransomware Attack: What We Know So Far"
date = 2026-11-10T04:51:00Z
tags = ["hacking news", "ransomware", "byod ransomware", "higher education", "incident response", "vanderbilt"]
categories = ["security-operations"]
summary = "Vanderbilt University told students and staff on November 9 to shut down their devices and get off campus Wi-Fi while it contained a cybersecurity incident. A new ransomware group called BYOD claims it stole over a million SSNs, and it has hit Michigan State and UNM Health in the last month. What is confirmed, what is only claimed, and what engineers can take from the three incidents."
description = "Vanderbilt ordered devices shut down on Nov 9 after a cyberattack claimed by the BYOD ransomware gang, its third US university in a month. Confirmed vs claimed."
author = "John Marshall"
imageAlt = "A long, empty lecture hall with rows of wooden and black seats behind white desks, tall windows on the right and ceiling lights overhead"
imageCredit = "Photo by [Zsófia Hajnal](https://unsplash.com/photos/empty-lecture-hall-with-rows-of-seats-I8PUo5Xk8DU) on Unsplash"
takeaways = [
  "On November 9, 2026 Vanderbilt University told students and employees to shut down university devices and disconnect from campus Wi-Fi while it contained a cybersecurity incident. By that evening Wi-Fi was back but most systems and applications were still restricted.",
  "A ransomware group calling itself BYOD claims responsibility and says it took 'Over 1 Million SSNs' plus student and employee records. Vanderbilt has not confirmed any data theft, and the claim is unverified.",
  "BYOD, which The Record says emerged in September, has also claimed Michigan State University (1.3 million people, per the group) and UNM Health, where ambulances were diverted. In both cases the institutions' own statements describe far less than the group claims.",
  "Lessons for engineers: have a tested 'shut it all down' message and an out-of-band help channel ready, watch synced storage such as OneDrive and Box for mass renames, and don't size your response to an attacker's leak-site claims."
]

[[faq]]
q = "What happened at Vanderbilt University on November 9, 2026?"
a = "Vanderbilt told students and employees to shut down university devices and disconnect from campus Wi-Fi while its IT team worked to contain a cybersecurity incident, according to FOX 17 and Gizmodo. Its 7 p.m. update said Wi-Fi was available again but 'access to most Vanderbilt systems and applications remains restricted', and that classes would run on a normal schedule on November 10."

[[faq]]
q = "Who is behind the Vanderbilt cyberattack?"
a = "A ransomware group calling itself BYOD claimed responsibility online. Vanderbilt's public updates have not named an attacker, and the claim has not been independently verified."

[[faq]]
q = "Was student data stolen in the Vanderbilt attack?"
a = "Not confirmed. BYOD claims it obtained 'Over 1 Million SSNs, Full Names, Email addresses, Phone Numbers, Student & Employee Records', as quoted by Gizmodo. FOX 17 reports that Vanderbilt has not confirmed whether sensitive information was stolen."

[[faq]]
q = "Is Vanderbilt Health affected?"
a = "According to FOX 17, Vanderbilt Health, which operates separately from the university, said its IT systems were unaffected and patient care continued. It told employees to stay off university IT systems until further notice."
+++

*Reported as of November 10, 2026, 05:00 UTC. Vanderbilt said it would give its next update by 9 a.m. Central on November 10. We will add dated updates here if confirmed facts change.*

On Monday, November 9, Vanderbilt University told students and employees to **shut down university devices and disconnect from campus Wi-Fi** while its IT team worked to contain a cybersecurity incident, [FOX 17 reported](https://fox17.com/news/local/vanderbilt-cybersecurity-incident-disrupts-classes-as-alleged-hackers-claim-stolen-data). A new ransomware group called **BYOD** has claimed the attack and says it stole data on more than a million people. Vanderbilt has not confirmed any data theft.

Vanderbilt is the third US university system BYOD has claimed in about a month, after Michigan State University and the University of New Mexico's health system. Below: what each institution has confirmed, what is only the group's claim, and what engineering and IT teams can take from it.

## Timeline

| Date | Event | Source |
|---|---|---|
| Early Oct 2026 | Michigan State University (MSU) "became aware of suspicious cyber activity"; anyone with an MSU NetID was told to reset their password to at least 15 characters | [The Record](https://therecord.media/michigan-state-university-byod-gang-cyber-incident) |
| Mon, Oct 26 | UNM Health limited new admissions, diverted ambulances and suspended outpatient surgeries and appointments | [BleepingComputer](https://bleepingcomputer.com/news/security/unm-health-ransomware-attack-disrupts-patient-care-surgeries) |
| Tue, Oct 27 | UNM said its hospitals remained open; classes at its four health sciences schools were canceled | BleepingComputer |
| Sun, Nov 1 (approx.) | BYOD added MSU to its leak site, claiming data on 1.3 million current and former students | The Record (Nov 2) |
| Mon, Nov 9, morning | Vanderbilt told staff and students to shut down devices and leave campus Wi-Fi | FOX 17, [Gizmodo](https://gizmodo.com/attackers-claim-to-have-stolen-data-on-over-1-million-vanderbilt-students-and-staff-2000837388) |
| Mon, Nov 9, 7 p.m. | Vanderbilt update: Wi-Fi restored, most systems still restricted, normal schedule on Nov 10 | FOX 17 (quoting the update) |

## What Vanderbilt has said

Vanderbilt's 7 p.m. update on November 9, as quoted by FOX 17:

- "Campus Wi-Fi is now available, but access to most Vanderbilt systems and applications remains restricted."
- "Vanderbilt Information Technology is working with government agencies and other partners to manage this situation."
- "Classes will proceed on a normal schedule."

Earlier on Monday, officials told users to "SHUT DOWN YOUR DEVICE IMMEDIATELY to help prevent potential further security risks" and not to "investigate, troubleshoot, or resolve the issue yourself", according to Gizmodo. FOX 17 reports that the university also told people to watch for unexpected pop-ups, unfamiliar apps, password or sign-in requests, and missing or renamed files, including in OneDrive and Box, and to contact IT by phone or from a separate device.

FOX 17 reports that students were told to stay off Brightspace, the coursework platform, and that some instructors moved to printed materials. Vanderbilt Health, which operates separately, told FOX 17 its IT systems were unaffected and patient care continued.

## Confirmed vs claimed

| Item | Status |
|---|---|
| Vanderbilt is responding to a cybersecurity incident and restricted most systems | **Confirmed** by Vanderbilt's own updates (as quoted by FOX 17 and Gizmodo) |
| Vanderbilt is working with government agencies | **Confirmed** by Vanderbilt's update |
| BYOD is responsible | **Claimed** by BYOD; Vanderbilt has not named an attacker |
| "Over 1 Million SSNs, Full Names, Email addresses, Phone Numbers, Student & Employee Records" stolen | **Claimed** in BYOD's ransom message (quoted by Gizmodo); not confirmed by Vanderbilt |
| Databases locked and part of the network taken over | **Claimed** by BYOD (per FOX 17); not confirmed |
| Ransom amount | **Not reported**. The group's message says it will act "when communication has been established between our team and yours" |

## What is not confirmed

- **How BYOD got in.** None of the reports we checked say how the attackers gained access at Vanderbilt, MSU or UNM. Gizmodo notes the group's name refers to "Bring Your Own Device" policies but does not connect it to how this breach happened, and we have seen nothing that does.
- **Reports of on-screen warnings.** FOX 17 cites reports of audio warnings and unfamiliar pop-ups on university computers but says it did not verify them.
- **Other victims.** Gizmodo's update cites DataBreach.com for a further BYOD claim against a Texas state agency. We have not confirmed it and leave it out of the timeline.

## The pattern: big claims, narrower confirmations

The two earlier incidents show the gap between what BYOD posts and what victims confirm:

- **Michigan State:** BYOD claims data on 1.3 million people. MSU told The Record that the activity "appeared to be a potential credential compromise event", that "current evidence does not indicate a successful compromise of the university's central Active Directory environment," and that there was "no evidence that other MSU data was accessed, changed, or stolen."
- **UNM Health:** BYOD claimed it compromised 36,000 systems, including Active Directory, Group Policy and the Microsoft Entra tenant. UNM's assessment, as reported by BleepingComputer, found the event "did not penetrate core systems or servers" and affected some end-user devices. UNM still diverted ambulances while it worked that out.

BYOD also told UNM it would provide free decryption keys for healthcare facilities and offered up to $2,500 per affected patient, according to BleepingComputer. The Record describes the group as new, emerging in September, with little known about it.

We can't say which side is closer to the truth at Vanderbilt yet. The point for defenders is that both numbers matter: the confirmed scope drives recovery, and the claimed scope drives notification pressure and press coverage.

## What engineers and IT teams can take from this

1. **Pre-write the "shut it all down" order.** Vanderbilt's instruction to power off devices and leave Wi-Fi is a blunt but fast containment step. Decide in advance who can issue it, which systems are exempt (clinical, safety, research instruments), and how you will reach people once email and SSO are off. Run it in a [tabletop exercise](/posts/the-tabletop-exercise-gap-testing-incident-response-for-real/) before you need it.
2. **Keep an out-of-band help channel.** Vanderbilt told users to contact IT by phone or from a separate device. If your helpdesk portal sits behind the same identity provider as everything else, it goes down with it.
3. **Watch synced storage.** Vanderbilt's warning about missing or renamed files in OneDrive and Box is a reminder that sync clients can spread encrypted or renamed files into the cloud. Know your version-history and restore limits, and alert on mass rename or delete activity.
4. **Make a password reset cheap to run.** MSU's response to a suspected credential compromise was a campus-wide NetID reset. Practise it, and make sure your [logs answer incident questions](/posts/logging-for-incidents-not-for-dashboards/), such as which accounts authenticated from where, before you need them.
5. **Patch what ransomware crews are known to use.** How BYOD got in is unknown, but CISA flags KEV entries tied to ransomware campaigns, and that flag changes over time. See our analysis of [KEV knownRansomwareCampaignUse flips](/posts/kev-knownransomwarecampaignuse-unknown-to-known-flips/).

## Sources

- FOX 17 (WZTV), "Vanderbilt cybersecurity incident disrupts classes as alleged hackers claim stolen data," November 9, 2026: [fox17.com](https://fox17.com/news/local/vanderbilt-cybersecurity-incident-disrupts-classes-as-alleged-hackers-claim-stolen-data)
- Gizmodo, "Attackers Claim to Have Stolen Data on Over 1 Million Vanderbilt Students and Staff," November 9, 2026: [gizmodo.com](https://gizmodo.com/attackers-claim-to-have-stolen-data-on-over-1-million-vanderbilt-students-and-staff-2000837388)
- The Record, Michigan State University and the BYOD gang, November 2, 2026: [therecord.media](https://therecord.media/michigan-state-university-byod-gang-cyber-incident)
- BleepingComputer, "UNM Health ransomware attack disrupts patient care, surgeries," October 27, 2026: [bleepingcomputer.com](https://bleepingcomputer.com/news/security/unm-health-ransomware-attack-disrupts-patient-care-surgeries)

We could not retrieve Vanderbilt's own update page directly during this run. Vanderbilt's statements above are as quoted by FOX 17 and Gizmodo.
