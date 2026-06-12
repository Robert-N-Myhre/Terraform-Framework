# ===========================================================================
# AWS Hybrid Connectivity — Site-to-Site VPN
#
# Independently invocable: this module sources no other module in this
# framework. VPC or transit gateway IDs are plain inputs.
#
# Provider API divergence note (see README): AWS S2S VPN always provisions
# TWO tunnels per connection (managed HA). Azure VPN Gateway provisions
# one or two depending on active-active mode; GCP HA VPN provisions two
# interfaces on one gateway; OCI IPSec connections also carry two tunnels.
# Tunnel counts and BGP session shapes differ — on-prem device configs are
# not portable across clouds.
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
    module_source = "modules/aws/hybrid-connectivity/vpn"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  use_vgw = var.attachment_type == "vgw"

  static_routes = merge([
    for conn_key, conn in var.vpn_connections : {
      for cidr in conn.static_routes :
      "${conn_key}/${cidr}" => { connection_key = conn_key, cidr = cidr }
    } if local.use_vgw && conn.static_routes_only
  ]...)
}

# ---------------------------------------------------------------------------
# Virtual private gateway (vgw mode)
# ---------------------------------------------------------------------------
resource "aws_vpn_gateway" "this" {
  count = local.use_vgw ? 1 : 0

  vpc_id          = var.vpc_id
  amazon_side_asn = var.amazon_side_asn

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-vgw-${var.name_suffix}"
  })
}

resource "aws_vpn_gateway_route_propagation" "this" {
  for_each = local.use_vgw ? toset(var.enable_route_propagation) : toset([])

  vpn_gateway_id = aws_vpn_gateway.this[0].id
  route_table_id = each.value
}

# ---------------------------------------------------------------------------
# Customer gateways
# ---------------------------------------------------------------------------
resource "aws_customer_gateway" "this" {
  for_each = var.customer_gateways

  bgp_asn     = each.value.bgp_asn
  ip_address  = each.value.ip_address
  device_name = each.value.device_name
  type        = "ipsec.1"

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-cgw-${each.key}-${var.name_suffix}"
  })
}

# ---------------------------------------------------------------------------
# VPN connections (two tunnels each, AWS-managed HA)
# ---------------------------------------------------------------------------
resource "aws_vpn_connection" "this" {
  for_each = var.vpn_connections

  customer_gateway_id = aws_customer_gateway.this[each.value.customer_gateway_key].id
  type                = "ipsec.1"
  static_routes_only  = each.value.static_routes_only

  vpn_gateway_id     = local.use_vgw ? aws_vpn_gateway.this[0].id : null
  transit_gateway_id = local.use_vgw ? null : var.transit_gateway_id

  tunnel1_inside_cidr   = each.value.tunnel1_inside_cidr
  tunnel2_inside_cidr   = each.value.tunnel2_inside_cidr
  tunnel1_preshared_key = each.value.tunnel1_preshared_key
  tunnel2_preshared_key = each.value.tunnel2_preshared_key

  tunnel1_ike_versions = each.value.tunnel_ike_versions
  tunnel2_ike_versions = each.value.tunnel_ike_versions

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-vpn-${each.key}-${var.name_suffix}"
  })
}

resource "aws_vpn_connection_route" "this" {
  for_each = local.static_routes

  vpn_connection_id      = aws_vpn_connection.this[each.value.connection_key].id
  destination_cidr_block = each.value.cidr
}
