# terraform/modules/network/vpcs.tf
#
# Three VPCs standing in for successive deployment generations. Each gets two
# subnets — workload and Cloud WAN attachment (architecture.md §2) — derived from
# the VPC's own CIDR via cidrsubnet(), never a separate hardcoded CIDR.

data "aws_availability_zones" "available" {
  state = "available"
}

# --- old-deploy ---

resource "aws_vpc" "old_deploy" {
  cidr_block           = var.old_deploy_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "old-deploy-vpc"
  }
}

resource "aws_subnet" "old_deploy_workload" {
  vpc_id            = aws_vpc.old_deploy.id
  cidr_block        = cidrsubnet(var.old_deploy_vpc_cidr, 1, 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "old-deploy-workload"
  }
}

resource "aws_subnet" "old_deploy_attachment" {
  vpc_id            = aws_vpc.old_deploy.id
  cidr_block        = cidrsubnet(var.old_deploy_vpc_cidr, 1, 1)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "old-deploy-attachment"
  }
}

# --- current-deploy ---

resource "aws_vpc" "current_deploy" {
  cidr_block           = var.current_deploy_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "current-deploy-vpc"
  }
}

resource "aws_subnet" "current_deploy_workload" {
  vpc_id            = aws_vpc.current_deploy.id
  cidr_block        = cidrsubnet(var.current_deploy_vpc_cidr, 1, 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "current-deploy-workload"
  }
}

resource "aws_subnet" "current_deploy_attachment" {
  vpc_id            = aws_vpc.current_deploy.id
  cidr_block        = cidrsubnet(var.current_deploy_vpc_cidr, 1, 1)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "current-deploy-attachment"
  }
}

# --- future-deploy ---

resource "aws_vpc" "future_deploy" {
  cidr_block           = var.future_deploy_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "future-deploy-vpc"
  }
}

resource "aws_subnet" "future_deploy_workload" {
  vpc_id            = aws_vpc.future_deploy.id
  cidr_block        = cidrsubnet(var.future_deploy_vpc_cidr, 1, 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "future-deploy-workload"
  }
}

resource "aws_subnet" "future_deploy_attachment" {
  vpc_id            = aws_vpc.future_deploy.id
  cidr_block        = cidrsubnet(var.future_deploy_vpc_cidr, 1, 1)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "future-deploy-attachment"
  }
}
