# ===========================================================================
# GCP Hybrid Connectivity — Cloud Interconnect (VLAN attachments)
#
# Independently invocable: this module sources no other module in this
# framework. The network self-link and (for DEDICATED) the physical
# interconnect self-link are plain inputs.
#
# NOTE: the physical Dedicated Interconnect port is ordered via the
# console/API out-of-band (LOA-CFA, cross-connect). For PARTNER
# attachments, hand the pairing_key output to the service provider.
#
# Provider API divergence note (see README): GCP attachments bind to a
# Cloud Router — the BGP speaker is the ROUTER, not the attachment. AWS
# DX puts BGP on the VIF; Azure ExpressRoute on the circuit peering; OCI
# FastConnect on the virtual circuit. Partner attachments delegate BGP
# session setup to the partner entirely.
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
    module_source = "modules-gcp-hybrid-connectivity-cloud-interconnect" # label values disallow "/"
  }
  all_tags = merge({ for k, v in var.additional_tags : lower(k) => lower(v) }, local.mandatory_tags)

  dedicated_with_bgp = {
    for k, a in var.attachments : k => a
    if a.type == "DEDICATED" && a.bgp != null
  }
}

# ---------------------------------------------------------------------------
# Cloud Router
# ---------------------------------------------------------------------------
resource "google_compute_router" "this" {
  project = var.project_id
  name    = "${local.name_base}-router-ic-${var.name_suffix}"
  region  = var.region
  network = var.network_self_link

  bgp {
    asn = var.router_asn
  }
}

# ---------------------------------------------------------------------------
# VLAN attachments
# ---------------------------------------------------------------------------
resource "google_compute_interconnect_attachment" "this" {
  for_each = var.attachments

  project = var.project_id
  name    = "${local.name_base}-icatt-${each.key}-${var.name_suffix}"
  region  = var.region
  router  = google_compute_router.this.id

  type          = each.value.type
  admin_enabled = each.value.admin_enabled

  # PARTNER-only arguments
  edge_availability_domain = each.value.type == "PARTNER" ? each.value.edge_availability_domain : null

  # DEDICATED-only arguments
  interconnect      = each.value.type == "DEDICATED" ? each.value.interconnect_self_link : null
  vlan_tag8021q     = each.value.type == "DEDICATED" ? each.value.vlan_tag : null
  bandwidth         = each.value.type == "DEDICATED" ? each.value.bandwidth : null
  candidate_subnets = each.value.type == "DEDICATED" && length(each.value.candidate_subnets) > 0 ? each.value.candidate_subnets : null

  labels = local.all_tags
}

# ---------------------------------------------------------------------------
# BGP sessions for DEDICATED attachments
# (PARTNER sessions are configured by the service provider.)
# ---------------------------------------------------------------------------
resource "google_compute_router_interface" "this" {
  for_each = local.dedicated_with_bgp

  project = var.project_id
  name    = "${local.name_base}-rif-ic-${each.key}-${var.name_suffix}"
  region  = var.region
  router  = google_compute_router.this.name

  ip_range                = each.value.bgp.session_range
  interconnect_attachment = google_compute_interconnect_attachment.this[each.key].name
}

resource "google_compute_router_peer" "this" {
  for_each = local.dedicated_with_bgp

  project = var.project_id
  name    = "${local.name_base}-peer-ic-${each.key}-${var.name_suffix}"
  region  = var.region
  router  = google_compute_router.this.name

  interface       = google_compute_router_interface.this[each.key].name
  peer_ip_address = each.value.bgp.peer_ip
  peer_asn        = each.value.bgp.peer_asn
}
