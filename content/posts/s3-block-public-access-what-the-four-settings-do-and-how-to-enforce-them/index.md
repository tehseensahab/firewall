+++
title = "S3 Block Public Access: What the Four Settings Do and How to Enforce Them"
date = 2026-10-08T08:45:00Z
tags = ["cloud-security", "iam"]
categories = ["cloud-security"]
summary = "New S3 buckets have blocked public access by default since April 2023, but older buckets, account settings and new accounts can still be open. Here is what each setting does and how to enforce all four across an account or an AWS organization."
description = "What the four S3 Block Public Access settings do, which one wins when they overlap, and how to enforce them across an AWS account or organization."
author = "FirewallSync Editorial"
imageAlt = "Rows of white archive boxes on wooden shelves"
imageCredit = "Photo by [Luke Caunt](https://unsplash.com/photos/5utYi64hnJ0) on Unsplash"
takeaways = [
  "S3 Block Public Access has four separate settings. Two stop new public ACLs and policies from being written; two make S3 ignore or restrict public ACLs and policies that already exist.",
  "S3 applies the most restrictive combination of the organization, account, bucket and access point settings, so turning everything on at the account level covers every bucket in it.",
  "Since April 2023, buckets created through the API, CLI, SDKs or CloudFormation get Block Public Access and ACLs disabled by default. Buckets created earlier keep whatever they had.",
  "Since November 26, 2025, AWS Organizations can enforce all four settings across every account from one policy.",
  "If you need a public website, put CloudFront in front of a private bucket with origin access control instead of making the bucket public."
]

[[faq]]
q = "Are new S3 buckets private by default?"
a = "Yes, for buckets created since AWS's April 2023 change. AWS said all newly created buckets get S3 Block Public Access enabled and ACLs disabled by default, whether created through the console, API, CLI, SDKs or CloudFormation. Buckets created before the change in your Region keep their existing settings."

[[faq]]
q = "What is the difference between BlockPublicPolicy and RestrictPublicBuckets?"
a = "BlockPublicPolicy rejects attempts to attach a new bucket or access point policy that grants public access. RestrictPublicBuckets limits access to a bucket that already has a public policy, allowing only AWS service principals and authorized users in the bucket owner's account. You need both: one stops new mistakes, the other neutralizes old ones."

[[faq]]
q = "Does enabling Block Public Access change my bucket policies?"
a = "No. AWS states that Block Public Access settings do not alter existing policies or ACLs. That is why removing a setting later makes a bucket with a public policy or ACL publicly accessible again."

[[faq]]
q = "How do I host a static website if public access is blocked?"
a = "Keep the bucket private and serve it through Amazon CloudFront with origin access control, which grants the CloudFront distribution read access through a bucket policy. AWS recommends origin access control over the older origin access identity. If you must serve directly from S3, you have to relax the relevant settings for that one bucket."

[[faq]]
q = "Can I enforce Block Public Access across all my AWS accounts?"
a = "Yes. Since November 26, 2025, an AWS Organizations S3 policy can enable all four settings for the whole organization, an organizational unit or specific accounts, and new member accounts inherit it. It applies the four settings together; you cannot pick individual settings at the organization level."
+++

Turn on all four S3 Block Public Access settings at the account level in every AWS account, or, if you use AWS Organizations, enforce them with an organization policy so no account can switch them off. Then look for buckets created before April 2023, because AWS's private-by-default change only applied to new buckets. The rest of this article explains what each setting does, because the names are similar and the differences matter when something stops working.

## The four settings

AWS describes four independent settings. Two act when someone tries to make something public; two act on what is already public.

| Setting | What it does | Acts on |
|---|---|---|
| `BlockPublicAcls` | Makes calls that set a public ACL fail: `PutBucketAcl`, `PutObjectAcl`, and `PutObject` requests that include a public ACL | New ACLs |
| `IgnorePublicAcls` | Makes S3 ignore all public ACLs on the bucket and its objects. Uploads that include a public ACL still succeed, but the ACL has no effect | Existing and new ACLs |
| `BlockPublicPolicy` | Makes S3 reject a `PutBucketPolicy` call if the policy allows public access, and does the same for the bucket's same-account access point policies | New policies |
| `RestrictPublicBuckets` | Limits a bucket or access point that has a public policy to AWS service principals and authorized users in the owner's account, blocking all other cross-account access | Existing policies |

An ACL (access control list) is the older per-bucket and per-object permission mechanism in S3; a bucket policy is the JSON resource policy attached to a bucket.

The pairs matter. `BlockPublicPolicy` alone stops a new public policy but leaves an existing one working. `RestrictPublicBuckets` alone neutralizes an existing public policy but lets someone attach a new one. AWS recommends turning on all four.

One warning from AWS's documentation is worth repeating: "Block public access settings don't alter existing policies or ACLs. Therefore, removing a block public access setting causes a bucket or object with a public policy or ACL to again be publicly accessible." The settings are a shield over your policies, not a cleanup of them.

## What S3 counts as "public"

S3 uses its own definition, and it is stricter than "allows everyone".

