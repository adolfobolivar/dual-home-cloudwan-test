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
  `current-deploy` VPCs.
- Bi-directional TCP port-80 connectivity check between `current-deploy` and
  `future-deploy` VPCs.
- Confirm no route exists between `old-deploy` and `future-deploy` (isolation check).

## Use Case ↔ Test Traceability Matrix

| Use Case | Validation |
|---|---|
| UC-001 — Verify old-deploy ↔ current-deploy connectivity | Bi-directional port-80 check above |
| UC-002 — Verify current-deploy ↔ future-deploy connectivity | Bi-directional port-80 check above |
| UC-003 — Check dual-home Cloud WAN deployment status | Route table / attachment / core network status checks above |

A use case isn't done until its row above has been exercised against a real
`terraform apply` in the `test` environment.
