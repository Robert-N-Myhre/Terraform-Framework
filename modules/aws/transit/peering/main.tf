# ===========================================================================
# AWS Transit — VPC Peering
#
# Independently invocable: this module sources no other module in this
# framework. VPC and route table IDs are plain inputs.
#
# Provider API divergence note (see README): AWS peering is a two-sided
# requester/accepter handshake and is NON-TRANSITIVE. Azure VNet peering is
# two one-way peering resources; GCP VPC peering is symmetric per-network
# config; OCI uses Local Peering Gateways (LPGs) with explicit route rules.
# None of these clouds provide transitive routing via simple peering — use
# the transit-gateway / vwan / ncc / drg modules for hub-and-spoke.
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
    module_source = "modules/aws/transit/peering"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  requester_routes = merge([
    for p_key, p in var.peerings : {
      for rt_id in p.requester_route_table_ids :
      "${p_key}/${rt_id}" => {
        peering_key      = p_key
        route_table_id   = rt_id
        destination_cidr = p.requester_destination_cidr
      }
    }
  ]...)

  accepter_routes = merge([
    for p_key, p in var.peerings : {
      for rt_id in p.accepter_route_table_ids :
      "${p_key}/${rt_id}" => {
        peering_key      = p_key
        route_table_id   = rt_id
        destination_cidr = p.accepter_destination_cidr
      }
    }
  ]...)

  # Cross-region peering cannot auto-accept on the requester resource.
  cross_region_peerings = { for k, p in var.peerings : k => p if p.peer_region != null }
}

resource "aws_vpc_peering_connection" "this" {
  for_each = var.peerings

  vpc_id      = each.value.requester_vpc_id
  peer_vpc_id = each.value.accepter_vpc_id
  peer_region = each.value.peer_region
  auto_accept = each.value.peer_region == null ? each.value.auto_accept : false

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-pcx-${each.key}-${var.name_suffix}"
  })
}

# Same-account cross-region acceptance. Cross-account acceptance requires a
# second provider alias and belongs in the consumer root module.
resource "aws_vpc_peering_connection_accepter" "cross_region" {
  for_each = local.cross_region_peerings

  vpc_peering_connection_id = aws_vpc_peering_connection.this[each.key].id
  auto_accept               = true

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-pcx-accept-${each.key}-${var.name_suffix}"
  })
}

resource "aws_vpc_peering_connection_options" "requester" {
  for_each = { for k, p in var.peerings : k => p if p.peer_region == null }

  vpc_peering_connection_id = aws_vpc_peering_connection.this[each.key].id

  requester {
    allow_remote_vpc_dns_resolution = each.value.allow_requester_dns_resolution
  }

  accepter {
    allow_remote_vpc_dns_resolution = each.value.allow_accepter_dns_resolution
  }

  depends_on = [aws_vpc_peering_connection.this]
}

resource "aws_route" "requester" {
  for_each = local.requester_routes

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = each.value.destination_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this[each.value.peering_key].id
}

resource "aws_route" "accepter" {
  for_each = local.accepter_routes

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = each.value.destination_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this[each.value.peering_key].id

  depends_on = [aws_vpc_peering_connection_accepter.cross_region]
}
