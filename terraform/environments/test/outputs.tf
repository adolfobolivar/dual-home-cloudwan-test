# terraform/environments/test/outputs.tf
# Re-exports the network module's outputs for UC-003's status checks.

output "vpc_ids" {
  value = module.network.vpc_ids
}

output "workload_subnet_ids" {
  value = module.network.workload_subnet_ids
}

output "security_group_ids" {
  value = module.network.security_group_ids
}

output "core_network_ids" {
  value = module.network.core_network_ids
}

output "vpc_attachment_ids" {
  value = module.network.vpc_attachment_ids
}

output "workload_route_table_ids" {
  value = module.network.workload_route_table_ids
}

output "ecr_repository_url" {
  value = module.connectivity_test.ecr_repository_url
}

output "ecs_cluster_name" {
  value = module.connectivity_test.ecs_cluster_name
}

output "task_definition_family" {
  value = module.connectivity_test.task_definition_family
}

output "log_group_name" {
  value = module.connectivity_test.log_group_name
}
