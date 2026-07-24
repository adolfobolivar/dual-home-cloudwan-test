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
