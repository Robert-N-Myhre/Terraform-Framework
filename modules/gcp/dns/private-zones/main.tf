# ===========================================================================
# GCP DNS — Private Managed Zones (plain, forwarding, or peering)
#
# Independently invocable: this module sources no other module in this
# framework. VPC self-links are plain inputs.
#
# Provider API divergence note (see README): GCP attaches resolving VPCs as
# a LIST on the zone (private_visibility_config) — Azure uses standalone
# link resources, AWS uses inline vpc blocks, OCI uses resolver views.
# GCP folds "forwarding" into the zone type itself (forwarding zones),
# where AWS/Azure use separate resolver-rule resources.
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
    module_source = "modules-gcp-dns-private-zones" # label values disallow "/"
  }
  all_tags = merge({ for k, v in var.additional_tags : lower(k) => lower(v) }, local.mandatory_tags)

  records = merge([
    for z_key, z in var.private_zones : {
      for r_key, r in z.records :
      "${z_key}/${r_key}" => merge(r, { zone_key = z_key })
    }
  ]...)
}

resource "google_dns_managed_zone" "this" {
  for_each = var.private_zones

  project     = var.project_id
  name        = "${local.name_base}-zone-${each.key}-${var.name_suffix}"
  dns_name    = each.value.domain_name
  description = each.value.description
  visibility  = "private"

  private_visibility_config {
    dynamic "networks" {
      for_each = toset(each.value.network_self_links)
      content {
        network_url = networks.value
      }
    }
  }

  dynamic "forwarding_config" {
    for_each = length(each.value.forwarding_targets) > 0 ? [1] : []
    content {
      dynamic "target_name_servers" {
        for_each = each.value.forwarding_targets
        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          forwarding_path = target_name_servers.value.forwarding_path
        }
      }
    }
  }

  dynamic "peering_config" {
    for_each = each.value.peering_network_self_link != null ? [1] : []
    content {
      target_network {
        network_url = each.value.peering_network_self_link
      }
    }
  }

  labels = local.all_tags
}

resource "google_dns_record_set" "this" {
  for_each = local.records

  project      = var.project_id
  managed_zone = google_dns_managed_zone.this[each.value.zone_key].name

  # Apex records use the zone domain; others prepend the relative name.
  name = (
    each.value.name == "" || each.value.name == "@"
    ? google_dns_managed_zone.this[each.value.zone_key].dns_name
    : "${each.value.name}.${google_dns_managed_zone.this[each.value.zone_key].dns_name}"
  )

  type    = each.value.type
  ttl     = each.value.ttl
  rrdatas = each.value.rrdatas
}
