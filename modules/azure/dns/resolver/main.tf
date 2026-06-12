# ===========================================================================
# Azure DNS — DNS Private Resolver
#
# Independently invocable: this module sources no other module in this
# framework. VNet and delegated-subnet IDs are plain inputs.
#
# Provider API divergence note (see README): Azure's resolver mirrors AWS
# Route 53 Resolver (inbound/outbound endpoints) but groups forwarding
# rules into RULESETS that link to VNets — AWS associates individual rules
# with VPCs. Each endpoint needs a dedicated subnet delegated to
# Microsoft.Network/dnsResolvers; rule domains require a trailing dot.
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
    module_source = "modules/azure/dns/resolver"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  ruleset_rules = merge([
    for rs_key, rs in var.forwarding_rulesets : {
      for r_key, r in rs.rules :
      "${rs_key}/${r_key}" => merge(r, { ruleset_key = rs_key, rule_key = r_key })
    }
  ]...)

  ruleset_vnet_links = merge([
    for rs_key, rs in var.forwarding_rulesets : {
      for idx, vnet_id in rs.vnet_link_ids :
      "${rs_key}/${idx}" => { ruleset_key = rs_key, vnet_id = vnet_id, idx = idx }
    }
  ]...)
}

resource "azurerm_private_dns_resolver" "this" {
  name                = "${local.name_base}-dnspr-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_network_id  = var.vnet_id

  tags = local.all_tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  for_each = var.inbound_endpoints

  name                    = "${local.name_base}-dnsprin-${each.key}-${var.name_suffix}"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = each.value.subnet_id
  }

  tags = local.all_tags
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "this" {
  for_each = var.outbound_endpoints

  name                    = "${local.name_base}-dnsprout-${each.key}-${var.name_suffix}"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.location
  subnet_id               = each.value.subnet_id

  tags = local.all_tags
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "this" {
  for_each = var.forwarding_rulesets

  name                = "${local.name_base}-dnsfrs-${each.key}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  private_dns_resolver_outbound_endpoint_ids = [
    for ep_key in each.value.outbound_endpoint_keys :
    azurerm_private_dns_resolver_outbound_endpoint.this[ep_key].id
  ]

  tags = local.all_tags
}

resource "azurerm_private_dns_resolver_forwarding_rule" "this" {
  for_each = local.ruleset_rules

  name                      = each.value.rule_key
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.this[each.value.ruleset_key].id
  domain_name               = each.value.domain_name
  enabled                   = each.value.enabled

  dynamic "target_dns_servers" {
    for_each = each.value.target_dns_servers
    content {
      ip_address = target_dns_servers.value.ip_address
      port       = target_dns_servers.value.port
    }
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "this" {
  for_each = local.ruleset_vnet_links

  name                      = "${local.name_base}-dnsfrslink-${replace(each.key, "/", "-")}-${var.name_suffix}"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.this[each.value.ruleset_key].id
  virtual_network_id        = each.value.vnet_id
}
