# terraform-aws-key-pair — SCOPE

Standalone module for a single EC2 key pair. It registers a **caller-supplied
public key** with AWS so the key pair can be named as `key_name` when launching
EC2 instances. The matching private key is generated and held by the caller and
never touches this module, AWS, or Terraform state. A single module call yields
one taggable, public-key-only key pair.

- **Module type:** Standalone (single resource)
- **Resource managed:** `aws_key_pair.this`

## Single resource managed

- `aws_key_pair` — the imported public key (identity via `key_name` /
  `key_name_prefix` + `public_key` material + tags). No sub-resources, no
  associations, no timeouts block. Consumption by EC2 instances / launch
  templates is by **name** (`key_name`), done in those modules.

## Out-of-scope (consumed by reference)

Referenced by name/id, never created here:

- The EC2 instances / launch templates / ASGs that reference the key pair by
  `key_name` (handled by `terraform-aws-ec2-instance`, `terraform-aws-launch-template`,
  `terraform-aws-autoscaling-group`).
- The **private key** — generated and held by the caller (`ssh-keygen`),
  supplied *nowhere* to this module.
- The public-key source (a local file, SSM parameter, or data source) — read by
  the caller and passed in as the `public_key` string.

## Required IAM permissions

Least-privilege actions the executing Terraform identity needs. This module
**imports** a public key, so the create action is `ec2:ImportKeyPair` — not
`ec2:CreateKeyPair` (which would have AWS generate a private key).

| Action | Required for |
|---|---|
| `ec2:ImportKeyPair` | Register the public key (create) |
| `ec2:DeleteKeyPair` | De-register the key pair (destroy / FORCE-NEW replace) |
| `ec2:DescribeKeyPairs` | Read / refresh state (not ARN-scopable) |
| `ec2:CreateTags` | Request-time tagging at import |
| `ec2:DeleteTags` | Tag updates / removal |

- **No service-linked role** is created by `aws_key_pair`;
  `iam:CreateServiceLinkedRole` is **not** required.
- **No `iam:PassRole`** — a key pair is not an IAM principal and passes no role.
- `Describe*` calls do not support resource-level permissions — they cannot be
  ARN-scoped.

## AWS Prerequisites

- **Service-linked roles:** none required.
- **Account opt-ins:** none — works in any active Region with no service
  enablement.
- **A locally generated key pair:** the caller must hold an RSA (2048/4096-bit)
  or ED25519 key and supply only the public half. Accepted formats: OpenSSH,
  base64-DER, RFC 4716.
- **Region constraints:** none. Key pairs are **regional** (no us-east-1 global
  constraint) — a key registered in one Region is invisible in another. The
  module inherits the caller's provider Region; it declares no `region`
  variable. Multi-Region use = one module call per Region via provider aliases.
- **Windows note:** ED25519 is not usable by Windows instances — use RSA for
  Windows hosts.
- **Service quotas:** default **5,000 key pairs per Region per account**
  (adjustable via Service Quotas).

## Emits

| Output | Description | Typically consumed by |
|---|---|---|
| `id` | Key pair **name** (equals `key_name`) | `aws_instance.key_name`, launch templates, ASGs |
| `arn` | `arn:aws:ec2:<region>:<account>:key-pair/<key-name>` | IAM/SCP conditions, AWS Config rules |
| `tags_all` | All tags incl. provider `default_tags` (resource tags win) | governance / audit |
| `key_pair_id` | Stable id (`key-...`) | `DescribeKeyPairs`, Config rules, drift detection |
| `key_name` | Key pair name (identical to `id`) | instance / launch-template wiring |
| `key_type` | Inferred type (`"rsa"` / `"ed25519"`) | compliance reporting |
| `fingerprint` | RFC 4716 §4 MD5 fingerprint | out-of-band key verification |

> Primary outputs: **`id` + `arn` + `tags_all`.** `id` / `key_name` are the real
> cross-resource references in practice (`aws_instance.key_name` expects the
> name, not the `key-...` id). No output exposes any secret.

## Provider gotchas (from authoring)

- **All identity/material fields are FORCE-NEW** — `key_name`,
  `key_name_prefix`, `public_key`. Changing any destroys and recreates the key
  pair (new `key-...` id) and **de-registers it from instances launched with
  it**.
- **`id` IS the key name**, not a `key-...` id. The stable `key-...` id is the
  separate `key_pair_id` output. `aws_instance.key_name` consumes the **name**.
- **Import drift** — the AWS API does **not** return `public_key` in
  `DescribeKeyPairs`, so a `terraform import` of an existing key pair will plan
  a **replace** on the next apply. No supported workaround; prefer creating
  through the module.
- **`key_name` ⇎ `key_name_prefix`** are mutually exclusive (the provider
  rejects both); the module enforces this with a `validation {}`. Both null →
  Terraform generates a unique name.
- **DSA rejected** — a `validation {}` blocks `ssh-dss` keys (only fires on
  OpenSSH-format keys, which start with a type token; DER/RFC4716 forms are
  unaffected). RSA / ED25519 only.
- **No encryption / KMS surface** — a key pair holds only a public key, so there
  is no `kms_key_arn` variable; secure-by-default here is structural
  (public-key-only) plus the DSA baseline.
- **No `timeouts` block** — `aws_key_pair` exposes none; the module ends at
  `tags`.
- **`tags` vs `tags_all`** — `var.tags` flows to `aws_key_pair.this`; `tags_all`
  is the merge over provider `default_tags` (resource tags win). `default_tags`
  is the caller's provider-block concern, never set here.
- **Regional** — `arn` carries `<region>`; registering the same key in multiple
  Regions requires one module call per Region.
