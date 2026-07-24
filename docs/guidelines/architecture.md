# Architecture — dual-home-cloudwan-test

## §1 Overview

100% Terraform, hosted on AWS, all resources in `us-east-2`. Three VPCs
(`old-deploy`, `current-deploy`, `future-deploy`) connected by two independent AWS
Cloud WAN core networks:

- **Core network A** connects `old-deploy` ↔ `current-deploy`.
- **Core network B** connects `current-deploy` ↔ `future-deploy`.

`current-deploy` has one attachment into each core network; `old-deploy` and
`future-deploy` each attach to only one. There is no shared core network, so a policy
change, route propagation issue, or attachment failure in core network A cannot
affect core network B, and vice versa.

## §2 Network Design

- Each core network gets its own ASN (from the private range 64512–65534) and its own
  Cloud WAN segment name — no sharing across core networks.
- Each core network's policy document defines an attachment policy rule that
  auto-accepts VPC attachments carrying a specific tag (e.g. `cloudwan-segment =
  <segment-name>`), rather than requiring manual acceptance.
- Each VPC has two subnets: one for deployment/workload resources, one dedicated to
  the Cloud WAN core network ENIs (attachment subnet). These are never the same
  subnet.

## §3 Security

- Security groups on the workload subnet allow inbound/outbound TCP port 80 from the
  peer VPC's CIDR only (not `0.0.0.0/0`).
- No IAM roles beyond what Cloud WAN's service-linked role and the connectivity test
  tool require — this project runs no other compute.

## §4 Terraform Conventions

### §4.1 State Backend

Terraform state is remote: one S3 bucket (versioned, SSE-encrypted, public access
blocked) and one DynamoDB lock table for the `test` environment, provisioned once by
`terraform/bootstrap/test/` (local state — it creates the backend, so it can't use
it). `terraform/environments/test/` initializes against that backend via
`terraform init -backend-config=backend.hcl`. Never a local `.tfstate` file for the
environment root module.

### §4.2 CI Validation

Every change to `terraform/` must pass, in order: `terraform validate`, `tflint`,
`checkov -d .`. No `terraform apply` runs without these passing first.

## §5 Input Variables

No `.tfvars`, no `-var-file`. Every environment root module reads
`terraform/environments/<env>/input.yaml` via `yamldecode(file(...))` into
`local.input`. Secrets (AWS credentials) live in the gitignored
`terraform/environments/<env>/secrets.yaml`, documented by the committed
`secrets.yaml.example`.

| Key | Type | Description |
|---|---|---|
| `environment` | string | Environment name (`test`) |
| `aws_region` | string | `us-east-2` |
| `old_deploy_vpc_cidr` | string | CIDR for the `old-deploy` VPC |
| `current_deploy_vpc_cidr` | string | CIDR for the `current-deploy` VPC |
| `future_deploy_vpc_cidr` | string | CIDR for the `future-deploy` VPC |
| `core_network_a_asn` | number | ASN for the old↔current core network |
| `core_network_b_asn` | number | ASN for the current↔future core network |
| `core_network_a_segment` | string | Segment name for core network A |
| `core_network_b_segment` | string | Segment name for core network B |
| `state_bucket_name` | string | S3 bucket name for remote state (bootstrap only) |
| `lock_table_name` | string | DynamoDB lock table name (bootstrap only) |

The VPC/ASN/segment keys above are the contract the future CloudWAN network module
(not built in this pass) and the `terraform-module` skill must follow once that
module is scaffolded.

Tagging: every resource gets `Environment`, `Project`
(`dual-home-cloudwan-test`), `Owner`, and `ManagedBy` (`Terraform`) tags via the AWS
provider's `default_tags` block — never a per-resource `tags = {...}` block.
