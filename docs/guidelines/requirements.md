# Requirements — dual-home-cloudwan-test

Requirements catalog derived from [vision.md](vision.md) and
[architecture.md](architecture.md). This project is infrastructure-only (100%
Terraform, AWS Cloud WAN) — there is no application layer, so no UI/API/data-layer
requirement categories apply. The sole actor is the **Network Operator**.

## Functional Requirements

| ID     | Title                          | User Story                                                                                                                                                                       | Priority | Status |
|--------|--------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|--------|
| FR-001 | Old-Current Connectivity       | As a Network Operator, I want bidirectional TCP port-80 connectivity between the `old-deploy` and `current-deploy` VPCs so that I can confirm core network A links those two deployment generations. | High     | Open   |
| FR-002 | Current-Future Connectivity    | As a Network Operator, I want bidirectional TCP port-80 connectivity between the `current-deploy` and `future-deploy` VPCs so that I can confirm core network B links those two deployment generations. | High     | Open   |
| FR-003 | Automated Attachment Acceptance| As a Network Operator, I want VPC attachments to be automatically accepted by a tag-based Cloud WAN attachment policy rule so that I don't have to manually approve each attachment. | High     | Open   |
| FR-004 | Infrastructure Status Check    | As a Network Operator, I want to check the status of every VPC route table, VPC attachment, and core network so that I can confirm the infrastructure is healthy and correctly configured. | Medium   | Open   |

## Non-Functional Requirements

| ID      | Title                        | Requirement                                                                                                                                                                                                  | Category     | Priority | Status |
|---------|-------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|----------|--------|
| NFR-001 | Core Network Blast-Radius Isolation | A failure or policy change in core network A must not affect core network B, and vice versa. Verified by each core network having a unique ASN (from the private range 64512–65534) and a unique Cloud WAN segment name, with no segment shared across the two core networks. | Availability | High     | Open   |
| NFR-002 | Old-Future Path Absence      | No route table entry and no Layer 3 connectivity path may exist between the `old-deploy` VPC and the `future-deploy` VPC. Verified by the absence of routes to the peer CIDR in every route table on both VPCs and by a failed TCP connection attempt between them. | Security     | High     | Open   |
| NFR-003 | Uniform Default-Tags Tagging | 100% of AWS resources created by this project must carry the `Environment`, `Project`, `Owner`, and `ManagedBy` tags applied solely via the Terraform AWS provider's `default_tags` block. Zero resources may declare a per-resource `tags = {...}` block. | Maintainability | Medium | Open |

## Constraints

| ID    | Title                  | Constraint                                                                                                     | Category  | Priority | Status |
|-------|-------------------------|-----------------------------------------------------------------------------------------------------------------|-----------|----------|--------|
| C-001 | Single Region            | All AWS resources must be provisioned in the `us-east-2` region only.                                          | Technical | High     | Open   |
| C-002 | Cloud WAN Only            | Inter-VPC connectivity must use AWS Cloud WAN exclusively. VPC Peering and Transit Gateway are prohibited.      | Technical | High     | Open   |
| C-003 | 100% Infrastructure as Code | All infrastructure must be provisioned via Terraform. No manual AWS Management Console changes are permitted, per architecture.md §4.2's CI validation gate (`terraform validate`, `tflint`, `checkov -d .`). | Technical | High     | Open   |
| C-004 | Single Test Environment  | This phase covers a single `test` environment only. No `prod` environment or second AWS account is in scope.   | Operational | Medium | Open   |
