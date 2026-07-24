# terraform/modules/network/main.tf
#
# Two fully independent Cloud WAN core networks (architecture.md §1). AWS Network
# Manager ties a global network to exactly one core network (a global network
# "contains a single core network" — confirmed against AWS's own docs after
# `CreateCoreNetwork` rejected a second core network on one global network with
# "Global Network ID is already associated with another core network"), so each
# core network gets its own global network — one shared global network for both
# was never possible, and separate ones only reinforce that core network A and B
# never share an ASN, a segment, or an attachment policy rule (requirements.md
# NFR-001).

resource "aws_networkmanager_global_network" "a" {
  description = "Global network for core network A (old-deploy <-> current-deploy)."

  tags = {
    Name = "dual-home-cloudwan-test-global-network-a"
  }
}

resource "aws_networkmanager_global_network" "b" {
  description = "Global network for core network B (current-deploy <-> future-deploy)."

  tags = {
    Name = "dual-home-cloudwan-test-global-network-b"
  }
}

# Core network A: old-deploy <-> current-deploy.
data "aws_networkmanager_core_network_policy_document" "a" {
  core_network_configuration {
    # AWS rejects a degenerate single-value range (e.g. "64512-64512") with
    # INVALID_ASN_RANGE, so this reserves a 2-ASN range starting at
    # core_network_a_asn — AWS auto-assigns one of the two to the single edge
    # location. core_network_a_asn/core_network_b_asn must stay far enough apart
    # that the two ranges never overlap (input.yaml keeps a 2-value gap).
    asn_ranges = ["${var.core_network_a_asn}-${var.core_network_a_asn + 1}"]

    edge_locations {
      location = var.aws_region
    }
  }

  segments {
    name                          = var.core_network_a_segment
    require_attachment_acceptance = false
  }

  # Tag-based attachment policy: an attachment lands in this segment only if it
  # carries the matching "cloudwan-segment" tag (FR-003) — not a blanket "any"
  # rule, so an attachment tagged for segment B can never land in segment A.
  attachment_policies {
    rule_number     = 100
    condition_logic = "and"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "cloudwan-segment"
      value    = var.core_network_a_segment
    }

    action {
      association_method = "constant"
      segment            = var.core_network_a_segment
    }
  }
}

resource "aws_networkmanager_core_network" "a" {
  # No create_base_policy: that auto-generates a base policy with the full default
  # ASN range (64512-65534) and immediately assigns an edge an ASN from it. If our
  # real policy below then narrows the range to [asn, asn+1], AWS rejects it with
  # INVALID_ASN_UPDATE whenever the auto-assigned ASN falls outside that range —
  # non-deterministic, so this project's real policy is the first policy applied
  # instead, with no prior ASN assignment to conflict with.
  global_network_id = aws_networkmanager_global_network.a.id

  tags = {
    Name = "dual-home-cloudwan-test-core-network-a"
  }
}

resource "aws_networkmanager_core_network_policy_attachment" "a" {
  core_network_id = aws_networkmanager_core_network.a.id
  policy_document = data.aws_networkmanager_core_network_policy_document.a.json
}

# Core network B: current-deploy <-> future-deploy. Independent ASN/segment/policy
# from core network A above — no shared resource, no shared identifier.
data "aws_networkmanager_core_network_policy_document" "b" {
  core_network_configuration {
    asn_ranges = ["${var.core_network_b_asn}-${var.core_network_b_asn + 1}"]

    edge_locations {
      location = var.aws_region
    }
  }

  segments {
    name                          = var.core_network_b_segment
    require_attachment_acceptance = false
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "and"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "cloudwan-segment"
      value    = var.core_network_b_segment
    }

    action {
      association_method = "constant"
      segment            = var.core_network_b_segment
    }
  }
}

resource "aws_networkmanager_core_network" "b" {
  global_network_id = aws_networkmanager_global_network.b.id

  tags = {
    Name = "dual-home-cloudwan-test-core-network-b"
  }
}

resource "aws_networkmanager_core_network_policy_attachment" "b" {
  core_network_id = aws_networkmanager_core_network.b.id
  policy_document = data.aws_networkmanager_core_network_policy_document.b.json
}
