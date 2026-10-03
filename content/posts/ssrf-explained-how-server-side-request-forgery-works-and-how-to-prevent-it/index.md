+++
title = "SSRF Explained: How Server-Side Request Forgery Works and How to Prevent It"
date = 2026-10-03T08:05:00Z
tags = ["appsec", "api security", "cloud security"]
categories = ["appsec"]
summary = "Any feature that fetches a URL on a user's behalf lets that user borrow your server's network position. Here is how SSRF works, why URL filters keep failing, and the layered controls that hold."
description = "SSRF prevention for engineers: how server-side request forgery reaches cloud metadata, why deny lists fail, and how to layer validation, egress and IMDSv2."
author = "FirewallSync Editorial"
imageAlt = "A rack of servers with network cables attached"
imageCredit = "Photo by [Yuriy Vertikov](https://unsplash.com/photos/c-lSQecD9oI) on Unsplash"
takeaways = [
  "SSRF happens when your server fetches a destination an attacker chose, so the request arrives with your server's network access and credentials rather than theirs.",
  "The highest-value target in cloud environments is the instance metadata service at 169.254.169.254, which can return temporary credentials for the instance's role.",
  "Checking the URL string is not enough: redirects, DNS answers that change between check and use, and alternate IP notations all get past string filters.",
  "Use an allow list when destinations are known. When they are not, validate the resolved IP address, disable redirects and enforce the same rule at the network layer.",
  "On AWS, requiring IMDSv2 removes the simplest metadata path, but AWS describes it as defense in depth, not a fix for the SSRF bug itself."
]

[[faq]]
q = "What is SSRF in simple terms?"
a = "Server-side request forgery is a flaw where an application fetches a URL or network destination supplied by a user without ensuring the request goes where it should. The attacker uses the server as a relay to reach systems that only the server can reach, such as internal services or a cloud metadata endpoint."

[[faq]]
q = "Is SSRF still in the OWASP Top 10?"
a = "It was its own category, A10, in the OWASP Top 10 2021. In the 2025 edition OWASP rolled SSRF into A01 Broken Access Control, so it is still covered but no longer listed separately."

[[faq]]
q = "Does IMDSv2 prevent SSRF?"
a = "No. IMDSv2 makes the AWS metadata service harder to reach through a typical SSRF bug because it requires a PUT request and a custom header before any metadata is returned. The SSRF flaw itself remains and can still be used against other internal services."

[[faq]]
q = "Why is a deny list of internal IP addresses not enough?"
a = "Because the address your code checks is not always the address it connects to. A public URL can redirect to an internal one, a hostname can resolve differently on a second lookup, and the same address can be written in several notations. OWASP advises against relying on deny lists or regular expressions for these reasons."
+++

Server-side request forgery (SSRF) is what happens when your application fetches a destination an attacker chose. The attacker cannot reach your internal network or your cloud credentials directly, but your server can, and a feature that fetches URLs on request will do the reaching for them.

The fix is not a cleverer URL filter. It is a set of layers: avoid taking raw URLs where you can, validate the address you actually connect to, refuse redirects, restrict what the fetching component can reach at the network level, and harden the most valuable target. The rest of this article explains why each layer exists.

## What SSRF is

MITRE's definition for [CWE-918](https://cwe.mitre.org/data/definitions/918.html) is precise: "The web server receives a URL or similar request from an upstream component and retrieves the contents of this URL, but it does not sufficiently ensure that the request is being sent to the expected destination."

The vulnerable feature is usually one somebody asked for on purpose:

- Webhooks, where a customer registers a URL for you to call
- Link previews and URL unfurling
- "Import from URL" for images, documents or feeds
- HTML-to-PDF and screenshot services that load remote resources
- Server-side integrations that build a backend URL from request parameters

In each case the request originates inside your infrastructure. It passes any firewall that trusts your server, and it may carry whatever ambient identity the server has. CWE-918 lists the consequences as reading application data, executing unauthorized code or commands, and bypassing protection mechanisms such as firewalls.

Two variants matter for testing. In the basic form the response is returned to the attacker, who can read internal pages directly. In blind SSRF nothing is returned, but the attacker can still trigger state-changing requests or infer what exists from timing and error differences.

## Where it sits in the OWASP Top 10

