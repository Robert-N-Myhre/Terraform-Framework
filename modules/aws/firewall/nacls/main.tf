# ===========================================================================
# AWS Firewall — Network ACLs
#
# Independently invocable: this module sources no other module in this
# framework. VPC and subnet IDs are supplied as plain values.
#
# Provider API divergence note (see README): NACLs are STATELESS subnet-level
# filters — the closest cross-cloud analogue is the OCI security list (which
# is stateful by default but supports stateless rules). Azure NSGs and GCP
# firewall rules are stateful; consumers porting rules between clouds must
# add explicit return-path rules here that the stateful clouds infer.
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
    module_source = "modules/aws/firewall/nacls"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  ingress_rules = merge([
    for acl_key, acl in var.network_acls : {
      for rule_key, rule in acl.ingress_rules :
      "${acl_key}/${rule_key}" => merge(rule, { acl_key = acl_key })
    }
  ]...)

  egress_rules = merge([
    for acl_key, acl in var.network_acls : {
      for rule_key, rule in acl.egress_rules :
      "${acl_key}/${rule_key}" => merge(rule, { acl_key = acl_key })
    }
  ]...)

  subnet_associations = merge([
    for acl_key, acl in var.network_acls : {
      for idx, subnet_id in acl.subnet_ids :
      "${acl_key}/${subnet_id}" => { acl_key = acl_key, subnet_id = subnet_id }
    }
  ]...)
}

resource "aws_network_acl" "this" {
  for_each = var.network_acls

  vpc_id = var.vpc_id

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-nacl-${each.key}-${var.name_suffix}"
  })
}

resource "aws_network_acl_rule" "ingress" {
  for_each = local.ingress_rules

  network_acl_id = aws_network_acl.this[each.value.acl_key].id
  egress         = false
  rule_number    = each.value.rule_number
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  icmp_type      = each.value.icmp_type
  icmp_code      = each.value.icmp_code
}

resource "aws_network_acl_rule" "egress" {
  for_each = local.egress_rules

  network_acl_id = aws_network_acl.this[each.value.acl_key].id
  egress         = true
  rule_number    = each.value.rule_number
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  icmp_type      = each.value.icmp_type
  icmp_code      = each.value.icmp_code
}

resource "aws_network_acl_association" "this" {
  for_each = local.subnet_associations

  network_acl_id = aws_network_acl.this[each.value.acl_key].id
  subnet_id      = each.value.subnet_id
}
