+++
title = "CSAF 2.1 metrics: Read EPSS, SSVC and CVSS v4 per Product"
date = 2026-11-23T04:30:00Z
tags = ["csaf", "csaf 2.1", "epss", "ssvc", "cvss v4", "vulnerability management", "json schema"]
categories = ["appsec"]
summary = "In CSAF 2.1, vulnerabilities[].metrics[] holds CVSS v2/v3/v4, EPSS, SSVC v2 and a qualitative severity rating per product, with an optional source URL. This guide maps every field, shows how the values differ from the same signals in a CVE record, and gives a short Python reader plus the timestamp tests a consumer should apply."
description = "CSAF 2.1 metrics[] stores CVSS v4, EPSS and SSVC per product ID with an optional source URL. Field map, CVE-record differences, a Python reader and checks."
author = "John Marshall"
takeaways = [
  "CSAF 2.1 replaces vulnerabilities[].scores with metrics[]. Each metric object requires content and products and may carry source; content can hold cvss_v2, cvss_v3, cvss_v4, epss, ssvc_v2, qualitative_severity_rating and x_extensions, with at least one property.",
  "Metrics are scoped to product IDs, not to the CVE. One file can give a CVSS v4 score for the affected build and nothing for the fixed build; join on product ID, not just CVE.",
  "A metric without source was assigned by the document author. A source URL means a third party (for example an EPSS provider or a coordinator) originally determined it.",
  "EPSS percentile and probability are strings matching a decimal pattern, not numbers, and each EPSS block needs a timestamp. Recommended test 6.2.41 flags a final or interim document whose youngest EPSS timestamp is more than 15 days older than its newest revision.",
  "SSVC in CSAF uses the CERT/CC SelectionList 2.0.0 format with namespace, key, version and value keys (ssvc:E@1.1.0 = P). CISA's ADP container in a CVE record uses a different shape (options with names like 'active'), so you need a mapping before comparing them."
]

[[faq]]
q = "Where are CVSS scores in a CSAF 2.1 file?"
a = "Under vulnerabilities[].metrics[].content.cvss_v2, cvss_v3 or cvss_v4. Each metric object also has a products array listing the product IDs the score applies to, and an optional source URL. CSAF 2.0 used vulnerabilities[].scores[] with only cvss_v2 and cvss_v3."

[[faq]]
q = "Is EPSS in CSAF a number or a string?"
a = "A string. Both percentile and probability must match the pattern ^(([0]\\.([0-9])+)|([1]\\.[0]+))$, and timestamp is a required date-time. A JSON number such as 0.041 fails schema validation, so convert with float() after reading."

[[faq]]
q = "What does a missing source on a CSAF metric mean?"
a = "The CSAF 2.1 prose says: 'If no source is given, then the metric was assigned by the document author.' Treat it as the vendor's or issuer's own assessment; a metric with a source URL came from the party at that URL."

[[faq]]
q = "Can I compare SSVC in a CSAF file with CISA's SSVC in the CVE record?"
a = "Yes, after mapping. CSAF uses SSVC SelectionList 2.0.0 keys (for example Exploitation key E, values N, P or A). CISA's ADP container lists options such as {\"Exploitation\": \"active\"}. Map both to the same decision point and value before you decide which one wins."
+++

**Short answer:** In CSAF 2.1, every score a vendor ships lives in `vulnerabilities[].metrics[]`. Each item has a required `content` object (CVSS v2, v3 or v4, EPSS, SSVC v2, a qualitative severity rating, or extensions), a required `products` list of product IDs, and an optional `source` URL. If `source` is missing, the document author assigned the metric. Read it per product, keep the `source`, and check the EPSS and SSVC timestamps before you let a vendor value override the one you already get from the CVE record.

This guide is for engineers who ingest vendor CSAF files and already pull EPSS, CVSS and CISA's SSVC from other feeds. Our [CSAF 2.1 vs 2.0 field-change guide](/posts/csaf-2-1-vs-2-0-what-changes-for-vex-consumers/) covers the rename from `scores` to `metrics`. This piece goes one level down. It covers what each `metrics` field holds, how it differs from the same signal elsewhere, and how to read it without losing the product scope.

