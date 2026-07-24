# terraform/modules/network/route_tables.tf
#
# A Cloud WAN VPC attachment being AVAILABLE (attachments.tf) does not, by itself,
# make traffic flow — a VPC's subnets still route only within their own VPC (the
# implicit "local" route) unless a route table explicitly points traffic at the
# core network. Without this file, UC-001/UC-002's port-80 checks would fail even
# though every other piece of the topology looks correct. Only workload subnets
# get a route: nothing is expected to originate from the attachment subnet.
#
# The route target is the core network's ARN, not an ENI or gateway ID — AWS
# resolves the actual next hop through Cloud WAN itself.

resource "aws_route_table" "old_deploy_workload" {
  vpc_id = aws_vpc.old_deploy.id

  tags = {
    Name = "old-deploy-workload-rt"
  }
}

resource "aws_route_table_association" "old_deploy_workload" {
  subnet_id      = aws_subnet.old_deploy_workload.id
  route_table_id = aws_route_table.old_deploy_workload.id
}

resource "aws_route" "old_deploy_to_current" {
  route_table_id         = aws_route_table.old_deploy_workload.id
  destination_cidr_block = var.current_deploy_vpc_cidr
  core_network_arn       = aws_networkmanager_core_network.a.arn

  depends_on = [aws_networkmanager_vpc_attachment.old_deploy_to_a]
}

resource "aws_route_table" "current_deploy_workload" {
  vpc_id = aws_vpc.current_deploy.id

  tags = {
    Name = "current-deploy-workload-rt"
  }
}

resource "aws_route_table_association" "current_deploy_workload" {
  subnet_id      = aws_subnet.current_deploy_workload.id
  route_table_id = aws_route_table.current_deploy_workload.id
}

# current-deploy is the pivot: its workload route table needs a route into EACH
# core network, one per peer — never a single route covering both, since that
# would blur the exact isolation boundary this project exists to test.
resource "aws_route" "current_deploy_to_old" {
  route_table_id         = aws_route_table.current_deploy_workload.id
  destination_cidr_block = var.old_deploy_vpc_cidr
  core_network_arn       = aws_networkmanager_core_network.a.arn

  depends_on = [aws_networkmanager_vpc_attachment.current_deploy_to_a]
}

resource "aws_route" "current_deploy_to_future" {
  route_table_id         = aws_route_table.current_deploy_workload.id
  destination_cidr_block = var.future_deploy_vpc_cidr
  core_network_arn       = aws_networkmanager_core_network.b.arn

  depends_on = [aws_networkmanager_vpc_attachment.current_deploy_to_b]
}

resource "aws_route_table" "future_deploy_workload" {
  vpc_id = aws_vpc.future_deploy.id

  tags = {
    Name = "future-deploy-workload-rt"
  }
}

resource "aws_route_table_association" "future_deploy_workload" {
  subnet_id      = aws_subnet.future_deploy_workload.id
  route_table_id = aws_route_table.future_deploy_workload.id
}

resource "aws_route" "future_deploy_to_current" {
  route_table_id         = aws_route_table.future_deploy_workload.id
  destination_cidr_block = var.current_deploy_vpc_cidr
  core_network_arn       = aws_networkmanager_core_network.b.arn

  depends_on = [aws_networkmanager_vpc_attachment.future_deploy_to_b]
}
