# terraform/modules/network/endpoints.tf
#
# Every VPC here is fully private (no internet gateway, no NAT) by design. Fargate
# still has to pull a container image and ship logs somewhere on every task start
# (architecture.md §6), so each VPC gets its own VPC endpoints: interface endpoints
# for ECR's API/registry calls and CloudWatch Logs, plus a free S3 gateway endpoint
# (ECR stores image layers in S3). This only works for a *private* ECR repository
# in this same region — ECR Public Gallery (public.ecr.aws) is a us-east-1-only
# service with no regional VPC endpoint, so it's unreachable from here regardless.
#
# The endpoint security group has no egress rule at all, intentionally: security
# groups are stateful, so return traffic for an already-allowed inbound connection
# doesn't need a matching egress rule, and these endpoint ENIs never initiate
# outbound connections of their own.

locals {
  interface_endpoint_services = ["ecr.api", "ecr.dkr", "logs"]
}

# --- old-deploy ---

resource "aws_security_group" "old_deploy_endpoints" {
  name        = "old-deploy-vpc-endpoints"
  description = "Allow TCP 443 from within old-deploy VPC to its VPC endpoints"
  vpc_id      = aws_vpc.old_deploy.id

  ingress {
    description = "HTTPS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.old_deploy_vpc_cidr]
  }

  tags = {
    Name = "old-deploy-vpc-endpoints"
  }
}

resource "aws_vpc_endpoint" "old_deploy" {
  for_each = toset(local.interface_endpoint_services)

  vpc_id              = aws_vpc.old_deploy.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.old_deploy_workload.id]
  security_group_ids  = [aws_security_group.old_deploy_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "old-deploy-${each.value}"
  }
}

resource "aws_vpc_endpoint" "old_deploy_s3" {
  vpc_id            = aws_vpc.old_deploy.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.old_deploy_workload.id]

  tags = {
    Name = "old-deploy-s3"
  }
}

# --- current-deploy ---

resource "aws_security_group" "current_deploy_endpoints" {
  name        = "current-deploy-vpc-endpoints"
  description = "Allow TCP 443 from within current-deploy VPC to its VPC endpoints"
  vpc_id      = aws_vpc.current_deploy.id

  ingress {
    description = "HTTPS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.current_deploy_vpc_cidr]
  }

  tags = {
    Name = "current-deploy-vpc-endpoints"
  }
}

resource "aws_vpc_endpoint" "current_deploy" {
  for_each = toset(local.interface_endpoint_services)

  vpc_id              = aws_vpc.current_deploy.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.current_deploy_workload.id]
  security_group_ids  = [aws_security_group.current_deploy_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "current-deploy-${each.value}"
  }
}

resource "aws_vpc_endpoint" "current_deploy_s3" {
  vpc_id            = aws_vpc.current_deploy.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.current_deploy_workload.id]

  tags = {
    Name = "current-deploy-s3"
  }
}

# --- future-deploy ---

resource "aws_security_group" "future_deploy_endpoints" {
  name        = "future-deploy-vpc-endpoints"
  description = "Allow TCP 443 from within future-deploy VPC to its VPC endpoints"
  vpc_id      = aws_vpc.future_deploy.id

  ingress {
    description = "HTTPS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.future_deploy_vpc_cidr]
  }

  tags = {
    Name = "future-deploy-vpc-endpoints"
  }
}

resource "aws_vpc_endpoint" "future_deploy" {
  for_each = toset(local.interface_endpoint_services)

  vpc_id              = aws_vpc.future_deploy.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.future_deploy_workload.id]
  security_group_ids  = [aws_security_group.future_deploy_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "future-deploy-${each.value}"
  }
}

resource "aws_vpc_endpoint" "future_deploy_s3" {
  vpc_id            = aws_vpc.future_deploy.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.future_deploy_workload.id]

  tags = {
    Name = "future-deploy-s3"
  }
}