**Status:** Field names and test numbers below come from the OASIS CSAF TC repository (`csaf_2.1/json_schema/csaf.json` and `csaf_2.1/prose/edit/src/`, commit of 18 November 2026). The 2.1 prose is Committee Specification 01, dated 9 November 2026, not yet an OASIS Standard, so details can still change.

## The metric object at a glance

```json
"metrics": [
  {
    "content": {
      "cvss_v4": { "version": "4.0", "vectorString": "CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N",
                   "baseScore": 9.3, "baseSeverity": "CRITICAL" },
      "ssvc_v2": { "schemaVersion": "2.0.0", "target_ids": ["CVE-1900-0001"],
                   "timestamp": "2026-11-20T11:00:00.000Z",
                   "selections": [ { "namespace": "ssvc", "key": "E", "version": "1.1.0", "values": [ { "key": "P" } ] } ] }
    },
    "products": ["CSAFPID-0001"]
  },
  {
    "content": { "epss": { "percentile": "0.912000000", "probability": "0.041000000",
                           "timestamp": "2026-11-01T00:00:00.000Z" } },
    "products": ["CSAFPID-0001"],
    "source": "https://epss.example/scores/2026-11-01"
  }
]
```

This is an illustrative fragment of a complete test document we built (fictional vendor, placeholder CVE, example.com-style URLs). The full file validates with zero errors against the CS01 schema. We used Python `jsonschema` 4.26 offline, with the FIRST CVSS and CERT/CC SSVC schemas loaded from `csaf_2.1/referenced_schema/`. The CVSS v4 base score of 9.3 for that vector was computed with the Python `cvss` library.

## Field map

| Path under `metrics[]` | Type and rule (CS01 schema) | What it means |
|---|---|---|
| `content` | object, required, `minProperties: 1`, no other properties allowed | "Information about (at least one) metric or score for the given products" |
| `content.cvss_v2` | FIRST `cvss-v2.0.json` | CVSS v2.0 object |
| `content.cvss_v3` | `oneOf` FIRST `cvss-v3.0.json` / `cvss-v3.1.json` | CVSS v3.x object |
| `content.cvss_v4` | FIRST `cvss-v4.0.json` | CVSS v4.0 object (new in 2.1) |
| `content.epss` | object; `percentile`, `probability`, `timestamp` all required; no extra properties | EPSS data (new in 2.1) |
| `content.qualitative_severity_rating` | enum `critical`, `high`, `medium`, `low`, `none` | Severity on a word scale without a vector (new in 2.1) |
| `content.ssvc_v2` | CERT/CC `SelectionList_2_0_0.schema.json` | SSVC decision point selections (new in 2.1) |
| `content.x_extensions` | `extensions_t` | Metrics-level extensions |
| `products` | `products_t`, required | Product IDs "for which products the given content applies" |
| `source` | string, `format: uri`, optional | "The URL of the source that originally determined the metric" |

Three details matter for parsers:

- **The product is the scope, not the CVE.** The prose says a metric object "SHOULD reflect the associated product's status". For example, "a fixed product no longer contains a vulnerability and should have a CVSS score of `0`, or simply no score listed". A fixed build with no metric is normal, not missing data. Join metrics to `product_status` on product ID before you roll anything up to the CVE.
- **No `source` means the issuer.** The prose: "If no source is given, then the metric was assigned by the document author." Its examples of a `source` are "the vendor advisory, discoverer blog post, a multiplier's assessment or other sources".
- **Several sources can coexist.** Mandatory test 6.1.56 forbids a Qualitative Severity Rating and a CVSS value "for the tuple of Product ID and source", and notes that "different source might assign different metrics for the same product". So one product can carry the vendor's CVSS and a third party's EPSS in separate metric objects.

