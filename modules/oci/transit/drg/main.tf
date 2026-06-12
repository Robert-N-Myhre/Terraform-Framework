# ===========================================================================
# OCI Transit — Dynamic Routing Gateway (hub-and-spoke)
#
# Independently invocable: this module sources no other module in this
# framework. VCN OCIDs are plain inputs. Return routes inside each VCN
# (pointing at the DRG) belong to the consumer root or a separately
# invoked core-network configuration.
#
# Provider API divergence note (see README): the upgraded DRG is OCI's
# transit hub — analogue of AWS TGW (closest match: both have custom
# route tables per attachment), Azure vWAN, GCP NCC. The DRG also
# terminates IPSec VPN and FastConnect (hybrid domain modules attach to a
# DRG by OCID) and peers cross-region via RPCs.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-oci-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/oci/transit/drg"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

resource "oci_core_drg" "this" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-drg-${var.name_suffix}"

  freeform_tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Custom DRG route tables
# ---------------------------------------------------------------------------
resource "oci_core_drg_route_table" "this" {
  for_each = var.drg_route_tables

  drg_id       = oci_core_drg.this.id
  display_name = "${local.name_base}-drgrt-${each.value}-${var.name_suffix}"

  freeform_tags = local.all_tags
}

# ---------------------------------------------------------------------------
# VCN attachments
# ---------------------------------------------------------------------------
resource "oci_core_drg_attachment" "this" {
  for_each = var.vcn_attachments

  drg_id       = oci_core_drg.this.id
  display_name = "${local.name_base}-drgatt-${each.key}-${var.name_suffix}"

  drg_route_table_id = (
    each.value.drg_route_table_key != null
    ? oci_core_drg_route_table.this[each.value.drg_route_table_key].id
    : null
  )

  network_details {
    type           = "VCN"
    id             = each.value.vcn_id
    route_table_id = each.value.vcn_route_table_id
  }

  freeform_tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Static DRG routes
# ---------------------------------------------------------------------------
resource "oci_core_drg_route_table_route_rule" "this" {
  for_each = var.static_routes

  drg_route_table_id         = oci_core_drg_route_table.this[each.value.drg_route_table_key].id
  destination                = each.value.destination_cidr
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = oci_core_drg_attachment.this[each.value.next_hop_attachment_key].id
}

# ---------------------------------------------------------------------------
# Remote peering connections (cross-region)
# ---------------------------------------------------------------------------
resource "oci_core_remote_peering_connection" "this" {
  for_each = var.remote_peering_connections

  compartment_id   = var.compartment_id
  drg_id           = oci_core_drg.this.id
  display_name     = "${local.name_base}-rpc-${each.key}-${var.name_suffix}"
  peer_id          = each.value.peer_rpc_id
  peer_region_name = each.value.peer_region_name

  freeform_tags = local.all_tags
}
