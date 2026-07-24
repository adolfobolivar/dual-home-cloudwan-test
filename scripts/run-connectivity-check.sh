#!/usr/bin/env bash
# scripts/run-connectivity-check.sh — the "connectivity test tool or script" that
# UC-001/UC-002/UC-003 refer to. Runs a one-shot, on-demand port-80 connectivity
# check between two VPCs using the ECS Fargate tooling in architecture.md §6:
# starts a bounded-duration listener task in the target VPC, starts a check task
# in the source VPC that attempts a single TCP connection to it, reports
# PASS/FAIL, and stops the listener — nothing is left running afterward.
#
# Usage: scripts/run-connectivity-check.sh <source> <target>
#   <source>/<target> one of: old, current, future
#
# Examples (see docs/use-cases for the exact scenarios):
#   scripts/run-connectivity-check.sh old current      # UC-001
#   scripts/run-connectivity-check.sh current future    # UC-002
#   scripts/run-connectivity-check.sh old future         # expected to FAIL (no path)
set -euo pipefail

SOURCE=${1:-}
TARGET=${2:-}

if [[ -z "$SOURCE" || -z "$TARGET" ]]; then
  echo "Usage: $0 <source: old|current|future> <target: old|current|future>" >&2
  exit 2
fi

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform/environments/test" && pwd)"
cd "$ENV_DIR"

if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
  export AWS_ACCESS_KEY_ID
  AWS_ACCESS_KEY_ID=$(python3 -c "import yaml; print(yaml.safe_load(open('secrets.yaml'))['aws_access_key_id'])")
fi
if [[ -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  export AWS_SECRET_ACCESS_KEY
  AWS_SECRET_ACCESS_KEY=$(python3 -c "import yaml; print(yaml.safe_load(open('secrets.yaml'))['aws_secret_access_key'])")
fi
export AWS_DEFAULT_REGION=us-east-2

OUT=$(terraform output -json)

# terraform outputs key VPCs as old_deploy/current_deploy/future_deploy.
SOURCE_KEY="${SOURCE}_deploy"
TARGET_KEY="${TARGET}_deploy"

json_get() { python3 -c "import json,sys; print(json.loads(sys.argv[1])['$1']['value']['$2'])" "$OUT"; }

CLUSTER=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['ecs_cluster_name']['value'])" "$OUT")
TASK_DEF=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['task_definition_family']['value'])" "$OUT")
SUBNET_SOURCE=$(json_get workload_subnet_ids "$SOURCE_KEY")
SG_SOURCE=$(json_get security_group_ids "$SOURCE_KEY")
SUBNET_TARGET=$(json_get workload_subnet_ids "$TARGET_KEY")
SG_TARGET=$(json_get security_group_ids "$TARGET_KEY")

echo "Cluster: $CLUSTER   Task definition: $TASK_DEF"
echo "Source ($SOURCE): subnet=$SUBNET_SOURCE sg=$SG_SOURCE"
echo "Target ($TARGET): subnet=$SUBNET_TARGET sg=$SG_TARGET"

echo
echo "Starting listener task in $TARGET..."
LISTENER_TASK_ARN=$(aws ecs run-task \
  --cluster "$CLUSTER" \
  --task-definition "$TASK_DEF" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_TARGET],securityGroups=[$SG_TARGET],assignPublicIp=DISABLED}" \
  --overrides '{"containerOverrides":[{"name":"connectivity-test","command":["listen"]}]}' \
  --query 'tasks[0].taskArn' --output text)
echo "Listener task: $LISTENER_TASK_ARN"

cleanup() {
  echo "Stopping listener task..."
  aws ecs stop-task --cluster "$CLUSTER" --task "$LISTENER_TASK_ARN" --reason "connectivity check complete" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Waiting for listener task to reach RUNNING..."
aws ecs wait tasks-running --cluster "$CLUSTER" --tasks "$LISTENER_TASK_ARN"

ENI_ID=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$LISTENER_TASK_ARN" \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value | [0]' --output text)
TARGET_IP=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI_ID" \
  --query 'NetworkInterfaces[0].PrivateIpAddress' --output text)
echo "Listener private IP: $TARGET_IP"

echo
echo "Starting check task in $SOURCE (connecting to $TARGET_IP:80)..."
CHECK_TASK_ARN=$(aws ecs run-task \
  --cluster "$CLUSTER" \
  --task-definition "$TASK_DEF" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_SOURCE],securityGroups=[$SG_SOURCE],assignPublicIp=DISABLED}" \
  --overrides "{\"containerOverrides\":[{\"name\":\"connectivity-test\",\"command\":[\"check\",\"$TARGET_IP\"]}]}" \
  --query 'tasks[0].taskArn' --output text)
echo "Check task: $CHECK_TASK_ARN"

echo "Waiting for check task to stop..."
aws ecs wait tasks-stopped --cluster "$CLUSTER" --tasks "$CHECK_TASK_ARN"

EXIT_CODE=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$CHECK_TASK_ARN" \
  --query 'tasks[0].containers[0].exitCode' --output text)

echo
if [[ "$EXIT_CODE" == "0" ]]; then
  echo "RESULT: PASS ($SOURCE -> $TARGET, $TARGET_IP:80 reachable)"
  exit 0
else
  echo "RESULT: FAIL ($SOURCE -> $TARGET), container exit code $EXIT_CODE"
  exit 1
fi