## EPSS in CSAF vs the EPSS feed

The EPSS block carries the same two numbers as the [EPSS data feed columns](/posts/epss-data-feed-columns-percentile-vs-probability-and-how-to-join-it-to-a-scanner-export/). The encoding differs in two ways.

- **Strings, not numbers.** Both `percentile` and `probability` must match `^(([0]\.([0-9])+)|([1]\.[0]+))$`. In our test, a file with `"probability": 0.041` failed validation with "0.041 is not of type 'string'". Convert with `float()` after reading, and write strings when you produce files.
- **A timestamp per value.** The schema defines `timestamp` as the time "the EPSS value was recorded". The feed has one `score_date` per daily file instead. A CSAF EPSS value is a snapshot, frozen at that timestamp. It is not a live score.

Two tests in the 2.1 spec use that timestamp. Both apply only when the document status is `final` or `interim`, and both compare against "the `date` of the newest item of the `revision_history`":

| Test | Level | Rule |
|---|---|---|
| 6.1.51 Inconsistent EPSS Timestamp | Mandatory | Each EPSS `timestamp` must be earlier than or equal to that date |
| 6.2.41 Old EPSS Timestamp | Recommended | The youngest EPSS `timestamp` must not be "more than 15 days older" than that date |

The spec defines probability as the likelihood of exploitation activity "in the 30 days following the given timestamp". Past that window, an EPSS value in an advisory is history. **Editorial recommendation:** use the vendor's EPSS value only as a fallback, when you have no current feed value for that CVE. Otherwise prefer your daily feed, and keep the CSAF value with its timestamp for audit.

## SSVC in CSAF vs SSVC in the CVE record

This is where a naive comparison breaks. CSAF 2.1 embeds the CERT/CC SSVC **Selection List 2.0.0** format. That schema requires `timestamp`, `schemaVersion` (constant `"2.0.0"`) and `selections`. Each selection requires `namespace`, `key`, `version` and `values`, and each value needs only a `key`. Optional `target_ids` lists the identifiers being evaluated.

CISA's ADP container in a CVE record (see [how to read CISA Vulnrichment SSVC values](/posts/cisa-vulnrichment-how-to-read-ssvc-values-in-a-cve-record-and-turn-them-into-a-patch-decision/)) uses a different shape. Here it is for CVE-2026-123890, as published in `cvelistV5`:

```json
{"type": "ssvc", "content": {"timestamp": "2026-11-19T00:00:00+00:00",
  "options": [{"Exploitation": "active"}, {"Automatable": "yes"}, {"Technical Impact": "total"}],
  "role": "CISA Coordinator", "version": "2.0.3", "id": "CVE-2026-123890"}}
```

To compare the two, map both to the same decision point. The keys below come from the CERT/CC SSVC source (`src/ssvc/decision_points/ssvc/`):

| Decision point | CSAF `ssvc_v2` selection | Value keys | CISA ADP option |
|---|---|---|---|
| Exploitation | `namespace: ssvc`, `key: E`, `version: 1.1.0` | `N` None, `P` Public PoC, `A` Active | `{"Exploitation": "none" / "poc" / "active"}` |
| Automatable | `namespace: ssvc`, `key: A`, `version: 2.0.0` | `N` No, `Y` Yes | `{"Automatable": "no" / "yes"}` |
| Technical Impact | `namespace: ssvc`, `key: TI`, `version: 1.0.0` | `P` Partial, `T` Total | `{"Technical Impact": "partial" / "total"}` |

Schema validation will not catch a producer that copies CISA's words into CSAF. We swapped `"key": "P"` for `"key": "active"` in our test file and it still validated with zero errors, because a value key only has to be alphanumeric. Mandatory test 6.1.48 catches it: for a registered namespace, each decision point must exist, be valid, and list its `values` "in the same order as in their definition". So run a CSAF validator that implements the 6.1.x tests, not just the JSON schema.

Two more SSVC tests matter on intake:

