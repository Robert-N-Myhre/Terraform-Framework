# ===========================================================================
# AWS DNS — Route 53 Private Hosted Zones
#
# Independently invocable: this module sources no other module in this
# framework. VPC IDs for zone association are plain inputs.
#
# Provider API divergence note (see README): Route 53 private zones bind to
# VPCs inline on the zone resource. Azure Private DNS uses a separate
# virtual_network_link resource; GCP private zones take a list of network
# self-links; OCI uses DNS views attached to resolvers. The association
# model is the least portable part of the DNS domain.
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
    module_source = "modules/aws/dns/private-zones"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  records = merge([
    for zone_key, zone in var.private_zones : {
      for rec_key, rec in zone.records :
      "${zone_key}/${rec_key}" => merge(rec, { zone_key = zone_key })
    }
  ]...)
}

resource "aws_route53_zone" "this" {
  for_each = var.private_zones

  name    = each.value.domain_name
  comment = each.value.comment

  # Route 53 requires at least one VPC at creation time for a private zone.
  # All associations are managed inline here; do not mix inline and
  # standalone aws_route53_zone_association for the same zone.
  dynamic "vpc" {
    for_each = each.value.vpc_associations
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-zone-${each.key}-${var.name_suffix}"
  })
}

resource "aws_route53_record" "this" {
  for_each = local.records

  zone_id = aws_route53_zone.this[each.value.zone_key].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.values
}
