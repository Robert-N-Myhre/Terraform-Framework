# ===========================================================================
# OCI Hybrid Connectivity — FastConnect (virtual circuits)
#
# Independently invocable: this module sources no other module in this
# framework. The DRG (for PRIVATE circuits) and any cross-connects are
# supplied by OCID.
#
# NOTE: the physical layer is out-of-band — for the partner model the
# provider completes their side after circuit creation; for the dedicated
# model the cross-connect (LOA, patch) must exist first.
#
# Provider API divergence note (see README): OCI virtual circuits carry
# the BGP session directly (customer/oracle peering IPs on the circuit) —
# vs AWS (BGP on the VIF), Azure (dual BGP on the circuit peering), GCP
# (BGP on the Cloud Router). PUBLIC circuit type (advertising your public
# prefixes over FastConnect) has an AWS analogue (public VIF) but none in
# GCP.
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
    module_source = "modules/oci/hybrid-connectivity/fastconnect"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

resource "oci_core_virtual_circuit" "this" {
  for_each = var.virtual_circuits

  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-vc-${each.key}-${var.name_suffix}"
  type           = each.value.circuit_type

  bandwidth_shape_name = each.value.bandwidth_shape_name
  customer_asn         = each.value.customer_asn

  # PRIVATE circuits terminate on the DRG; PUBLIC circuits advertise prefixes.
  gateway_id = each.value.circuit_type == "PRIVATE" ? var.drg_id : null

  # Partner model
  provider_service_id = each.value.provider_service_id

  # Dedicated model
  dynamic "cross_connect_mappings" {
    for_each = each.value.cross_connect_mappings
    content {
      cross_connect_or_cross_connect_group_id = cross_connect_mappings.value.cross_connect_or_cross_connect_group_id
      vlan                                    = cross_connect_mappings.value.vlan
      customer_bgp_peering_ip                 = cross_connect_mappings.value.customer_bgp_peering_ip
      oracle_bgp_peering_ip                   = cross_connect_mappings.value.oracle_bgp_peering_ip
    }
  }

  dynamic "public_prefixes" {
    for_each = each.value.circuit_type == "PUBLIC" ? toset(each.value.public_prefixes) : toset([])
    content {
      cidr_block = public_prefixes.value
    }
  }

  freeform_tags = local.all_tags
}
