# ===========================================================================
# AWS Hybrid Connectivity — Direct Connect
#
# Independently invocable: this module sources no other module in this
# framework. Existing connection/VGW/TGW IDs are plain inputs.
#
# NOTE: the physical cross-connect (LOA-CFA, patch panel work) is a manual
# or partner step Terraform cannot perform. A newly ordered dedicated
# connection stays in 'ordering/pending' until that completes.
#
# Provider API divergence note (see README): DX gateway sits between VIFs
# and VGW/TGW. Azure ExpressRoute uses circuit + peerings + gateway
# connection; GCP Interconnect uses attachments (VLAN) bound to Cloud
# Routers; OCI FastConnect uses virtual circuits on a DRG. BGP session
# provisioning and prefix-filtering semantics differ per cloud.
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
    module_source = "modules/aws/hybrid-connectivity/direct-connect"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  connection_id = var.create_connection ? aws_dx_connection.this[0].id : var.existing_connection_id
}

# ---------------------------------------------------------------------------
# Dedicated connection (optional — physical provisioning is out-of-band)
# ---------------------------------------------------------------------------
resource "aws_dx_connection" "this" {
  count = var.create_connection ? 1 : 0

  name      = "${local.name_base}-dxcon-${var.name_suffix}"
  bandwidth = var.connection_bandwidth
  location  = var.connection_location

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Direct Connect gateway
# ---------------------------------------------------------------------------
resource "aws_dx_gateway" "this" {
  name            = coalesce(var.dx_gateway_name, "${local.name_base}-dxgw-${var.name_suffix}")
  amazon_side_asn = var.dx_gateway_asn
}

# ---------------------------------------------------------------------------
# Private virtual interfaces
# ---------------------------------------------------------------------------
resource "aws_dx_private_virtual_interface" "this" {
  for_each = var.private_vifs

  connection_id = local.connection_id
  dx_gateway_id = aws_dx_gateway.this.id

  name             = "${local.name_base}-dxvif-${each.key}-${var.name_suffix}"
  vlan             = each.value.vlan
  address_family   = "ipv4"
  bgp_asn          = each.value.bgp_asn
  bgp_auth_key     = each.value.bgp_auth_key
  amazon_address   = each.value.amazon_address
  customer_address = each.value.customer_address
  mtu              = each.value.mtu

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Gateway associations (VGW or TGW)
# ---------------------------------------------------------------------------
resource "aws_dx_gateway_association" "this" {
  for_each = var.gateway_associations

  dx_gateway_id         = aws_dx_gateway.this.id
  associated_gateway_id = each.value.gateway_id

  allowed_prefixes = length(each.value.allowed_prefixes) > 0 ? each.value.allowed_prefixes : null
}