- **ACLs.** An ACL is public if it grants any permission to the `AllUsers` or `AuthenticatedUsers` groups. `AuthenticatedUsers` means any AWS account holder, not users in your account.
- **Bucket policies.** S3 starts by assuming a policy is public, then checks whether it qualifies as non-public. To be non-public, a policy must grant access only to fixed values, with no wildcard and no IAM policy variable, for things such as specific AWS principals, `aws:SourceIp` address ranges, or conditions like `aws:SourceVpc`, `aws:SourceArn` and `aws:SourceAccount`.

AWS's documentation gives an example: a policy granting `"Principal": "*"` with the condition `"StringEquals": {"aws:SourceVpc": "vpc-91237329"}` is non-public, because the VPC ID is fixed. The same policy using `StringLike` with a wildcard VPC value is public.

## Where the settings apply, and which wins

You can set Block Public Access on an access point, a bucket, an AWS account, and, since November 2025, across an organization. AWS's rule for overlapping settings is simple: S3 "applies the most restrictive combination". If the account blocks public policies, no bucket in that account can be made public through a policy, whatever the bucket's own setting says.

This is why the account level is where to start. One command covers every existing and future bucket in the account:

```bash
aws s3control put-public-access-block \
    --account-id 123456789012 \
    --public-access-block-configuration '{"BlockPublicAcls": true, "IgnorePublicAcls": true, "BlockPublicPolicy": true, "RestrictPublicBuckets": true}'
```

The command needs the `s3:PutAccountPublicAccessBlock` permission. AWS's CLI reference notes that it can return an access-denied error when the account is governed by an organization-level policy, because that policy takes over account-level settings.

To check a single bucket's own settings:

```bash
aws s3api get-public-access-block --bucket amzn-s3-demo-bucket
```

AWS's API reference cautions that this returns the bucket-level configuration only; the effective behavior also depends on the account and organization settings.

### Access points behave differently

AWS notes two details for S3 access points. Their Block Public Access settings can only be set when the access point is created and cannot be changed afterward. And an access point whose network origin is a VPC is always treated as non-public, whatever its policy says.

## Enforcing it across an organization

On November 26, 2025, AWS announced organization-level enforcement for S3 Block Public Access. You attach an AWS Organizations S3 policy at the root, at an organizational unit or to specific accounts, and new member accounts inherit it. AWS states there is no additional charge. AWS's policy syntax documentation shows the whole policy:

```json
{
    "s3_attributes": {
        "public_access_block_configuration": {
            "@@assign": "all"
        }
    }
}
```

The value is `"all"` or `"none"`. The organization level is all or nothing: it turns the four settings on or off together. AWS's documentation adds that if you want to manage the settings per account, you should disable the S3 policy type at the organization level.

For a multi-account estate, this is the strongest form of the control, because an administrator inside a member account cannot turn it off. That is our reading of the design rather than an AWS claim. Before attaching it, find any account that legitimately serves public content from S3 and move that content behind CloudFront first.

## The April 2023 default, and what it did not change

In December 2022, AWS announced two changes that took effect from April 2023: newly created buckets would have Block Public Access enabled, and ACLs disabled through the "bucket owner enforced" Object Ownership setting. AWS said the console already used both defaults, and the change extended them to buckets created through the S3 API, CLI, SDKs and CloudFormation. An update dated April 27, 2023 says the settings then applied to all new buckets in all AWS Regions.

The announcement describes newly created buckets only. A bucket created in 2021 with a public policy keeps it until someone acts. The places to look first:

- AWS accounts older than 2023, especially ones nobody owns any more.
- Buckets created by older infrastructure-as-code modules that set the bucket ACL or policy explicitly.
- Accounts where someone turned the account-level setting off to make one website work.

## Auditing an account

AWS Security Hub has four controls that cover this, if you use it:

| Control | What it checks | Severity |
|---|---|---|
| S3.1 | All four settings enabled at the account level | Medium |
| S3.8 | All four settings enabled at the bucket level | High |
| S3.2 | Bucket permits public read access, considering settings, policy and ACL | Critical |
| S3.3 | Bucket permits public write access, considering settings, policy and ACL | Critical |

IAM Access Analyzer for S3 also reports buckets that grant access to anyone on the internet or to other AWS accounts. AWS notes that in rare cases Access Analyzer and the Block Public Access evaluation can disagree on whether a bucket is public.

If you do not use either service, this Python script with boto3 reports the gaps in one account. It only reads configuration. It is illustrative: we tested its logic with botocore's Stubber against simulated responses, not against a live AWS account.

