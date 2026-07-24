# terraform/modules/network/attachments.tf
#
# VPC attachments into the two core networks. current-deploy is the only VPC
# attached to both (architecture.md §1) — it reuses its single attachment subnet for
# both attachments, since each attachment is scoped by core_network_id, not subnet.
#
# The "cloudwan-segment" tag is a functional tag the attachment-policies in main.tf
# match on to route each attachment into the right segment automatically (FR-003) —
# it is not one of the four mandated Environment/Project/Owner/ManagedBy tags (those
# come from the provider's default_tags and merge with this one), so this is not the
# per-resource tagging the terraform-module skill's DO-NOT list warns against. "Name"
# is the one mandated per-resource tag (architecture.md §5) and sits alongside it.
#
# Each attachment explicitly depends on its core network's *real* policy attachment
# (main.tf), not just the core network resource itself — core_network_id is available
# as soon as the core network exists with only its auto-generated base policy, which
# has no "cloudwan-segment"-matching rule yet. Without depends_on, Terraform could
# create the VPC attachment before the real policy lands, and it would fail to match
# any attachment-policy rule.

resource "aws_networkmanager_vpc_attachment" "old_deploy_to_a" {
  core_network_id = aws_networkmanager_core_network.a.id
  vpc_arn         = aws_vpc.old_deploy.arn
  subnet_arns     = [aws_subnet.old_deploy_attachment.arn]

  tags = {
    Name               = "old-deploy-to-core-network-a"
    "cloudwan-segment" = var.core_network_a_segment
  }

  depends_on = [aws_networkmanager_core_network_policy_attachment.a]
}

resource "aws_networkmanager_vpc_attachment" "current_deploy_to_a" {
  core_network_id = aws_networkmanager_core_network.a.id
  vpc_arn         = aws_vpc.current_deploy.arn
  subnet_arns     = [aws_subnet.current_deploy_attachment.arn]

  tags = {
    Name               = "current-deploy-to-core-network-a"
    "cloudwan-segment" = var.core_network_a_segment
  }

  depends_on = [aws_networkmanager_core_network_policy_attachment.a]
}

resource "aws_networkmanager_vpc_attachment" "current_deploy_to_b" {
  core_network_id = aws_networkmanager_core_network.b.id
  vpc_arn         = aws_vpc.current_deploy.arn
  subnet_arns     = [aws_subnet.current_deploy_attachment.arn]

  tags = {
    Name               = "current-deploy-to-core-network-b"
    "cloudwan-segment" = var.core_network_b_segment
  }

  depends_on = [aws_networkmanager_core_network_policy_attachment.b]
}

resource "aws_networkmanager_vpc_attachment" "future_deploy_to_b" {
  core_network_id = aws_networkmanager_core_network.b.id
  vpc_arn         = aws_vpc.future_deploy.arn
  subnet_arns     = [aws_subnet.future_deploy_attachment.arn]

  tags = {
    Name               = "future-deploy-to-core-network-b"
    "cloudwan-segment" = var.core_network_b_segment
  }

  depends_on = [aws_networkmanager_core_network_policy_attachment.b]
}
