# ===========================================================================
# GCP Transit — Network Connectivity Center (hub-and-spoke)
#
# Independently invocable: this module sources no other module in this
# framework. Spoke VPC self-links and tunnel/attachment URIs are plain
# inputs.
#
# Provider API divergence note (see README): NCC is GCP's managed transit
# hub — analogue of AWS TGW, Azure vWAN, OCI DRG — but WITHOUT per-spoke
# route tables: all VPC spokes get full-mesh subnet reachability, with
# exclude_export_ranges as the only segmentation control. TGW/vWAN/DRG
# segmentation designs do not port to NCC directly.
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
    module_source = "modules-gcp-transit-ncc" # label values disallow "/"
  }
  all_tags = merge({ for k, v in var.additional_tags : lower(k) => lower(v) }, local.mandatory_tags)
}

resource "google_network_connectivity_hub" "this" {
  project     = var.project_id
  name        = "${local.name_base}-ncchub-${var.name_suffix}"
  description = var.hub_description

  labels = local.all_tags
}

# ---------------------------------------------------------------------------
# VPC-network spokes (global)
# ---------------------------------------------------------------------------
resource "google_network_connectivity_spoke" "vpc" {
  for_each = var.vpc_spokes

  project  = var.project_id
  name     = "${local.name_base}-nccspoke-${each.key}-${var.name_suffix}"
  location = "global"
  hub      = google_network_connectivity_hub.this.id

  linked_vpc_network {
    uri                   = each.value.vpc_self_link
    exclude_export_ranges = each.value.exclude_export_ranges
  }

  labels = local.all_tags
}

# ---------------------------------------------------------------------------
# Hybrid spokes (regional: HA VPN tunnels or Interconnect attachments)
# ---------------------------------------------------------------------------
resource "google_network_connectivity_spoke" "hybrid" {
  for_each = var.hybrid_spokes

  project  = var.project_id
  name     = "${local.name_base}-nccspoke-${each.key}-${var.name_suffix}"
  location = each.value.location
  hub      = google_network_connectivity_hub.this.id

  dynamic "linked_vpn_tunnels" {
    for_each = each.value.type == "vpn" ? [1] : []
    content {
      uris                       = each.value.uris
      site_to_site_data_transfer = each.value.site_to_site_data_transfer
    }
  }

  dynamic "linked_interconnect_attachments" {
    for_each = each.value.type == "interconnect" ? [1] : []
    content {
      uris                       = each.value.uris
      site_to_site_data_transfer = each.value.site_to_site_data_transfer
    }
  }

  labels = local.all_tags
}
