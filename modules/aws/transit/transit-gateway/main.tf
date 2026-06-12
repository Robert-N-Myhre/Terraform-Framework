# ===========================================================================
# AWS Transit — Transit Gateway (hub-and-spoke)
#
# Independently invocable: this module sources no other module in this
# framework. Attached VPCs/subnets are plain ID inputs.
#
# Provider API divergence note (see README): TGW is a regional routed hub
# with its own route tables, associations, and propagations. Azure's
# analogue is Virtual WAN (vhub); GCP's is Network Connectivity Center
# (hub+spokes, no TGW-style custom route tables); OCI's is the DRG with
# DRG route tables and import distribution lists. Segmentation models
# differ enough that route-table design does not port 1:1.
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
    module_source = "modules/aws/transit/transit-gateway"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  propagations = merge([
    for att_key, att in var.vpc_attachments : {
      for rt_key in att.propagate_to :
      "${att_key}/${rt_key}" => { attachment_key = att_key, route_table_key = rt_key }
    }
  ]...)

  associations = {
    for att_key, att in var.vpc_attachments :
    att_key => att.route_table_key if att.route_table_key != null
  }
}

resource "aws_ec2_transit_gateway" "this" {
  description     = var.description
  amazon_side_asn = var.amazon_side_asn

  default_route_table_association = var.enable_default_route_table_association ? "enable" : "disable"
  default_route_table_propagation = var.enable_default_route_table_propagation ? "enable" : "disable"
  dns_support                     = var.enable_dns_support ? "enable" : "disable"
  vpn_ecmp_support                = var.enable_vpn_ecmp_support ? "enable" : "disable"
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments ? "enable" : "disable"

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-tgw-${var.name_suffix}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.vpc_attachments

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.subnet_ids

  appliance_mode_support = each.value.appliance_mode ? "enable" : "disable"
  dns_support            = each.value.dns_support ? "enable" : "disable"

  # When custom route tables are used, the default association/propagation
  # flags above are disabled and these explicit resources take over.
  transit_gateway_default_route_table_association = var.enable_default_route_table_association
  transit_gateway_default_route_table_propagation = var.enable_default_route_table_propagation

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-tgwatt-${each.key}-${var.name_suffix}"
  })
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each = var.route_tables

  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-tgwrt-${each.value}-${var.name_suffix}"
  })
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = local.associations

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = local.propagations

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment_key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_key].id
}

resource "aws_ec2_transit_gateway_route" "this" {
  for_each = var.static_routes

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_key].id
  destination_cidr_block         = each.value.destination_cidr
  blackhole                      = each.value.blackhole

  transit_gateway_attachment_id = (
    each.value.blackhole
    ? null
    : aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment_key].id
  )
}
