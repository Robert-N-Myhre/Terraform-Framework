# ===========================================================================
# OCI DNS — Private Views and Zones
#
# Independently invocable: this module sources no other module in this
# framework. Attaching views to VCN resolvers happens by OCID in the
# consumer root or via the independently invoked oci/dns/resolver module.
#
# Provider API divergence note (see README): OCI scopes private DNS through
# VIEWS attached to VCN resolvers — a third model distinct from AWS
# (zone-VPC associations), Azure (VNet links), and GCP (network lists on
# the zone). The same zone can appear in multiple views with different
# answers (split-horizon by view).
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
    module_source = "modules/oci/dns/private-views"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  zones = merge([
    for v_key, v in var.views : {
      for z_key, z in v.zones :
      "${v_key}/${z_key}" => merge(z, { view_key = v_key })
    }
  ]...)

  records = merge([
    for vz_key, z in local.zones : {
      for r_key, r in z.records :
      "${vz_key}/${r_key}" => merge(r, { zone_key = vz_key })
    }
  ]...)
}

resource "oci_dns_view" "this" {
  for_each = var.views

  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-dnsview-${each.key}-${var.name_suffix}"
  scope          = "PRIVATE"

  freeform_tags = local.all_tags
}

resource "oci_dns_zone" "this" {
  for_each = local.zones

  compartment_id = var.compartment_id
  name           = each.value.domain_name
  zone_type      = "PRIMARY"
  scope          = "PRIVATE"
  view_id        = oci_dns_view.this[each.value.view_key].id

  freeform_tags = local.all_tags
}

resource "oci_dns_rrset" "this" {
  for_each = local.records

  zone_name_or_id = oci_dns_zone.this[each.value.zone_key].id
  domain = (
    each.value.name == "" || each.value.name == "@"
    ? oci_dns_zone.this[each.value.zone_key].name
    : "${each.value.name}.${oci_dns_zone.this[each.value.zone_key].name}"
  )
  rtype   = each.value.type
  scope   = "PRIVATE"
  view_id = oci_dns_view.this[split("/", each.value.zone_key)[0]].id

  dynamic "items" {
    for_each = each.value.rdata
    content {
      domain = (
        each.value.name == "" || each.value.name == "@"
        ? oci_dns_zone.this[each.value.zone_key].name
        : "${each.value.name}.${oci_dns_zone.this[each.value.zone_key].name}"
      )
      rtype = each.value.type
      ttl   = each.value.ttl
      rdata = items.value
    }
  }
}
