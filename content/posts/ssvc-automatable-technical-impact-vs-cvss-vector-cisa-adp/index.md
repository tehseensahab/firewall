+++
title = "SSVC Automatable vs CVSS: What Predicts CISA's Call"
date = 2026-11-26T04:50:00Z
tags = ["ssvc", "cvss", "cisa-adp", "vulnrichment", "automatable", "technical impact", "cvelistv5", "vulnerability management"]
categories = ["appsec"]
summary = "We compared CISA-ADP SSVC Automatable and Technical Impact with CVSS v3.1 vectors in all 227,496 CVE records that carry a CISA SSVC block. Automatable is yes in 90.2% of records whose vector is AV:N/AC:L/PR:N/UI:N and 1.2% of the rest; Technical Impact is total in 95.3% of records with C, I and A all High. Here is the method, the code and when to trust each field."
description = "SSVC Automatable vs CVSS: yes in 90.2% of AV:N/AC:L/PR:N/UI:N records, 1.2% otherwise; Technical Impact total tracks C/I/A High. 227,496 CVE records, code."
author = "John Marshall"
takeaways = [
  "We read all 227,496 published CVE records in the cvelistV5 export of 2026-11-26 that carry a CISA-ADP SSVC block: Automatable is yes in 52,160 (22.9%), Technical Impact is total in 79,334.",
  "Where the record also has a CVSS v3.1 vector (190,071 records), Automatable is yes in 90.2% of records whose vector is AV:N/AC:L/PR:N/UI:N and in 1.2% of all others. That one rule agrees with CISA's call 96.7% of the time.",
  "Technical Impact is total in 95.3% of records with C, I and A all High, 70.2% with two High and 3.1% with one or none.",
  "The disagreements are the useful part: CVE-2024-47575 (FortiManager) has an open AV:N/AC:L/PR:N/UI:N vector but Automatable no; Zerologon (CVE-2020-1472) has Automatable yes despite Microsoft's AV:L/PR:L vector.",
  "Practical rule: use CISA's SSVC values when present and keep them separate from CVSS; for the 37,425 SSVC records without a v3.1 vector and for CVEs CISA has not scored, the vector rule is a reasonable stand-in, labelled as derived.",
]

[[faq]]
q = "Is SSVC Automatable the same as CVSS AV:N/PR:N/UI:N?"
a = "No, but they line up closely. In 46,013 CVE records whose CVSS v3.1 vector is AV:N/AC:L/PR:N/UI:N, CISA-ADP marked Automatable yes in 90.2%. In the other 144,058 records with a v3.1 vector it marked yes in 1.2%. SSVC asks whether the kill chain steps 1-4 can be reliably automated, which a vector only approximates."

[[faq]]
q = "Does SSVC Technical Impact total mean CVSS C:H/I:H/A:H?"
a = "Mostly. Technical Impact is total in 95.3% of records whose v3.1 vector has Confidentiality, Integrity and Availability all High, 70.2% with two High and 3.1% with one or none. SSVC's total means total control of the software's behaviour or total disclosure of its information."

[[faq]]
q = "Can I derive SSVC Automatable from CVSS when CISA has not scored a CVE?"
a = "As a labelled estimate, yes. Treating AV:N/AC:L/PR:N/UI:N as Automatable yes matched CISA's value in 96.7% of the 190,071 records we could compare. Keep the derived value in a separate field so it is never confused with CISA's assessment, and replace it when a CISA-ADP SSVC block appears."

[[faq]]
q = "Which CVSS vector did you use when a record had more than one?"
a = "The CNA's cvssV3_1 vector first, because CISA-ADP drops its own CVSS when a CNA supplies one. If the CNA had none, we used the CISA-ADP cvssV3_1 vector. Records with neither were counted separately."
+++

**Short answer:** CISA's SSVC `Automatable` value is close to a function of four CVSS v3.1 base metrics. Across the 190,071 CVE records that carry both a CISA-ADP SSVC block and a v3.1 vector, Automatable is `yes` in **90.2%** of records whose vector reads `AV:N/AC:L/PR:N/UI:N` and in **1.2%** of the rest. `Technical Impact` tracks the C/I/A impact metrics in the same way: `total` in **95.3%** of records with all three High. So the two SSVC fields mostly agree with CVSS, and the roughly 1 in 30 records where Automatable and the vector disagree are worth reading before you build SLAs on either.

