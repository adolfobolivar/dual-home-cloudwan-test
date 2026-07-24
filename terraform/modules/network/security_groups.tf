# terraform/modules/network/security_groups.tf
#
# One security group per VPC's workload subnet, scoped to TCP port 80 from the
# peer VPC's CIDR only — never 0.0.0.0/0 (architecture.md §3). current-deploy is
# the only VPC with two peers (old-deploy and future-deploy).

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

  tags = {
    Name = "future-deploy-workload"
  }
}
