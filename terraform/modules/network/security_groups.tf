# terraform/modules/network/security_groups.tf
#
# One security group per VPC's workload subnet, scoped to TCP port 80 from the
# peer VPC's CIDR only — never 0.0.0.0/0 (architecture.md §3). current-deploy is
# the only VPC with two peers (old-deploy and future-deploy).
#
# Each also gets two 443 egress rules: one to that VPC's own endpoint security
# group (endpoints.tf, covers the ecr.api/ecr.dkr/logs *interface* endpoints —
# discovered when the connectivity-test tool's listener task failed with a
# `dial tcp ...:443: i/o timeout` pulling its image; security groups default-deny
# anything not explicitly listed, port 80 to the peer VPC doesn't cover this at
# all), and one to the region's S3 prefix list. The S3 gateway endpoint (unlike
# the interface endpoints) has no ENI or security group of its own — it's a
# route-table/prefix-list mechanism — so a security-group-referencing egress rule
# never matches S3-bound traffic; ECR stores image layers in S3, so without this
# second rule the image auth step succeeds but the layer download still times out.

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_security_group" "old_deploy_workload" {
  name        = "old-deploy-workload"
  description = "Allow TCP 80 to/from current-deploy VPC only"
  vpc_id      = aws_vpc.old_deploy.id

  ingress {
    description = "Port 80 from current-deploy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.current_deploy_vpc_cidr]
  }

  egress {
    description = "Port 80 to current-deploy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.current_deploy_vpc_cidr]
  }

  egress {
    description     = "HTTPS to old-deploy VPC endpoints (ECR/CloudWatch Logs)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.old_deploy_endpoints.id]
  }

  egress {
    description     = "HTTPS to S3 (ECR image layers, via S3 gateway endpoint)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  tags = {
    Name = "old-deploy-workload"
  }
}

resource "aws_security_group" "current_deploy_workload" {
  name        = "current-deploy-workload"
  description = "Allow TCP 80 to/from old-deploy and future-deploy VPCs only"
  vpc_id      = aws_vpc.current_deploy.id

  ingress {
    description = "Port 80 from old-deploy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.old_deploy_vpc_cidr]
  }

  ingress {
    description = "Port 80 from future-deploy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.future_deploy_vpc_cidr]
  }

  egress {
    description = "Port 80 to old-deploy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.old_deploy_vpc_cidr]
  }

  egress {
    description = "Port 80 to future-deploy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.future_deploy_vpc_cidr]
  }

  egress {
    description     = "HTTPS to current-deploy VPC endpoints (ECR/CloudWatch Logs)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.current_deploy_endpoints.id]
  }

  egress {
    description     = "HTTPS to S3 (ECR image layers, via S3 gateway endpoint)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  tags = {
    Name = "current-deploy-workload"
  }
}

resource "aws_security_group" "future_deploy_workload" {
  name        = "future-deploy-workload"
  description = "Allow TCP 80 to/from current-deploy VPC only"
  vpc_id      = aws_vpc.future_deploy.id

  ingress {
    description = "Port 80 from current-deploy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.current_deploy_vpc_cidr]
  }

  egress {
    description = "Port 80 to current-deploy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.current_deploy_vpc_cidr]
  }

  egress {
    description     = "HTTPS to future-deploy VPC endpoints (ECR/CloudWatch Logs)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.future_deploy_endpoints.id]
  }

  egress {
    description     = "HTTPS to S3 (ECR image layers, via S3 gateway endpoint)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  tags = {
    Name = "future-deploy-workload"
  }
}
