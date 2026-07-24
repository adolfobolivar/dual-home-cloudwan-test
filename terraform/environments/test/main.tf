# terraform/environments/test/main.tf
# Wires the network module to this environment's input.yaml values
# (architecture.md §5) — every argument below is a local.input.<key> read, never a
# literal.

module "network" {
  source = "../../modules/network"

  aws_region              = local.input.aws_region
  old_deploy_vpc_cidr     = local.input.old_deploy_vpc_cidr
  current_deploy_vpc_cidr = local.input.current_deploy_vpc_cidr
  future_deploy_vpc_cidr  = local.input.future_deploy_vpc_cidr
  core_network_a_asn      = local.input.core_network_a_asn
  core_network_b_asn      = local.input.core_network_b_asn
  core_network_a_segment  = local.input.core_network_a_segment
  core_network_b_segment  = local.input.core_network_b_segment
}
