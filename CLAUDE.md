# CLAUDE.md

This file contains guidelines and common commands for AI assistants (like Claude/Copilot) working on the
**dual-home-cloudwan-test** project.

**dual-home-cloudwan-test validates whether AWS Cloud WAN can host two fully independent core networks**, each
connecting a pair of VPCs that stand in for successive deployment generations (`old-deploy`, `current-deploy`,
`future-deploy`), such that a failure or configuration change in one core network can never affect the other. Full
context lives in `docs/guidelines/vision.md` — read it before proposing new scope. In particular, the following are
**out of scope** unless a use case is added for them first: any real application workload inside a VPC, a `prod`
environment or second AWS account, VPC Peering or Transit Gateway, and any direct connectivity between `old-deploy`
and `future-deploy`.

This project is **infrastructure-only** — there is no backend, frontend, or database. Everything here is Terraform
and AWS Cloud WAN.

---

## 📚 Specifications (source of truth)

This project is built specs-first. Before implementing or changing infrastructure, check:

- `docs/guidelines/vision.md` — scope, actor, objectives, explicit non-goals.
- `docs/guidelines/requirements.md` — functional/non-functional requirements and constraints catalog (FR-xxx,
  NFR-xxx, C-xxx).
- `docs/guidelines/use_cases.puml` — one-page PlantUML overview of the actor (Network Operator) and all 3 use cases;
  a visual index, not a replacement for the detailed specs in `docs/use-cases/`.
- `docs/guidelines/architecture.md` — network topology (§1-§2), security groups (§3), Terraform state backend and CI
  validation gates (§4), and the full `input.yaml` variable matrix (§5). The primary source for every infrastructure
  decision in this project.
- `docs/guidelines/testing.md` — CI validation commands, connectivity/status checks, and the UC↔test traceability
  matrix.
- `.claude/skills/terraform-module/SKILL.md` — the skill for scaffolding or extending this project's Terraform. Use
  it rather than hand-rolling a module — it already encodes the DO-NOTs below.
- `docs/use-cases/UC-001` through `UC-003` — one file per use case (preconditions, main/alternative flows,
  postconditions, business rules). Every infrastructure behavior change should map to a business rule (`BR-xxx`) in
  one of these files; if it doesn't, either the code or the use case is wrong.

---

## 🏗️ Architecture Overview

- **Infrastructure (IaC):** Terraform, 100% — no manual AWS Console changes.
- **AWS stack:** Cloud WAN (two independent core networks), VPCs, security groups, S3 + DynamoDB for remote state.
- **Region:** `us-east-2` only, per `architecture.md` §1.
- **Topology:** Core network A connects `old-deploy` ↔ `current-deploy`; core network B connects `current-deploy` ↔
  `future-deploy`. `current-deploy` is the only VPC attached to both. Each core network has its own ASN, segment, and
  tag-based attachment policy — never shared (`architecture.md` §1-§2).
- **State:** one S3 bucket + DynamoDB lock table per environment, provisioned once by `terraform/bootstrap/<env>/`
  (local state — it creates the backend, so it can't use it). Currently one environment: `test`.

---

## 💻 Build and Run Commands

### Terraform bootstrap (one-time per environment, already applied for `test`)

```bash
cd terraform/bootstrap/test
export AWS_ACCESS_KEY_ID=...       # matching terraform/environments/test/secrets.yaml
export AWS_SECRET_ACCESS_KEY=...
terraform init
terraform plan
terraform apply
```

### Terraform environment (network infrastructure)

```bash
cd terraform/environments/test
export AWS_ACCESS_KEY_ID=...       # matching secrets.yaml — required every invocation, see architecture.md §4.1
export AWS_SECRET_ACCESS_KEY=...
terraform init -backend-config=backend.hcl
terraform plan    # reads ./input.yaml automatically, no -var-file needed
terraform apply
```

**Backend credentials are separate from provider credentials.** Terraform resolves the `backend "s3" {}` block
before evaluating any locals, so it can't read `secrets.yaml` the way the `provider "aws"` block does — the two
`AWS_*` environment variables above are required for every `init`/`plan`/`apply`, not just the first one.

---

## 🧪 Testing and Quality Commands

### Infrastructure Validation (CI gate, run before every apply)

```bash
cd terraform/environments/test
terraform validate
tflint
checkov -d .
```

### Connectivity and Status Checks (per `docs/guidelines/testing.md`)

- Validate status of each VPC route table, VPC attachment, and core network.
- Bi-directional TCP port-80 connectivity check between `old-deploy` and `current-deploy` VPCs (UC-001).
- Bi-directional TCP port-80 connectivity check between `current-deploy` and `future-deploy` VPCs (UC-002).
- Confirm no route exists between `old-deploy` and `future-deploy` (isolation check, UC-003).

---

## 📝 Code Style and Architectural Guidelines

### Infrastructure as Code (Terraform)

- **No Hardcoding:** Never hardcode CIDR blocks, ASNs, segment names, or region directly in a resource block. Values
  come from that environment's `input.yaml` (read via `yamldecode(file(...))` into `local.input`), not HCL `.tfvars`
  files (`architecture.md` §5).
- **State:** Terraform state is remote (S3 + DynamoDB lock table) per environment, never local, for
  `terraform/environments/<env>/`. `terraform/bootstrap/<env>/` is the one deliberate exception (local state — it
  creates the backend).
- **Tagging:** Every resource gets `Environment`, `Project`, `Owner`, and `ManagedBy` tags via the provider's
  `default_tags` — never a per-resource `tags = {...}` block.
- **Core network independence:** Core network A and core network B must never share an ASN, a segment name, or an
  attachment policy rule. This isolation is the entire point of the project (`architecture.md` §1-§2,
  `requirements.md` NFR-001) — a module that couples them is a defect, not a style nit.
- **Attachment acceptance:** automated via a tag-based attachment policy rule (`architecture.md` §2) — never manual,
  never wide open.
- **Security:** Security groups scoped to the peer VPC's CIDR on port 80 only, never `0.0.0.0/0`. No IAM
  role/policy with a wildcard resource or action grant.
- **CI gate:** `terraform validate`, `tflint`, and `checkov -d .` must all pass before `terraform apply` — this is a
  "No Pass, No Deploy" rule, not optional cleanup.
