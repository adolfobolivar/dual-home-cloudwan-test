# Testing Strategy — dual-home-cloudwan-test

## Infrastructure Validation (CI gate, run before every apply)

```bash
cd terraform/environments/test
terraform validate
tflint
checkov -d .
```

## Connectivity and Status Checks

- Validate status of each VPC route table.
- Validate status of each VPC attachment.
- Validate status of each core network.
- Bi-directional TCP port-80 connectivity check between `old-deploy` and
  `current-deploy` VPCs — run via `scripts/run-connectivity-check.sh old current`
  (architecture.md §6).
- Bi-directional TCP port-80 connectivity check between `current-deploy` and
  `future-deploy` VPCs — run via `scripts/run-connectivity-check.sh current future`.
- Confirm no route exists between `old-deploy` and `future-deploy` (isolation
  check) — run via `scripts/run-connectivity-check.sh old future`, which must FAIL.

## Use Case ↔ Test Traceability Matrix

| Use Case | Validation | Status |
|---|---|---|
| UC-001 — Verify old-deploy ↔ current-deploy connectivity | `scripts/run-connectivity-check.sh old current` | ✅ PASS |
| UC-002 — Verify current-deploy ↔ future-deploy connectivity | `scripts/run-connectivity-check.sh current future` | ✅ PASS |
| UC-003 — Check dual-home Cloud WAN deployment status | Route table / attachment / core network status checks above | Manually verified via AWS CLI |

A use case isn't done until its row above has been exercised against a real
`terraform apply` in the `test` environment. The isolation check
(`scripts/run-connectivity-check.sh old future`) must always FAIL — a PASS there
would mean the isolation boundary broke.