- **6.1.49 Inconsistent SSVC Timestamp** (mandatory): each `ssvc_v2.timestamp` must not be newer than the newest revision date in a `final` or `interim` document.
- **6.1.47 Inconsistent SSVC Target IDs** (mandatory): each `target_ids` item must be the vulnerability's `cve` or the `text` of one of its `ids`.

## A short reader

This stdlib-only Python 3.10+ script flattens `metrics[]` into one row per vulnerability, product, source and signal. It also flags the timestamp conditions above. We ran it against the test file shown earlier.

```python
import json, sys
from datetime import datetime, timedelta

def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))

def rows(doc):
    for vuln in doc.get("vulnerabilities", []):
        vid = vuln.get("cve") or (vuln.get("ids") or [{}])[0].get("text")
        for m in vuln.get("metrics", []):
            src = m.get("source", "issuer")          # no source = document author
            for pid in m["products"]:
                for kind, val in m["content"].items():
                    if kind == "x_extensions":
                        continue
                    if kind.startswith("cvss_"):
                        out = (val["baseScore"], val["vectorString"], None)
                    elif kind == "epss":             # strings in CSAF
                        out = (float(val["probability"]), float(val["percentile"]), val["timestamp"])
                    elif kind == "ssvc_v2":
                        sel = {f'{s["namespace"]}:{s["key"]}@{s["version"]}':
                               ",".join(v["key"] for v in s["values"]) for s in val["selections"]}
                        out = (sel, val.get("target_ids"), val["timestamp"])
                    else:                            # qualitative_severity_rating
                        out = (val, None, None)
                    yield vid, pid, src, kind, *out

def checks(doc):
    newest = max(ts(r["date"]) for r in doc["document"]["tracking"]["revision_history"])
    gated = doc["document"]["tracking"]["status"] in ("final", "interim")
    warn, latest_epss = [], {}
    for vid, pid, src, kind, a, b, t in rows(doc):
        if kind in ("epss", "ssvc_v2") and gated and ts(t) > newest:
            warn.append(f"{vid} {pid}: {kind} timestamp {t} is newer than revision_history")
        if kind == "epss":
            latest_epss[vid] = max(latest_epss.get(vid, ts(t)), ts(t))
    for vid, t in latest_epss.items():
        if gated and newest - t > timedelta(days=15):
            warn.append(f"{vid}: youngest EPSS timestamp {t:%Y-%m-%d} is >15 days older than revision_history")
    return warn

if __name__ == "__main__":
    doc = json.load(open(sys.argv[1]))
    for r in rows(doc):
        print(" | ".join(str(x) for x in r))
    for w in checks(doc):
        print("WARN", w)
```

Output on the test file:

```text
CVE-1900-0001 | CSAFPID-0001 | issuer | cvss_v4 | 9.3 | CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N | None
CVE-1900-0001 | CSAFPID-0001 | issuer | ssvc_v2 | {'ssvc:E@1.1.0': 'P', 'ssvc:A@2.0.0': 'Y', 'ssvc:TI@1.0.0': 'T'} | ['CVE-1900-0001'] | 2026-11-20T11:00:00.000Z
CVE-1900-0001 | CSAFPID-0001 | https://epss.example/scores/2026-11-01 | epss | 0.041 | 0.912 | 2026-11-01T00:00:00.000Z
WARN CVE-1900-0001: youngest EPSS timestamp 2026-11-01 is >15 days older than revision_history
```

This is a reader, not a validator. It assumes the file already passed schema validation. It does not implement test 6.1.48 or resolve product groups. It also ignores time zones beyond what `fromisoformat` handles. Treat it as a starting point for a pipeline stage.

## Which value wins

The spec defines where each signal sits and who supplied it. It does not say how to rank a vendor's value against a CVE record or a live feed. That ranking is your policy. Here is a defensible default, which is our editorial view rather than spec text:

