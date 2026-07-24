# Use Case: Verify Old-Deploy to Current-Deploy Connectivity

## Overview

**Use Case ID:** UC-001
**Use Case Name:** Verify Old-Deploy to Current-Deploy Connectivity
**Primary Actor:** Network Operator
**Goal:** Confirm bidirectional TCP port-80 connectivity between the old-deploy VPC and the current-deploy VPC over core network A
**Status:** Draft

## Preconditions

- The old-deploy VPC and the current-deploy VPC are deployed, each with a Cloud WAN attachment to core network A.
- Both VPC attachments have been accepted (automatically, per the tag-based attachment policy).
- The Network Operator has access to a connectivity test tool or script capable of testing TCP port-80 reachability between hosts in the two VPCs.

## Main Success Scenario

1. Network Operator selects the old-deploy VPC and the current-deploy VPC as the pair to test.
2. Operator runs the connectivity test tool to attempt a TCP port-80 connection from a host in the old-deploy VPC to a host in the current-deploy VPC.
3. Tool reports that the old-deploy-to-current-deploy connection attempt succeeded.
4. Operator runs the connectivity test tool to attempt a TCP port-80 connection from a host in the current-deploy VPC to a host in the old-deploy VPC.
5. Tool reports that the current-deploy-to-old-deploy connection attempt succeeded.
6. Operator records that bidirectional port-80 connectivity between the old-deploy VPC and the current-deploy VPC is confirmed.

## Alternative Flows

### A1: Old-Deploy-to-Current-Deploy Connection Fails

**Trigger:** The old-deploy-to-current-deploy connection attempt fails (step 3)
**Flow:**

1. Tool reports that the connection attempt failed or timed out.
2. Operator checks the route tables, VPC attachment status, and core network status for the old-deploy and current-deploy VPCs (per UC-003) to diagnose the failure.
3. Use case ends.

### A2: Current-Deploy-to-Old-Deploy Connection Fails

**Trigger:** The current-deploy-to-old-deploy connection attempt fails (step 5)
**Flow:**

1. Tool reports that the connection attempt failed or timed out.
2. Operator checks the route tables, VPC attachment status, and core network status for the old-deploy and current-deploy VPCs (per UC-003) to diagnose the failure.
3. Use case ends.

## Postconditions

### Success Postconditions

- Bidirectional TCP port-80 connectivity between the old-deploy VPC and the current-deploy VPC is confirmed and recorded.

### Failure Postconditions

- No bidirectional connectivity confirmation is recorded for the old-deploy and current-deploy VPC pair.
- The Operator has diagnostic information (route table, attachment, and core network status) identifying the point of failure.

## Business Rules

### BR-001: Independent Direction Verification

Connectivity in both directions (old-deploy-to-current-deploy and current-deploy-to-old-deploy) must be tested and must each succeed independently; success in one direction does not imply success in the other.

### BR-002: Old-Deploy-to-Future-Deploy Path Must Not Exist

This connectivity check must never succeed, directly or indirectly, between the old-deploy VPC and the future-deploy VPC. No test in this use case exercises that path, and no route or attachment may cause it to become reachable.
