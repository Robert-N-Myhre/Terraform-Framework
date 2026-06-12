# ===========================================================================
# OCI Hybrid Connectivity — Site-to-Site IPSec VPN
#
# Independently invocable: this module sources no other module in this
# framework. The DRG is supplied by OCID.
#
# Provider API divergence note (see README): OCI provisions TWO tunnels
# per IPSec connection (like AWS); per-tunnel configuration (BGP, PSK,
# IKE version) happens through the tunnel-MANAGEMENT resource, which
# adopts the auto-created tunnels rather than creating them — a pattern
# unique to OCI among the four clouds.
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
    module_source = "modules/oci/hybrid-connectivity/ipsec-vpn"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  tunnel_configs = merge([
    for conn_key, conn in var.ipsec_connections : {
      for t_key, t in conn.tunnels :
      "${conn_key}/${t_key}" => merge(t, { connection_key = conn_key })
    }
  ]...)
}

# ---------------------------------------------------------------------------
# CPE (on-premises device objects)
# ---------------------------------------------------------------------------
resource "oci_core_cpe" "this" {
  for_each = var.customer_premises_equipment

  compartment_id      = var.compartment_id
  display_name        = "${local.name_base}-cpe-${each.key}-${var.name_suffix}"
  ip_address          = each.value.ip_address
  cpe_device_shape_id = each.value.cpe_device_shape_id

  freeform_tags = local.all_tags
}

# ---------------------------------------------------------------------------
# IPSec connections (two tunnels each, auto-provisioned)
# ---------------------------------------------------------------------------
resource "oci_core_ipsec" "this" {
  for_each = var.ipsec_connections

  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-ipsec-${each.key}-${var.name_suffix}"
  cpe_id         = oci_core_cpe.this[each.value.cpe_key].id
  drg_id         = var.drg_id

  # OCI requires at least one static route string even for BGP connections;
  # convention: pass the on-prem supernet, or 0.0.0.0/0 placeholder for BGP.
  static_routes = length(each.value.static_routes) > 0 ? each.value.static_routes : ["0.0.0.0/0"]

  freeform_tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Tunnel management (adopts the auto-created tunnels)
# ---------------------------------------------------------------------------
data "oci_core_ipsec_connection_tunnels" "this" {
  for_each = var.ipsec_connections

  ipsec_id = oci_core_ipsec.this[each.key].id
}

resource "oci_core_ipsec_connection_tunnel_management" "this" {
  for_each = local.tunnel_configs

  ipsec_id  = oci_core_ipsec.this[each.value.connection_key].id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.this[each.value.connection_key].ip_sec_connection_tunnels[each.value.tunnel_index - 1].id

  display_name  = "${local.name_base}-tunnel-${replace(each.key, "/", "-")}-${var.name_suffix}"
  routing       = each.value.routing_type
  shared_secret = each.value.shared_secret
  ike_version   = each.value.ike_version

  dynamic "bgp_session_info" {
    for_each = each.value.routing_type == "BGP" ? [1] : []
    content {
      customer_bgp_asn      = each.value.customer_bgp_asn
      oracle_interface_ip   = each.value.oracle_interface_ip
      customer_interface_ip = each.value.customer_interface_ip
    }
  }
}
