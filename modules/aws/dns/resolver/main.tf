# ===========================================================================
# AWS DNS — Route 53 Resolver Endpoints and Forwarding Rules
#
# Independently invocable: this module sources no other module in this
# framework. Subnet and security group IDs are plain inputs.
#
# Provider API divergence note (see README): AWS splits hybrid DNS into
# inbound/outbound endpoints plus per-domain resolver rules. Azure DNS
# Private Resolver mirrors this shape (inbound/outbound endpoints +
# forwarding rulesets). GCP instead uses zone-level forwarding and server
# policies; OCI attaches forwarding/listening endpoints to a VCN resolver.
# The rule-association model is the least portable element.
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
    module_source = "modules/aws/dns/resolver"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  rule_vpc_associations = merge([
    for rule_key, rule in var.forwarding_rules : {
      for vpc_id in rule.vpc_ids :
      "${rule_key}/${vpc_id}" => { rule_key = rule_key, vpc_id = vpc_id }
    }
  ]...)
}

# ---------------------------------------------------------------------------
# Inbound endpoint — on-premises -> VPC resolution
# ---------------------------------------------------------------------------
resource "aws_route53_resolver_endpoint" "inbound" {
  count = var.create_inbound_endpoint ? 1 : 0

  name               = "${local.name_base}-rslvr-in-${var.name_suffix}"
  direction          = "INBOUND"
  security_group_ids = var.inbound_security_group_ids

  dynamic "ip_address" {
    for_each = toset(var.inbound_subnet_ids)
    content {
      subnet_id = ip_address.value
    }
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Outbound endpoint — VPC -> on-premises/other resolution
# ---------------------------------------------------------------------------
resource "aws_route53_resolver_endpoint" "outbound" {
  count = var.create_outbound_endpoint ? 1 : 0

  name               = "${local.name_base}-rslvr-out-${var.name_suffix}"
  direction          = "OUTBOUND"
  security_group_ids = var.outbound_security_group_ids

  dynamic "ip_address" {
    for_each = toset(var.outbound_subnet_ids)
    content {
      subnet_id = ip_address.value
    }
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Forwarding rules + VPC associations
# ---------------------------------------------------------------------------
resource "aws_route53_resolver_rule" "this" {
  for_each = var.forwarding_rules

  name        = "${local.name_base}-rslvrule-${each.key}-${var.name_suffix}"
  domain_name = each.value.domain_name
  rule_type   = each.value.rule_type

  # FORWARD rules need the outbound endpoint; SYSTEM rules must not set it.
  resolver_endpoint_id = (
    each.value.rule_type == "FORWARD"
    ? aws_route53_resolver_endpoint.outbound[0].id
    : null
  )

  dynamic "target_ip" {
    for_each = each.value.rule_type == "FORWARD" ? each.value.target_ips : []
    content {
      ip   = target_ip.value.ip
      port = target_ip.value.port
    }
  }

  tags = local.all_tags
}

resource "aws_route53_resolver_rule_association" "this" {
  for_each = local.rule_vpc_associations

  resolver_rule_id = aws_route53_resolver_rule.this[each.value.rule_key].id
  vpc_id           = each.value.vpc_id
}

# ---------------------------------------------------------------------------
# Query logging (optional)
# ---------------------------------------------------------------------------
resource "aws_route53_resolver_query_log_config" "this" {
  count = var.query_log_destination_arn != null ? 1 : 0

  name            = "${local.name_base}-rslvrlog-${var.name_suffix}"
  destination_arn = var.query_log_destination_arn

  tags = local.all_tags
}

resource "aws_route53_resolver_query_log_config_association" "this" {
  for_each = var.query_log_destination_arn != null ? toset(var.query_log_vpc_ids) : toset([])

  resolver_query_log_config_id = aws_route53_resolver_query_log_config.this[0].id
  resource_id                  = each.value
}