This matters because CISA's SSVC tree, and the [BOD 26-04 decision table](/posts/bod-26-04-decision-table-ssvc-json-lookup/), take Automatable and Technical Impact as inputs. If you already sort on CVSS, you want to know how much new information those two fields add. Where they sit in the record is covered in our [Vulnrichment SSVC guide](/posts/cisa-vulnrichment-how-to-read-ssvc-values-in-a-cve-record-and-turn-them-into-a-patch-decision/); the CVSS v4 Supplemental `AU` metric is a different, supplier-set field covered in [CVSS v4 Supplemental metrics](/posts/cvss-v4-supplemental-metrics-in-cve-records-automatable-provider-urgency/).

## What the two SSVC fields mean

From CERT/CC's decision-point definitions in [CERTCC/SSVC](https://github.com/CERTCC/SSVC) (`automatable.py`, Automatable v2.0.0; `technical_impact.py`, Technical Impact v1.0.0):

- **Automatable:** "Can an attacker reliably automate creating exploitation events for this vulnerability?" `Yes` = "Attackers can reliably automate steps 1-4 of the kill chain"; `No` = they cannot, where the steps are "(1) reconnaissance, (2) weaponization, (3) delivery, and (4) exploitation."
- **Technical Impact:** `Total` = "The exploit gives the adversary total control over the behavior of the software, or it gives total disclosure of all information on the system that contains the vulnerability." `Partial` = "limited control over, or information exposure about, the behavior of the software".