```python
"""Report S3 Block Public Access gaps in one AWS account (read-only)."""
import boto3
from botocore.exceptions import ClientError

SETTINGS = ("BlockPublicAcls", "IgnorePublicAcls", "BlockPublicPolicy", "RestrictPublicBuckets")
MISSING = "NoSuchPublicAccessBlockConfiguration"


def block_config(fetch) -> dict:
    """Return the four settings, treating 'not configured' as all False."""
    try:
        return fetch()["PublicAccessBlockConfiguration"]
    except ClientError as e:
        if e.response["Error"]["Code"] == MISSING:
            return {k: False for k in SETTINGS}
        raise


def audit(session=None) -> list[str]:
    session = session or boto3.Session()
    account_id = session.client("sts").get_caller_identity()["Account"]
    s3control = session.client("s3control")
    s3 = session.client("s3")

    findings = []
    account = block_config(lambda: s3control.get_public_access_block(AccountId=account_id))
    off = [k for k in SETTINGS if not account.get(k)]
    if off:
        findings.append(f"account {account_id}: off at account level: {', '.join(off)}")

    for bucket in s3.list_buckets()["Buckets"]:
        name = bucket["Name"]
        cfg = block_config(lambda: s3.get_public_access_block(Bucket=name))
        # Effective setting is the most restrictive of account and bucket.
        effective_off = [k for k in SETTINGS if not (cfg.get(k) or account.get(k))]
        try:
            is_public = s3.get_bucket_policy_status(Bucket=name)["PolicyStatus"]["IsPublic"]
        except ClientError as e:
            if e.response["Error"]["Code"] != "NoSuchBucketPolicy":
                raise
            is_public = False
        if is_public or effective_off:
            findings.append(f"bucket {name}: policy public={is_public}; "
                            f"effectively off: {', '.join(effective_off) or 'none'}")
    return findings


if __name__ == "__main__":
    for line in audit():
        print(line)
```

`GetBucketPolicyStatus` returns `IsPublic: true` when S3 considers the bucket's policy public. Known limits of the script:

- It does not read organization-level policies, so an account protected only by an organization policy may be reported as "off".
- It does not paginate the bucket list or handle buckets in Regions that need a regional client, which matters for large accounts.
- The missing-configuration error code is taken from the AWS SDK's model for the account-level API; we did not confirm the bucket-level code against a live account.
- It checks policies and settings, not ACLs on individual objects.

## If you need public content

Serving a website straight from a public bucket is the main reason people switch these settings off. AWS's recommended alternative is CloudFront with origin access control (OAC): the bucket stays private and a bucket policy grants read access only to your CloudFront distribution. AWS recommends OAC over the older origin access identity (OAI), citing support for all Regions including those launched after December 2022, for SSE-KMS encryption, and for PUT and DELETE requests. The bucket policy looks like this, with your own bucket name, account ID and distribution ID:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipalReadOnly",
      "Effect": "Allow",
      "Principal": {"Service": "cloudfront.amazonaws.com"},
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::amzn-s3-demo-bucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::111122223333:distribution/EDFDVBD6EXAMPLE"
        }
      }
    }
  ]
}
```

Because the condition uses a fixed `AWS:SourceArn` value, S3 treats this policy as non-public under the definition above, so it works with all four settings on.

Block Public Access does not cover everything. AWS's documentation advises also checking identity-based policies on IAM roles and resource-based policies on related resources such as KMS keys. For why per-bucket checklists rarely keep up across many accounts, see [why cloud misconfiguration checklists don't work](/posts/cloud-misconfiguration-checklists-dont-work-heres-what-does/).

## Sources and verification

Checked on October 8, 2026. We did not run the CLI commands or the audit script against a live AWS account.

| Important claim | Source | Verification |
|---|---|---|
| Behavior of the four settings; settings do not alter existing policies or ACLs; most restrictive combination applies; definition of public for ACLs and policies; access point rules; recommendation to enable all four; check identity and KMS policies too; Access Analyzer can disagree | [AWS, Blocking public access to your Amazon S3 storage](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html) | Verified |
| Account-level CLI command, required permission, access denied under organization policy | [AWS CLI reference, s3control put-public-access-block](https://docs.aws.amazon.com/cli/latest/reference/s3control/put-public-access-block.html) | Verified |
| Bucket-level GET returns bucket configuration only | [AWS API reference, GetPublicAccessBlock](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html) | Verified |
| `IsPublic` meaning | [AWS API reference, GetBucketPolicyStatus](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html) | Verified |
| Organization-level enforcement announced November 26, 2025; inheritance; no additional charge | [AWS What's New, November 26, 2025](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-s3-block-public-access-organization-level-enforcement/) | Verified |
| Organization policy JSON; "all" and "none"; disable the policy type to manage per account | [AWS Organizations, S3 policy syntax](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_s3_syntax.html) | Verified |
| April 2023 defaults for new buckets; creation methods covered; April 27, 2023 update | [AWS News Blog, December 13, 2022](https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/) | Verified |
| Older buckets keep their settings | Same post describes only newly created buckets | Qualified: inferred from the announcement's scope |
| Security Hub controls S3.1, S3.8, S3.2, S3.3 and severities | [AWS Security Hub, Amazon S3 controls](https://docs.aws.amazon.com/securityhub/latest/userguide/s3-controls.html) | Verified |
| OAC recommended over OAI and reasons; example bucket policy | [Amazon CloudFront, Restrict access to an Amazon S3 origin](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html) | Verified |
| Audit script logic | Tested with botocore Stubber, boto3 1.43, Python 3.13 | Qualified: not run against a live account |
| Missing-configuration error code | AWS SDK model for the s3control API | Qualified: bucket-level code not confirmed |
