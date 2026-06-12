# ===========================================================================
# AWS Firewall — Security Groups
#
# Independently invocable: this module sources no other module in this
# framework. The target VPC is supplied by ID, never by module reference.
#
# Provider API divergence note (see README): AWS security groups are
# stateful and attach to ENIs at instance/service level. Azure NSGs attach
# to subnets or NICs; GCP firewall rules are VPC-global and target by
# tag/service-account; OCI offers both subnet-level security lists and
# NSGs. This module models SG-to-SG references natively via
# referenced_security_group_key, a pattern that has no direct equivalent
# in GCP VPC firewall rules (which reference tags instead).
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-aws-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/aws/firewall/security-groups"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  # Flatten rule maps to "<sg-key>/<rule-key>" for stable for_each addresses.
  ingress_rules = merge([
    for sg_key, sg in var.security_groups : {
      for rule_key, rule in sg.ingress_rules :
      "${sg_key}/${rule_key}" => merge(rule, { sg_key = sg_key })
    }
  ]...)

  egress_rules = merge([
    for sg_key, sg in var.security_groups : {
      for rule_key, rule in sg.egress_rules :
      "${sg_key}/${rule_key}" => merge(rule, { sg_key = sg_key })
    }
  ]...)

  default_egress_sgs = var.default_egress_allow_all ? {
    for sg_key, sg in var.security_groups : sg_key => sg if length(sg.egress_rules) == 0
  } : {}
}

resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = "${local.name_base}-sg-${each.key}-${var.name_suffix}"
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-sg-${each.key}-${var.name_suffix}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.ingress_rules

  security_group_id = aws_security_group.this[each.value.sg_key].id
  description       = each.value.description
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.ip_protocol == "-1" ? null : each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
  cidr_ipv6         = each.value.cidr_ipv6
  prefix_list_id    = each.value.prefix_list_id

  referenced_security_group_id = (
    each.value.referenced_security_group_key != null
    ? aws_security_group.this[each.value.referenced_security_group_key].id
    : each.value.referenced_security_group_id
  )

  tags = local.all_tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id = aws_security_group.this[each.value.sg_key].id
  description       = each.value.description
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.ip_protocol == "-1" ? null : each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
  cidr_ipv6         = each.value.cidr_ipv6
  prefix_list_id    = each.value.prefix_list_id

  referenced_security_group_id = (
    each.value.referenced_security_group_key != null
    ? aws_security_group.this[each.value.referenced_security_group_key].id
    : each.value.referenced_security_group_id
  )

  tags = local.all_tags
}

resource "aws_vpc_security_group_egress_rule" "default_allow_all" {
  for_each = local.default_egress_sgs

  security_group_id = aws_security_group.this[each.key].id
  description       = "Default allow-all egress (default_egress_allow_all = true)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.all_tags
}
