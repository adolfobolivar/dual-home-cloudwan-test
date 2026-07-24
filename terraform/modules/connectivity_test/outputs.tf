# terraform/modules/connectivity_test/outputs.tf
# Consumed by scripts/run-connectivity-check.sh via `terraform output -json`.

output "ecr_repository_url" {
  value = aws_ecr_repository.connectivity_test.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "task_definition_family" {
  value = aws_ecs_task_definition.connectivity_test.family
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.connectivity_test.name
}
