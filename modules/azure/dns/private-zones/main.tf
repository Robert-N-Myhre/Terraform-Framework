# ===========================================================================
# Azure DNS — Private DNS Zones
#
# Independently invocable: this module sources no other module in this
# framework. VNet IDs for links are plain inputs.
#
# Provider API divergence note (see README): Azure links VNets to zones via
# standalone azurerm_private_dns_zone_virtual_network_link resources —
# unlike AWS (inline vpc blocks on the zone) and GCP (network list on the
# zone). Azure zone names are global within the resource group; the
# privatelink.* zones used for Private Endpoints follow this same model.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-azure-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/azure/dns/private-zones"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  vnet_links = merge([
    for z_key, z in var.private_zones : {
      for l_key, l in z.vnet_links :
      "${z_key}/${l_key}" => merge(l, { zone_key = z_key, link_key = l_key })
    }
  ]...)

  a_records = merge([
    for z_key, z in var.private_zones : {
      for r_key, r in z.a_records :
      "${z_key}/${r_key}" => merge(r, { zone_key = z_key })
    }
  ]...)

  cname_records = merge([
    for z_key, z in var.private_zones : {
      for r_key, r in z.cname_records :
      "${z_key}/${r_key}" => merge(r, { zone_key = z_key })
    }
  ]...)

  txt_records = merge([
    for z_key, z in var.private_zones : {
      for r_key, r in z.txt_records :
      "${z_key}/${r_key}" => merge(r, { zone_key = z_key })
    }
  ]...)
}

resource "azurerm_private_dns_zone" "this" {
  for_each = var.private_zones

  name                = each.value.domain_name
  resource_group_name = var.resource_group_name

  tags = local.all_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.vnet_links

  name                  = "${local.name_base}-dnslink-${replace(each.key, "/", "-")}-${var.name_suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value.zone_key].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = each.value.registration_enabled

  tags = local.all_tags
}

resource "azurerm_private_dns_a_record" "this" {
  for_each = local.a_records

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.this[each.value.zone_key].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = local.all_tags
}

resource "azurerm_private_dns_cname_record" "this" {
  for_each = local.cname_records

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.this[each.value.zone_key].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record

  tags = local.all_tags
}

resource "azurerm_private_dns_txt_record" "this" {
  for_each = local.txt_records

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.this[each.value.zone_key].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }

  tags = local.all_tags
}
