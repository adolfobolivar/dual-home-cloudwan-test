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

Each core network has its own **AWS Network Manager global network** — a global
network holds exactly one core network (confirmed against AWS's docs and
`CreateCoreNetwork`'s own validation error after trying to put both on one:
"Global Network ID is already associated with another core network"), so two core
networks were never going to share a global network. Two global networks is simply
what that 1:1 relationship requires, and it reinforces the same independence goal —
one more resource with zero sharing between A and B.

## §2 Network Design

- Each core network gets its own 2-ASN range (from the private range 64512–65534) and
  its own Cloud WAN segment name — no sharing across core networks. AWS rejects a
  degenerate single-value ASN range (`INVALID_ASN_RANGE`), so `input.yaml`'s
  `core_network_a_asn`/`core_network_b_asn` are each the start of a `[asn, asn+1]`
  range the module reserves; keep them far enough apart that the two ranges never
  overlap.
- Each core network's policy document defines an attachment policy rule that
  auto-accepts VPC attachments carrying a specific tag (e.g. `cloudwan-segment =
  <segment-name>`), rather than requiring manual acceptance.
- Each VPC has two subnets: one for deployment/workload resources, one dedicated to
  the Cloud WAN core network ENIs (attachment subnet). These are never the same
  subnet.
- An `AVAILABLE` VPC attachment does not by itself make traffic flow. Each
  workload subnet needs its own route table with an explicit route to every peer
  VPC's CIDR, targeting the core network's ARN (`aws_route`'s `core_network_arn`
  argument — not an ENI or gateway ID; AWS resolves the real next hop through
  Cloud WAN). Without it, a VPC's subnets only ever route within their own VPC.
  `current-deploy`'s workload route table gets two such routes, one per core
  network — never a single route covering both peers, which would blur the exact
  isolation boundary this project tests. The attachment subnet needs no such
  route; nothing is expected to originate from it.

## §3 Security

- Security groups on the workload subnet allow inbound/outbound TCP port 80 from the
  peer VPC's CIDR only (not `0.0.0.0/0`).
- No IAM roles beyond what Cloud WAN's service-linked role and the connectivity test
  tool (§6) require — this project runs no other compute.

## §4 Terraform Conventions

### §4.1 State Backend

Terraform state is remote: one S3 bucket (versioned, SSE-encrypted, public access
blocked) and one DynamoDB lock table for the `test` environment, provisioned once by
`terraform/bootstrap/test/` (local state — it creates the backend, so it can't use
it). `terraform/environments/test/` initializes against that backend via
`terraform init -backend-config=backend.hcl`. Never a local `.tfstate` file for the
environment root module.

**Backend credentials are separate from provider credentials.** Terraform resolves a
`backend "s3" {}` block before evaluating any locals or variables, so it cannot read
`secrets.yaml` the way the `provider "aws"` block does. Every `terraform init`/`plan`/
`apply` in `terraform/bootstrap/test/` or `terraform/environments/test/` needs
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` (matching `secrets.yaml`) exported as
environment variables first — an AWS CLI profile works too. This is required every
time, not a one-time setup step.

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
| `core_network_a_segment` | string | Segment name for core network A (alphanumeric only — Cloud WAN rejects hyphens/underscores) |
| `core_network_b_segment` | string | Segment name for core network B (alphanumeric only — Cloud WAN rejects hyphens/underscores) |
| `state_bucket_name` | string | S3 bucket name for remote state (bootstrap only) |
| `lock_table_name` | string | DynamoDB lock table name (bootstrap only) |

The VPC/ASN/segment keys above are the contract the future CloudWAN network module
(not built in this pass) and the `terraform-module` skill must follow once that
module is scaffolded.

Tagging: every resource gets `Environment`, `Project`
(`dual-home-cloudwan-test`), `Owner`, and `ManagedBy` (`Terraform`) tags via the AWS
provider's `default_tags` block — never a per-resource `tags = {...}` block **for
those four**.

**`Name` is the one required per-resource tag.** It is resource-specific by
definition (e.g. `old-deploy-vpc`, `current-deploy-workload-sg`), so it cannot come
from `default_tags` — every resource that accepts tags sets its own `Name` in a
`tags = { Name = "..." }` block (merged automatically with the four `default_tags`
values, not a replacement for them). A resource missing `Name` is a defect, not a
style nit — it's how resources stay identifiable in the AWS Console/CLI output
across three VPCs' worth of near-identical resources.

## §6 Connectivity Test Tooling

The bidirectional port-80 checks in UC-001 and UC-002 run on **ECS Fargate**, not EC2.
Built and verified end-to-end — `terraform/modules/connectivity_test/` and
`scripts/run-connectivity-check.sh`.

- One minimal container image (`docker/connectivity-test/`, Python stdlib only) is
  deployed identically into each VPC's workload subnet (§2), selected into one of two
  modes at `ecs:RunTask` time via a command override: `listen` (a bounded-duration —
  5 minutes — HTTP server) or `check <ip>` (a single TCP connect attempt, prints
  PASS/FAIL, exit code 0/1). The same image serves as both sides of a check: Fargate
  keeps a process running for the task's lifetime, so — unlike Lambda, which has no
  persistent listener — one task can accept the connection the peer VPC's task
  initiates.
- Tasks are invoked on demand for the duration of a single check, not left running
  continuously — `scripts/run-connectivity-check.sh` starts the listener, runs the
  check, and stops the listener every time, whether the check passes or fails. This
  avoids EC2's AMI/patching burden and boot-time latency while keeping cost and blast
  surface minimal.
- The ECS task execution role is scoped to only pulling the image and writing logs —
  no broader IAM grant, and no task role at all (§3's least-privilege rule applies
  here too; the container makes no AWS API calls of its own).
- **The image lives in a private ECR repository in this region, not ECR Public
  Gallery.** `public.ecr.aws` is a us-east-1-only service with no regional VPC
  endpoint, so it's unreachable from these fully private VPCs (no internet
  gateway/NAT, by design) regardless of any security group or route table
  configuration. Each VPC therefore has its own set of VPC endpoints
  (`terraform/modules/network/endpoints.tf`): interface endpoints for `ecr.api`,
  `ecr.dkr`, and `logs`, plus a free S3 gateway endpoint (ECR stores image layers in
  S3).
- **Each workload security group needs two separate 443 egress rules for this to
  work — one is not enough.** A security-group-referencing rule to the VPC's
  endpoint security group covers the three *interface* endpoints (they have real
  ENIs). It does **not** cover the S3 gateway endpoint, which has no ENI or security
  group at all — it's a route-table/prefix-list mechanism — so a second egress rule
  targeting the region's S3 prefix list (`data.aws_prefix_list`) is required
  separately. Missing either one produces the same symptom either way: the pull
  either fails at auth (`dial tcp <interface-endpoint-ip>:443: i/o timeout`) or fails
  at the layer download (`dial tcp <s3-ip>:443: i/o timeout`) — both look identical
  to a routing problem, but were actually a default-deny security group silently
  dropping traffic that no rule explicitly allowed. Port 80 to the peer VPC (§3)
  does not cover this at all — it's a completely different traffic path.
- AWS VPC Reachability Analyzer was considered as a zero-compute alternative but
  rejected for this role: it verifies configured reachability (route tables/SGs/NACLs),
  not an actual data-plane TCP handshake, which is what UC-001/UC-002 require.

Result of the first full run: `old → current` PASS, `current → future` PASS,
`old → future` FAIL — the isolation boundary this project exists to prove holds.