| Signal | Prefer | Why |
|---|---|---|
| CVSS for an affected product | The vendor's CSAF metric for that product ID | It is scoped to the build you run; a CVE-level score is not. Watch for v4 vs v3.1 mixing, as in [the CVE JSON baseScore trap](/posts/cve-json-cvss-metrics-cvssv4-0-cvssv3-1-basescore-trap/) |
| EPSS | Your current daily feed; CSAF value only as a dated fallback | A CSAF EPSS value is a snapshot with a 30-day horizon |
| SSVC Exploitation | The newer of CISA ADP and CSAF; on a tie, the more severe | Both carry a timestamp; a vendor's `P` from last week should not override CISA's `active` from today |
| Qualitative severity rating | CVSS when both exist | The prose: "CSAF consumer SHOULD give preference to CVSS if both, Qualitative Severity Rating and CVSS, are present" |

Then feed the result into the same decision flow you use for CVE-level signals. Our [vulnerability prioritization workflow from CVE record to patch ticket](/posts/vulnerability-prioritization-workflow-cve-record-to-patch-ticket/) shows where each one plugs in.

## Common mistakes

- **Rolling metrics up to the CVE.** Taking the highest CVSS in the file and pinning it to every product marks fixed builds as critical.
- **Dropping `source`.** Without it you cannot tell the vendor's own score from a copied third-party value, and test 6.1.56 depends on the product-and-source pair.
- **Parsing EPSS as JSON numbers.** A strict decoder will fail, and a lenient one may lose precision. The values are strings.
- **Comparing SSVC by display name.** `active`, `A` and `Active` are the same Exploitation value in three spellings. Map them to one form first.
- **Trusting schema validation for SSVC.** The schema allows any alphanumeric value key. Only the decision-point test checks that the key exists.

## Limits of this article

CSAF 2.1 is a Committee Specification, and we did not survey vendor feeds for 2.1 files, so all examples are built from the TC's schema and test data rather than a production advisory. Test numbers (6.1.47, 6.1.48, 6.1.49, 6.1.51, 6.1.56, 6.2.41) follow the TC's test-data file names and may be renumbered before the OASIS Standard. The precedence table is editorial guidance, not part of the specification.

## Sources and verification

| Important claim | Source | Status |
|---|---|---|
| `metrics[]` item requires `content` and `products`; `source` optional; content properties and EPSS pattern | [OASIS CSAF TC, csaf_2.1/json_schema/csaf.json](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.1/json_schema/csaf.json) | Verified |
| "If no source is given, then the metric was assigned by the document author"; fixed-product scoring guidance; CVSS preferred over qualitative rating | [CSAF 2.1 prose, vulnerabilities section](https://github.com/oasis-tcs/csaf/blob/master/csaf_2.1/prose/edit/src/schema-elements-02-props-04-vulnerabilities.md) | Verified |
| EPSS and SSVC timestamp tests, 15-day old-EPSS test, SSVC target ID and decision point tests, CVSS + qualitative rating test | [CSAF 2.1 prose, test sections](https://github.com/oasis-tcs/csaf/tree/master/csaf_2.1/prose/edit/src) | Verified (CS01; numbering may change) |
| SelectionList 2.0.0 required fields | [csaf_2.1/referenced_schema/certcc/SelectionList_2_0_0.schema.json](https://github.com/oasis-tcs/csaf/tree/master/csaf_2.1/referenced_schema/certcc) | Verified |
| SSVC keys E 1.1.0 (N/P/A), A 2.0.0 (N/Y), TI 1.0.0 (P/T) | [CERTCC/SSVC decision points](https://github.com/CERTCC/SSVC/tree/main/src/ssvc/decision_points/ssvc) | Verified |
| CISA ADP SSVC shape for CVE-2026-123890 | [cvelistV5 record](https://github.com/CVEProject/cvelistV5/blob/main/cves/2026/123xxx/CVE-2026-123890.json) | Verified |
| Test file validates; numeric EPSS fails; `"active"` key passes the schema | Our offline run, jsonschema 4.26, CS01 schema | Verified (our test) |
