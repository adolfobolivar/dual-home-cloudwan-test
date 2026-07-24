# Use Case: Check Dual-Home Cloud WAN Deployment Status

## Overview

**Use Case ID:** UC-003
**Use Case Name:** Check Dual-Home Cloud WAN Deployment Status
**Primary Actor:** Network Operator
**Goal:** Confirm the operational status of the current-deploy VPC's route tables, Cloud WAN attachments, and both core networks (A and B), in order to diagnose or confirm the health of the dual-home deployment
**Status:** Draft

## Preconditions

- The current-deploy VPC is deployed with two Cloud WAN attachments: one into core network A and one into core network B.
- Both attachments have been accepted (automatically, per the tag-based attachment policy).
- The Network Operator has AWS console or CLI/Terraform access to the test environment.

## Main Success Scenario

1. Network Operator selects the current-deploy VPC as the subject of the status check.
2. Operator checks the status of the current-deploy VPC's route table associated with the core network A attachment.
3. System confirms the route table status is active and correctly configured for core network A.
4. Operator checks the status of the current-deploy VPC's Cloud WAN attachment to core network A.
5. System confirms the attachment status is available.
6. Operator checks the status of core network A.
7. System confirms core network A's status is available.
8. Operator checks the status of the current-deploy VPC's route table associated with the core network B attachment.
9. System confirms the route table status is active and correctly configured for core network B.
10. Operator checks the status of the current-deploy VPC's Cloud WAN attachment to core network B.
11. System confirms the attachment status is available.
12. Operator checks the status of core network B.
13. System confirms core network B's status is available.
14. Operator records that the current-deploy VPC's route tables, attachments, and both core networks are confirmed healthy.

## Alternative Flows

### A1: Core Network A Route Table Not Active

**Trigger:** The route table status for core network A is not active or is misconfigured (step 3)
**Flow:**

1. System reports the route table status as unavailable, inactive, or misconfigured.
2. Operator records that the current-deploy VPC's core-network-A route table is the affected resource.
3. Use case ends.

### A2: Core Network A Attachment Not Available

**Trigger:** The Cloud WAN attachment status for core network A is not available (step 5)
**Flow:**

1. System reports the attachment status as unavailable, pending, or failed.
2. Operator records that the current-deploy VPC's core-network-A attachment is the affected resource.
3. Use case ends.

### A3: Core Network A Not Available

**Trigger:** Core network A's status is not available (step 7)
**Flow:**

1. System reports core network A's status as unavailable or degraded.
2. Operator records that core network A itself is the affected resource.
3. Use case ends.

### A4: Core Network B Route Table Not Active

**Trigger:** The route table status for core network B is not active or is misconfigured (step 9)
**Flow:**

1. System reports the route table status as unavailable, inactive, or misconfigured.
2. Operator records that the current-deploy VPC's core-network-B route table is the affected resource.
3. Use case ends.

### A5: Core Network B Attachment Not Available

**Trigger:** The Cloud WAN attachment status for core network B is not available (step 11)
**Flow:**

1. System reports the attachment status as unavailable, pending, or failed.
2. Operator records that the current-deploy VPC's core-network-B attachment is the affected resource.
3. Use case ends.

### A6: Core Network B Not Available

**Trigger:** Core network B's status is not available (step 13)
**Flow:**

1. System reports core network B's status as unavailable or degraded.
2. Operator records that core network B itself is the affected resource.
3. Use case ends.

## Postconditions

### Success Postconditions

- The status of the current-deploy VPC's route table, Cloud WAN attachment, and core network A is confirmed available and recorded.
- The status of the current-deploy VPC's route table, Cloud WAN attachment, and core network B is confirmed available and recorded.

### Failure Postconditions

- The status of one or more resources (route table, attachment, or core network) is recorded as unavailable, inactive, or misconfigured, along with which specific resource and which core network is affected.
- No confirmation of full dual-home health is recorded until the affected resource is remediated and rechecked.

## Business Rules

### BR-001: Core Network Diagnostic Independence

Diagnosing the status of core network A's resources (route table, attachment, core network) must not require inspecting or touching any core network B resource, and vice versa. Each core network's three resource checks must be independently completable using only that core network's own resources.

### BR-002: Full Resource Coverage

Confirming dual-home deployment status requires checking all three resource types (route table, attachment, core network) for both the core-network-A attachment and the core-network-B attachment; checking only a subset does not constitute a complete status check.
