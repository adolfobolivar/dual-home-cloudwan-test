# terraform/modules/network/outputs.tf
# Exposed for UC-003's status checks (route tables / attachments / core networks)
# and for the future Fargate connectivity-check tooling (architecture.md §6).

output "vpc_ids" {
  value = {
    old_deploy     = aws_vpc.old_deploy.id
    current_deploy = aws_vpc.current_deploy.id
    future_deploy  = aws_vpc.future_deploy.id
  }
}

output "workload_subnet_ids" {
  value = {
    old_deploy     = aws_subnet.old_deploy_workload.id
    current_deploy = aws_subnet.current_deploy_workload.id
    future_deploy  = aws_subnet.future_deploy_workload.id
  }
}

output "security_group_ids" {
  value = {
    old_deploy     = aws_security_group.old_deploy_workload.id
    current_deploy = aws_security_group.current_deploy_workload.id
    future_deploy  = aws_security_group.future_deploy_workload.id
  }
}

output "core_network_ids" {
  value = {
    a = aws_networkmanager_core_network.a.id
    b = aws_networkmanager_core_network.b.id
  }
}

output "vpc_attachment_ids" {
  value = {
    old_deploy_to_a     = aws_networkmanager_vpc_attachment.old_deploy_to_a.id
    current_deploy_to_a = aws_networkmanager_vpc_attachment.current_deploy_to_a.id
    current_deploy_to_b = aws_networkmanager_vpc_attachment.current_deploy_to_b.id
    future_deploy_to_b  = aws_networkmanager_vpc_attachment.future_deploy_to_b.id
  }
}

output "workload_route_table_ids" {
  value = {
    old_deploy     = aws_route_table.old_deploy_workload.id
    current_deploy = aws_route_table.current_deploy_workload.id
    future_deploy  = aws_route_table.future_deploy_workload.id
  }
}
