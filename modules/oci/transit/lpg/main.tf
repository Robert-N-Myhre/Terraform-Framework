# ===========================================================================
# OCI Transit — Local Peering Gateways (same-region VCN peering)
#
# Independently invocable: this module sources no other module in this
# framework. VCN OCIDs are plain inputs; subnet route rules pointing at
# the LPG OCIDs are the consumer's responsibility.
#
# Provider API divergence note (see README): OCI peers VCNs through
# GATEWAY OBJECTS (one LPG per side) connected by setting peer_id on one
# side — vs AWS's single handshake resource, Azure's two one-way
# peerings, and GCP's symmetric config. LPGs are same-region only;
# cross-region uses RPCs on a DRG (oci/transit/drg).
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
    module_source = "modules/oci/transit/lpg"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

resource "oci_core_local_peering_gateway" "a" {
  for_each = var.peerings

  compartment_id = var.compartment_id
  vcn_id         = each.value.vcn_a_id
  display_name   = "${local.name_base}-lpg-${each.key}-a-${var.name_suffix}"
  route_table_id = each.value.lpg_a_route_table_id

  # Setting peer_id on side A establishes the connection; side B accepts
  # implicitly and must NOT also set peer_id.
  peer_id = oci_core_local_peering_gateway.b[each.key].id

  freeform_tags = local.all_tags
}

resource "oci_core_local_peering_gateway" "b" {
  for_each = var.peerings

  compartment_id = var.compartment_id
  vcn_id         = each.value.vcn_b_id
  display_name   = "${local.name_base}-lpg-${each.key}-b-${var.name_suffix}"
  route_table_id = each.value.lpg_b_route_table_id

  freeform_tags = local.all_tags
}