Neither definition mentions CVSS. The [Vulnrichment README](https://github.com/cisagov/vulnrichment) says CISA scores SSVC first and then, for CVEs rated total, automatable or exploited, decides "if there is enough information to assert a specific CWE identifier and/or a CVSS score". It also says CISA-ADP "will drop its own assessments" if a CNA later supplies CWE, CVSS or CPE data.

## Method

- **Input:** the cvelistV5 release `cve_2026-11-26_0000Z` (file `2026-11-26_all_CVEs_at_midnight.zip.zip`, 432,459 record files, 413,235 in state `PUBLISHED`).
- **SSVC:** records with an `adp` container whose `providerMetadata.shortName` is `CISA-ADP` and a metric with `other.type` = `ssvc`. That is 227,496 records, every one with all three options (Exploitation, Automatable, Technical Impact).
- **CVSS:** the CNA's `cvssV3_1.vectorString` if present (143,655 records), otherwise CISA-ADP's own `cvssV3_1` (46,416). 37,425 SSVC records had neither and are reported separately. We used v3.1 because it is the most widely populated version; v4.0 is in far fewer records.
- **Rules tested:** "Automatable = yes when `AV:N`, `AC:L`, `PR:N` and `UI:N`" and "Technical Impact = total when C, I and A are all `H`" (and, as a second cut, two or more `H`).

## Results

### Automatable

| CVSS v3.1 vector source | AV:N/AC:L/PR:N/UI:N? | Records | Automatable yes | Share |
|---|---|---:|---:|---:|
| CNA | yes | 31,287 | 28,701 | 91.7% |
| CNA | no | 112,368 | 1,339 | 1.2% |
| CISA-ADP | yes | 14,726 | 12,803 | 86.9% |
| CISA-ADP | no | 31,690 | 407 | 1.3% |
| No v3.1 vector | n/a | 37,425 | 8,910 | 23.8% |

Combined, the open-path rule predicts `yes` for 46,013 records and CISA agrees on 41,504 (90.2%). It predicts `no` for 144,058 and CISA says `yes` for 1,746 of those (1.2%). Overall agreement is 96.7%, and the rule catches 96.0% of all `yes` values in records that have a vector.

Each metric pulls its weight. Among records that are `AV:N/PR:N/UI:N`, Automatable is `yes` for 41,504 of 46,013 with `AC:L` but only 164 of 7,954 with `AC:H`. Any privileges or any user interaction drops the `yes` rate below 2%: `AV:N/PR:L/UI:N` 1.6% (614 of 39,225), `AV:N/PR:N/UI:R` 1.6% (452 of 27,864).

The CNA and CISA-ADP rows behave almost the same. That is a useful sanity check, because CISA writes its own vector after scoring SSVC, so you might expect its vectors to match its SSVC calls more closely than a vendor's would. They do not: 86.9% versus 91.7%.

### Technical Impact

| C/I/A metrics rated High | Records | Technical Impact total | Share |
|---|---:|---:|---:|
| 3 | 57,464 | 54,749 | 95.3% |
| 2 | 11,959 | 8,398 | 70.2% |
| 1 | 46,892 | 1,453 | 3.1% |
| 0 | 73,756 | 2,271 | 3.1% |

"Total when two or more are High" agrees with CISA 94.7% of the time. Scope (`S:C`) barely moves the result (96.9% total with three High and `S:C`, 95.0% with `S:U`).

### Where they disagree

The CVSS vector describes the vulnerable component; SSVC is CISA's judgement about real attacks. A few KEV-listed examples from the same export:

- **CVE-2024-47575 (FortiManager):** Fortinet's vector is `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`, yet CISA-ADP has Automatable `no` (Exploitation `active`, Technical Impact `total`).
- **CVE-2020-1472 (Zerologon):** Microsoft's v3.1 vector is `AV:L/AC:L/PR:L/UI:N`, but CISA-ADP has Automatable `yes`.
- **CVE-2024-0769 (D-Link DIR-859):** open vector with `C:L/I:N/A:N`, but Technical Impact `total` and Automatable `no`.

We do not know CISA's reasoning for individual calls; the records do not include it. The examples show that neither field can be treated as a mechanical copy of the other.

## Reproduce it

Python 3.9+, standard library only. Download the release asset from the [cvelistV5 releases page](https://github.com/CVEProject/cvelistV5/releases) and run `python3 -I ssvc_vs_cvss.py 2026-11-26_all_CVEs_at_midnight.zip.zip`. We ran it on 2026-11-26; it took about 26 seconds and printed the numbers in the tables above.

```python
# Compare CISA-ADP SSVC Automatable / Technical Impact with CVSS v3.1 vectors
# across a cvelistV5 "all CVEs at midnight" release zip. Python 3.9+, stdlib only.
import collections, io, json, sys, zipfile

outer = zipfile.ZipFile(sys.argv[1])
inner = zipfile.ZipFile(io.BytesIO(outer.read(
    next(n for n in outer.namelist() if n.endswith(".zip")))))

def parse(vs):
    return dict(p.split(":", 1) for p in vs.split("/")[1:])

auto = collections.defaultdict(collections.Counter)   # (source, AV/AC/PR/UI==N/L/N/N) -> values
ti = collections.defaultdict(collections.Counter)     # count of C/I/A == H -> values
ssvc_total = collections.Counter()
for name in inner.namelist():
    if "/CVE-" not in name or not name.endswith(".json"):
        continue
    rec = json.loads(inner.read(name))
    if rec["cveMetadata"]["state"] != "PUBLISHED":
        continue
    c = rec["containers"]
    ssvc, adp_vec = None, None
    for adp in c.get("adp", []):
        if adp.get("providerMetadata", {}).get("shortName") != "CISA-ADP":
            continue
        for m in adp.get("metrics", []):
            if m.get("other", {}).get("type") == "ssvc":
                ssvc = {k: v for o in m["other"]["content"]["options"] for k, v in o.items()}
            if "cvssV3_1" in m:
                adp_vec = m["cvssV3_1"]["vectorString"]
    if not ssvc:
        continue
    ssvc_total[ssvc["Automatable"]] += 1
    cna_vec = next((m["cvssV3_1"]["vectorString"] for m in c["cna"].get("metrics", [])
                    if "cvssV3_1" in m), None)
    src, vs = ("cna", cna_vec) if cna_vec else ("cisa-adp", adp_vec) if adp_vec else ("none", None)
    if not vs:
        auto[("none", None)][ssvc["Automatable"]] += 1
        continue
    v = parse(vs)
    open_path = (v["AV"], v["AC"], v["PR"], v["UI"]) == ("N", "L", "N", "N")
    auto[(src, open_path)][ssvc["Automatable"]] += 1
    ti[sum(v[k] == "H" for k in "CIA")][ssvc["Technical Impact"]] += 1

print("records with CISA-ADP SSVC:", sum(ssvc_total.values()), dict(ssvc_total))
print("\nAutomatable by v3.1 source and AV:N/AC:L/PR:N/UI:N")
for k in sorted(auto, key=str):
    n = sum(auto[k].values())
    print(k, n, "yes", auto[k]["yes"], f"{100*auto[k]['yes']/n:.1f}%")
print("\nTechnical Impact by number of C/I/A = High")
for k in sorted(ti):
    n = sum(ti[k].values())
    print(k, n, "total", ti[k]["total"], f"{100*ti[k]['total']/n:.1f}%")
```

## What to do with this

1. **Prefer CISA's values when they exist.** They agree with CVSS most of the time, and the disagreements (FortiManager, Zerologon) are exactly the cases where an analyst looked at real-world exploitation.
2. **Do not double-count.** If your score already weights `AV:N/PR:N/UI:N` and C/I/A High, adding SSVC Automatable and Technical Impact on top mostly counts the same facts twice. Use SSVC as the decision input and CVSS as context, or the reverse, not both as additive points.
3. **Fill gaps with a labelled estimate.** For CVEs without a CISA-ADP SSVC block, `AV:N/AC:L/PR:N/UI:N` → Automatable yes matched CISA's call in 96.7% of comparable records, and "two or more of C/I/A High" → Technical Impact total in 94.7%. Store the result in a field such as `automatable_derived`, never in the field you use for CISA's value.
4. **Read the open-vector `no` records.** 4,509 records have an open vector but Automatable `no`. If your SLA keys on Automatable, these are the ones that drop to a slower timeline; spot-check those on internet-facing products.
5. **Put it in the pipeline.** These checks belong in the scoring step of the [CVE-record-to-ticket prioritization workflow](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/); for why exploitation evidence still outranks both, see [CVSS vs EPSS vs KEV](/posts/cvss-vs-epss-vs-kev-which-signal-should-decide-what-you-patch-first/).

## Limits of this article

- **Snapshot:** one cvelistV5 export (2026-11-26). SSVC values and CVSS vectors change as records are updated.
- **Correlation only:** we measure agreement, not CISA's method. Nothing here shows that CISA derives SSVC from CVSS.
- **Vector choice:** we used the CNA's v3.1 vector first and CISA-ADP's second; a record with several CNA v3.1 metrics uses the first one listed. v4.0 vectors were not analysed here.
- **Base metrics only:** temporal or environmental parts of vectors were ignored.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| 227,496 records with CISA-ADP SSVC; 52,160 Automatable yes; 79,334 Technical Impact total | [cvelistV5](https://github.com/CVEProject/cvelistV5/releases) release `cve_2026-11-26_0000Z`, counted with the script above | Verified |
| Automatable and Technical Impact shares by vector (tables) | Same export and script; derived rates recomputed in Python | Verified |
| AC:H and PR/UI breakdowns | Same export, separate pass with the same parsing | Verified |
| Vector and SSVC values for CVE-2024-47575, CVE-2020-1472, CVE-2024-0769 | Records in the same export (CNA cvssV3_1 and CISA-ADP SSVC) | Verified |
| Automatable and Technical Impact definitions | [CERTCC/SSVC](https://github.com/CERTCC/SSVC) `src/ssvc/decision_points/ssvc/automatable.py`, `technical_impact.py` | Verified |
| CISA scores SSVC first, adds CVSS/CWE for higher-risk CVEs, drops its own when a CNA supplies them | [cisagov/vulnrichment README](https://github.com/cisagov/vulnrichment) | Verified |
| Using the vector rule as a stand-in | Editorial recommendation based on the agreement rates | Qualified |
