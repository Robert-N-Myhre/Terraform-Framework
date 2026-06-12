# ===========================================================================
# GCP Hybrid Connectivity — HA Cloud VPN
#
# Independently invocable: this module sources no other module in this
# framework. The network self-link is a plain input.
#
# Provider API divergence note (see README): GCP HA VPN is ONE gateway with
# TWO interfaces; tunnels bind to a gateway interface and a Cloud Router
# BGP session — routing is always dynamic (no static-route VPN in HA VPN).
# AWS gives two tunnels per connection; Azure tunnel count follows
# active-active; OCI has two tunnels per IPSec connection with optional
# static routing. Classic (target) VPN gateways are deprecated and not
# implemented here.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-gcp-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = lower(var.environment)
    owner         = lower(var.owner)
    cost_center   = lower(var.cost_center)
    managed_by    = "terraform"
    module_source = "modules-gcp-hybrid-connectivity-cloud-vpn" # label values disallow "/"
  }
  all_tags = merge({ for k, v in var.additional_tags : lower(k) => lower(v) }, local.mandatory_tags)
}

# ---------------------------------------------------------------------------
# HA VPN gateway (two interfaces) + Cloud Router
# ---------------------------------------------------------------------------
resource "google_compute_ha_vpn_gateway" "this" {
  project = var.project_id
  name    = "${local.name_base}-havpngw-${var.name_suffix}"
  region  = var.region
  network = var.network_self_link
}

resource "google_compute_router" "this" {
  project = var.project_id
  name    = "${local.name_base}-router-vpn-${var.name_suffix}"
  region  = var.region
  network = var.network_self_link

  bgp {
    asn = var.router_asn
  }
}

# ---------------------------------------------------------------------------
# External (peer) gateways
# ---------------------------------------------------------------------------
resource "google_compute_external_vpn_gateway" "this" {
  for_each = var.peer_gateways

  project = var.project_id
  name    = "${local.name_base}-extgw-${each.key}-${var.name_suffix}"

  redundancy_type = length(each.value.interfaces) == 2 ? "TWO_IPS_REDUNDANCY" : "SINGLE_IP_INTERNALLY_REDUNDANT"

  dynamic "interface" {
    for_each = { for idx, ip in each.value.interfaces : idx => ip }
    content {
      id         = interface.key
      ip_address = interface.value
    }
  }

  labels = local.all_tags
}

# ---------------------------------------------------------------------------
# Tunnels + BGP sessions
# ---------------------------------------------------------------------------
resource "google_compute_vpn_tunnel" "this" {
  for_each = var.tunnels

  project = var.project_id
  name    = "${local.name_base}-tunnel-${each.key}-${var.name_suffix}"
  region  = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.this.id
  vpn_gateway_interface = each.value.vpn_gateway_interface

  peer_external_gateway           = google_compute_external_vpn_gateway.this[each.value.peer_gateway_key].id
  peer_external_gateway_interface = each.value.peer_external_gateway_interface

  shared_secret = each.value.shared_secret
  ike_version   = each.value.ike_version
  router        = google_compute_router.this.id

  labels = local.all_tags
}

resource "google_compute_router_interface" "this" {
  for_each = var.tunnels

  project = var.project_id
  name    = "${local.name_base}-rif-${each.key}-${var.name_suffix}"
  region  = var.region
  router  = google_compute_router.this.name

  ip_range   = each.value.bgp_session_range
  vpn_tunnel = google_compute_vpn_tunnel.this[each.key].name
}

resource "google_compute_router_peer" "this" {
  for_each = var.tunnels

  project = var.project_id
  name    = "${local.name_base}-peer-${each.key}-${var.name_suffix}"
  region  = var.region
  router  = google_compute_router.this.name

  interface                 = google_compute_router_interface.this[each.key].name
  peer_ip_address           = each.value.peer_bgp_ip
  peer_asn                  = each.value.peer_asn
  advertised_route_priority = each.value.advertised_route_priority
}
