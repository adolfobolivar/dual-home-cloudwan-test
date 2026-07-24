---
name: terraform-module
description: >
  Scaffolds or extends a Terraform module for this project's AWS Cloud WAN networking
  infrastructure, wired to input.yaml, tagged per the project's tagging strategy, and
  following least-privilege IAM. Use when the user asks to "create a Terraform
  module", "provision the VPC/core network/attachment", "add infrastructure for", or
  mentions Terraform, IaC, or AWS resource provisioning for this project.
---

# Terraform Module

## Instructions

Build or extend a Terraform module for $ARGUMENTS (e.g. "the old-deploy/current-deploy
core network", "the future-deploy VPC", "the attachment policy") following
`docs/guidelines/architecture.md`. This skill provisions infrastructure only — this
project has no application layer to implement.

## DO NOT

- Hardcode CIDR blocks, ASNs, segment names, or region directly in a resource block.
  Every such value comes from that environment's `input.yaml` via `local.input.<key>`
  (architecture.md §5) — never a literal in a `.tf` file.
- Use `.tfvars` files or a `-var-file` flag. This project reads `input.yaml` via
  `yamldecode(file(...))` into `local.input` (architecture.md §5) — don't reintroduce
  the HCL-tfvars pattern.
- Tag resources individually. Tagging is enforced once, at the AWS provider block, via
  `default_tags` (architecture.md §5) — a per-resource `tags = {...}` block is
  redundant and risks drifting from the standard set.
- Let two core networks share an ASN, a segment name, or an attachment policy rule.
  Core network A (old-deploy ↔ current-deploy) and core network B (current-deploy ↔
  future-deploy) must stay independent per architecture.md §1–§2 — a shared value is
  exactly the coupling this project exists to rule out.
- Set `require-attachment-acceptance = false` or otherwise skip the tag-based
  attachment policy rule (architecture.md §2). Attachment acceptance must be automated
  via a tag condition, not left manual and not left wide open.
- Write an IAM policy with a wildcard (`*`) resource or action grant, or attach an IAM
  role/instance profile beyond what a resource actually needs (architecture.md §3).
- Skip the remote state backend. Every environment's state lives in the versioned S3
  bucket + DynamoDB lock table (architecture.md §4.1) — never a local `.tfstate` file.

## Bootstrap Prerequisite (Read Before Any Environment Root Module)

The S3 bucket + DynamoDB lock table the DO NOT list above requires do not create
themselves — `terraform init` for `terraform/environments/test/`'s `backend "s3" {}`
block fails if they don't already exist. Both are handled by a separate,
already-scaffolded bootstrap step:

- `terraform/bootstrap/test/` — a small, local-state-only root module (not wired to
  any remote backend, since it's what creates the backend) that provisions just the
  state bucket and lock table. It reads AWS credentials from
  `../../environments/test/secrets.yaml` rather than keeping a second copy — one
  credentials file per environment, not one per module.
- `terraform/environments/test/backend.hcl` — the partial backend config
  (bucket/key/region/dynamodb_table) the environment root module is initialized with
  via `terraform init -backend-config=backend.hcl`. Its values must match
  `terraform/bootstrap/test/input.yaml` exactly.

Confirm both exist before scaffolding a new module under `terraform/modules/`; if they
don't, that's a separate task, out of scope for $ARGUMENTS unless the user is
explicitly asking for the bootstrap itself.

## Workflow

1. Read `docs/guidelines/architecture.md` in full — §1 for the two-core-network
   topology, §2 for segment/ASN/attachment-policy rules, §3 for security groups, §4
   for state backend and CI gates, §5 for the input-variable matrix.
2. Read `docs/guidelines/requirements.md` for the FR/NFR/C-xxx this module must
   satisfy (isolation NFRs in particular — a module that couples the two core
   networks violates the project's core requirement).
3. Check existing `terraform/modules/` for naming conventions and provider
   configuration — follow them; don't introduce a new pattern for a module that's
   structurally similar to an existing one.
4. Declare the module's inputs as reads from `local.input.<key>`, not hardcoded
   values or bare `var.x` at the environment root.
5. Implement the resources per architecture.md's decision for this layer — e.g. an
   `aws_networkmanager_core_network` with its own
   `aws_networkmanager_core_network_policy_document` (segments, attachment-policies,
   `core-network-configuration.asn-ranges` scoped to that core network only), VPC
   attachments in the dedicated attachment subnet, security groups scoped to the peer
   VPC's CIDR on port 80 only.
6. Apply `default_tags` at the provider block; do not add per-resource tag blocks.
7. Scope every IAM role/policy attached to a new resource to only the actions and
   resource ARNs it actually needs.
8. Run `terraform validate`, `tflint`, and `checkov -d .`, and resolve every finding —
   this is a CI gate (architecture.md §4.2), not optional cleanup.
9. Re-read the module against `input.yaml` and confirm nothing that should be
   configurable is hardcoded, and that nothing couples core network A to core
   network B.

## Resources

- `docs/guidelines/architecture.md` — the primary source for every infrastructure
  decision in this project.
- `docs/guidelines/requirements.md` — constraints (`C-xxx`) and NFRs this module must
  satisfy.
- If configured, use the **Terraform MCP server** (HashiCorp's official one) for
  current AWS provider/module registry documentation.
- If configured, use the **AWS Documentation MCP server** for Cloud WAN / Network
  Manager service documentation (core network policy document structure, attachment
  policy syntax, ASN ranges).