SSRF became its own category, A10, in the [OWASP Top 10 2021](https://top10.owasp.org/2021/A10_2021-Server-Side_Request_Forgery_(SSRF)/), added from the community survey rather than from incidence data. In the 2025 edition it no longer has a separate entry: the [2025 introduction](https://top10.owasp.org/2025/0x00_2025-Introduction/) states that "Server-Side Request Forgery (SSRF) has been rolled into" A01 Broken Access Control.

That reclassification is a useful way to think about the bug. SSRF is an access control failure: the server is authorized to reach something, and the application lets an unauthorized party direct that access. If you already review authorization as a class of bug, SSRF belongs in the same reviews.

## Why cloud metadata makes it serious

Every major cloud gives a virtual machine a local HTTP endpoint that describes the instance and, critically, can hand out temporary credentials for the identity attached to it. On AWS, Google Cloud and Azure the IPv4 address is the same link-local address, `169.254.169.254`.

An SSRF bug that can reach that address may be able to retrieve credentials and use them from outside your network. How easy that is depends on the provider's protections:

| Provider | Endpoint | Protection against a naive SSRF request |
|---|---|---|
| AWS, IMDSv1 | `169.254.169.254` | None: a plain GET request returns metadata |
| AWS, IMDSv2 | `169.254.169.254`, and `fd00:ec2::254` on Nitro instances in IPv6 subnets | Requires a session token obtained with a PUT request, then sent in the `X-aws-ec2-metadata-token` header. Default response hop limit is 1 |
| Google Cloud | `169.254.169.254`, `metadata.google.internal` | Requires the `Metadata-Flavor: Google` header. Requests carrying `X-Forwarded-For` are rejected |
| Azure | `169.254.169.254` | Requires the `Metadata: true` header. Requests carrying `X-Forwarded-For` are rejected |

IMDS stands for Instance Metadata Service. The header requirements matter because many SSRF bugs give the attacker control of the URL only, not the HTTP method or headers. They stop helping when the vulnerable feature lets the attacker set headers too, which some webhook and integration features do by design.

On AWS, both versions are accepted by default according to the [EC2 documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html), so IMDSv1 stays reachable until you require IMDSv2. The commands for that are in the hardening section below.

Metadata is the best-known target, not the only one. The same bug reaches internal admin panels, unauthenticated services bound to localhost, databases with HTTP interfaces, and other tenants' callbacks.

## Why URL filtering keeps failing

The intuitive defense is to inspect the URL and reject internal addresses. OWASP's guidance on that is blunt: "Do not mitigate SSRF via the use of a deny list or regular expression. Attackers have payload lists, tools, and skills to bypass deny lists."

The underlying problem is that the string you inspect and the address you connect to are different things. Four gaps account for most bypasses:

1. **Redirects.** The URL points to a public host that passes your check. That host answers with a redirect to `http://169.254.169.254/`, and your HTTP client follows it.
2. **DNS that changes between check and use.** Your code resolves the hostname, sees a public address and approves it. The HTTP client then resolves the name again and gets an internal address. This is DNS rebinding, a time-of-check to time-of-use race.
3. **Alternate notations.** `127.0.0.1` can be written as the decimal integer `2130706433`, in hexadecimal, or as the IPv4-mapped IPv6 address `::ffff:127.0.0.1`. A string comparison against "127.0.0.1" misses all of them, while many resolvers accept them.
4. **Parser disagreement.** The library that validates the URL and the library that fetches it may split the same string differently, for example around `@`, `#` or backslashes. The [OWASP SSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html) recommends treating parser disagreement as a rejection.

## How to prevent SSRF

OWASP's cheat sheet separates two situations, and the right control depends on which one you are in.

### Case 1: the destinations are known

If the feature only ever needs to call a fixed set of services, do not accept a URL at all. Accept an identifier, map it to a destination on the server, and build the request yourself. Where a hostname must be supplied, compare it against an allow list with exact matching.

This is the strong position: there is nothing to bypass because the user never controls the destination.

### Case 2: the destination can be anywhere

Webhooks and link previews cannot use an allow list, because the whole point is to reach arbitrary external hosts. Here OWASP's cheat sheet accepts that a block list is the available tool, while warning that deny lists are bypass-prone. That is consistent with the Top 10 advice quoted above: a block list is acceptable as one layer when applied to the resolved IP address and backed by network controls. It is not acceptable as a string filter standing alone.

The application-layer checks, in order:

1. Allow only the schemes and ports you need, typically `https` on port 443.
2. Reject URLs containing embedded credentials.
3. Resolve the hostname and reject the request if any returned address is not publicly routable.
4. Connect to the address you validated, not to the hostname again.
5. Disable redirect following, or re-run every check on each redirect target.
6. Do not return the raw upstream response to the caller.

The following Python function implements steps 1 to 3. It is illustrative, assumes Python 3.9 or later, and uses only the standard library.

```python
import ipaddress
import socket
from urllib.parse import urlsplit

ALLOWED_SCHEMES = {"https"}
ALLOWED_PORTS = {443}


def vet_url(url: str) -> list[str]:
    """Return the public IPs a URL resolves to, or raise ValueError."""
    parts = urlsplit(url)
    if parts.scheme not in ALLOWED_SCHEMES:
        raise ValueError("scheme not allowed")
    if parts.username or parts.password:
        raise ValueError("credentials in URL not allowed")
    host = parts.hostname
    port = parts.port or 443
    if not host or port not in ALLOWED_PORTS:
        raise ValueError("host or port not allowed")

    infos = socket.getaddrinfo(host, port, type=socket.SOCK_STREAM)
    addresses = {info[4][0] for info in infos}
    for raw in addresses:
        ip = ipaddress.ip_address(raw)
        if ip.version == 6 and ip.ipv4_mapped:
            ip = ip.ipv4_mapped
        if not ip.is_global:
            raise ValueError(f"{host} resolves to non-public address {ip}")
    return sorted(addresses)
```

Three design choices are worth noting:

- **It tests for "public", not for "private".** Python's [`ipaddress`](https://docs.python.org/3/library/ipaddress.html) documentation notes that `is_private` is `False` for the shared address space `100.64.0.0/10`, and so is `is_global`. Checking `not ip.is_global` rejects that range, loopback, link-local (including `169.254.169.254`) and private ranges in one condition. Checking `is_private` alone would let `100.64.0.0/10` through.
- **It validates what the resolver returns, not the string.** Decimal and hexadecimal notations are normalized by resolution before the check runs, which closes the alternate-notation gap without a list of patterns.
- **It rejects if any returned address is non-public**, not only the first.

What it does not do is equally important. It does not close the DNS rebinding gap on its own: if you call `vet_url()` and then hand the original hostname to an HTTP client, the client resolves again. To close that gap, connect to one of the returned IP addresses while still sending the original hostname for TLS verification and the `Host` header, or route outbound fetches through a proxy that enforces the same address rules at connection time. When you make the request, turn off redirect following, for example `allow_redirects=False` in the Python `requests` library.

### Network-layer controls

Application checks fail open when someone adds a second fetch path and forgets them. Network controls do not. OWASP's 2021 guidance lists segmenting remote resource access into separate networks, enforcing deny-by-default firewall policy for all but essential intranet traffic, and logging both accepted and blocked flows.

In practice that means running URL-fetching code in a component with its own egress rules: no route to internal subnets, no route to the metadata address, and outbound access only to the public internet. A dedicated fetch service or egress proxy also gives you one place to log every outbound destination, which is the evidence you will want when you investigate a suspected SSRF. Our article on [logging for incidents rather than dashboards](/posts/logging-for-incidents-not-for-dashboards/) covers what to keep.

### Harden the metadata service

On AWS, require IMDSv2 so that a plain GET no longer returns anything. For an existing instance:

```bash
aws ec2 modify-instance-metadata-options \
    --instance-id i-1234567890abcdef0 \
    --http-tokens required \
    --http-endpoint enabled
```

To make it the default for new instances launched in a Region, set the account-level default, which AWS documents per Region:

```bash
aws ec2 modify-instance-metadata-defaults \
    --region us-east-1 \
    --http-tokens required
```

Replace the instance ID and Region with your own. AWS documents that account-level defaults "do not affect existing instances", and that settings given at launch take precedence over them, so you need both commands to cover a running fleet.

Two cautions. First, check for software still using IMDSv1 before enforcing, because those calls will start failing with HTTP 401. AWS provides the `MetadataNoToken` CloudWatch metric for this: it counts IMDSv1 calls, and an instance is ready when it records none. Second, the default response hop limit of 1 keeps the token response on the instance itself. AWS notes that "in a container environment, a hop limit of `1` can cause issues" and its examples use 2 there. A higher limit also widens what can reach the service, so raise it only where a workload needs it.

AWS introduced IMDSv2 in a [November 2019 announcement](https://aws.amazon.com/blogs/security/defense-in-depth-open-firewalls-reverse-proxies-ssrf-vulnerabilities-ec2-instance-metadata-service/) titled "Add defense in depth against open firewalls, reverse proxies, and SSRF vulnerabilities". Defense in depth is the accurate description. Requiring IMDSv2 removes the easiest path to credentials. It does not remove the SSRF bug or protect anything else the server can reach.

The credential an attacker obtains is only as powerful as the role attached to the instance, so scoping that role tightly limits the damage of any metadata exposure. The rollout approach in [least-privilege access controls that don't slow teams down](/posts/least-privilege-access-controls-that-dont-slow-teams-down/) applies directly.

## Common mistakes

- **Validating once, fetching twice.** The check and the request each resolve DNS. This is the rebinding gap described above.
- **Leaving redirects on.** Many HTTP clients follow redirects by default, including the Python `requests` library for GET requests.
- **Blocking only `169.254.169.254` and `127.0.0.1`.** This misses IPv6 loopback `::1`, the AWS IPv6 endpoint `fd00:ec2::254`, private ranges and internal hostnames.
- **Trusting internal callers.** A service that fetches URLs passed to it by another internal service inherits that service's SSRF exposure.
- **Returning upstream errors verbatim.** Detailed error messages turn blind SSRF into a port scanner.
- **Relying on a web application firewall alone.** A WAF sees the inbound request string. It does not see what your server resolves and connects to.

## How to find it in your own code

Search for every place the application makes an outbound request, then trace whether any part of the destination comes from user input, stored user data or another service's response. HTTP client calls are the obvious ones. Less obvious are image and document processors, PDF renderers, XML parsers that resolve external entities, and SDK calls that accept an endpoint parameter.

For each one, ask three questions: can the caller influence the host, can the caller influence the scheme or port, and does the caller see the response. A yes to the first is an SSRF candidate regardless of the other two.

In testing, use a destination you control and watch for the inbound connection. That confirms the fetch happens and shows which component makes it, without touching internal systems. Only test systems you are authorized to test.

## Recommendations

1. Inventory outbound fetch features and remove user-controlled destinations where an identifier would do.
2. Where arbitrary destinations are required, validate the resolved address, connect to that address and disable redirects.
3. Put URL-fetching code behind egress rules that block internal ranges and the metadata address.
4. Require IMDSv2 on AWS, and scope instance roles to least privilege on every cloud.
5. Log outbound destinations from fetch components and alert on attempts to reach internal or link-local addresses.

No single item on that list is sufficient. Each one covers a failure mode of the others, which is the point of layering them.

## Sources and verification

Checked on October 3, 2026. Cloud provider behavior is as documented on that date and can change.

| Important claim | Source | Verification |
|---|---|---|
| Definition of SSRF and its consequences | [MITRE CWE-918](https://cwe.mitre.org/data/definitions/918.html) | Verified |
| SSRF was category A10 in the OWASP Top 10 2021, added from the community survey | [OWASP Top 10 2021, A10](https://top10.owasp.org/2021/A10_2021-Server-Side_Request_Forgery_(SSRF)/) | Verified |
| SSRF was rolled into A01 Broken Access Control in the 2025 edition | [OWASP Top 10 2025 introduction](https://top10.owasp.org/2025/0x00_2025-Introduction/) | Verified |
| OWASP advises against deny lists and regular expressions as the mitigation | [OWASP Top 10 2021, A10](https://top10.owasp.org/2021/A10_2021-Server-Side_Request_Forgery_(SSRF)/) | Verified |
| Allow list where destinations are known; address validation, DNS checks and disabled redirects where they are not | [OWASP SSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html) | Verified |
| IMDSv2 requires a PUT-issued session token; default hop limit is 1; both versions accepted by default | [AWS EC2 User Guide, instance metadata service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html) | Verified |
| Account-level IMDSv2 default is set per Region and does not affect existing instances | [AWS EC2 User Guide, instance metadata options](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-options.html) | Verified |
| `MetadataNoToken` tracks IMDSv1 calls before enforcement | [AWS EC2 User Guide, existing instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-IMDS-existing-instances.html) | Verified |
| Google Cloud requires `Metadata-Flavor: Google` and rejects `X-Forwarded-For` | [Google Cloud, querying VM metadata](https://docs.cloud.google.com/compute/docs/metadata/querying-metadata) | Verified |
| Azure requires `Metadata: true` and rejects `X-Forwarded-For` | [Azure Instance Metadata Service](https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service) | Verified |
| `is_private` and `is_global` are both `False` for `100.64.0.0/10` | [Python `ipaddress` documentation](https://docs.python.org/3/library/ipaddress.html) | Verified |

The Python example is illustrative rather than production-ready. It reduces risk as one layer and does not guarantee protection on its own.
