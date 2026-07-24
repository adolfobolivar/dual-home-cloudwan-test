# terraform/modules/network/variables.tf
# All values are passed from the environment root's local.input (architecture.md §5)
# — never a literal here, never a .tfvars file.

variable "aws_region" {
  type        = string
  description = "AWS region for the Cloud WAN edge location (architecture.md §1)."
}

variable "old_deploy_vpc_cidr" {
  type        = string
  description = "CIDR block for the old-deploy VPC."
}

variable "current_deploy_vpc_cidr" {
  type        = string
  description = "CIDR block for the current-deploy VPC."
}

variable "future_deploy_vpc_cidr" {
  type        = string
  description = "CIDR block for the future-deploy VPC."
}

variable "core_network_a_asn" {
  type        = number
  description = "Start of the 2-ASN range reserved for core network A (old-deploy <-> current-deploy). AWS rejects a degenerate single-value ASN range, so the module reserves [asn, asn+1]. Must not overlap core_network_b_asn's range (architecture.md §2, requirements.md NFR-001)."
}

variable "core_network_b_asn" {
  type        = number
  description = "Start of the 2-ASN range reserved for core network B (current-deploy <-> future-deploy). Must not overlap core_network_a_asn's range (architecture.md §2, requirements.md NFR-001)."
}

variable "core_network_a_segment" {
  type        = string
  description = "Cloud WAN segment name for core network A. Must differ from core_network_b_segment (architecture.md §2, requirements.md NFR-001)."
}

variable "core_network_b_segment" {
  type        = string
  description = "Cloud WAN segment name for core network B. Must differ from core_network_a_segment (architecture.md §2, requirements.md NFR-001)."
}
