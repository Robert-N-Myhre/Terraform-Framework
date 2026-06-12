# ===========================================================================
# Azure Firewall Domain — Azure Firewall (managed appliance)
#
# Independently invocable: this module sources no other module in this
# framework. The AzureFirewallSubnet ID is a plain input.
#
# Provider API divergence note (see README): Azure Firewall is a routed hub
# appliance — traffic reaches it via UDRs (next_hop VirtualAppliance to the
# firewall private IP). AWS Network Firewall instead inserts VPC endpoints
# you route to; OCI Network Firewall is a Palo Alto-backed appliance; GCP
# Cloud NGFW attaches policies rather than routing to an appliance. Rules
# here use the firewall-policy model (classic inline rules are deprecated).
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
    module_source = "modules/azure/firewall/azure-firewall"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

# ---------------------------------------------------------------------------
# Public IP (Standard SKU required by Azure Firewall)
# ---------------------------------------------------------------------------
resource "azurerm_public_ip" "this" {
  name                = "${local.name_base}-pip-fw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = length(var.zones) > 0 ? var.zones : null

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Firewall policy + rule collection group
# ---------------------------------------------------------------------------
resource "azurerm_firewall_policy" "this" {
  name                     = "${local.name_base}-fwpolicy-${var.name_suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.sku_tier
  threat_intelligence_mode = var.threat_intelligence_mode

  dynamic "dns" {
    for_each = var.dns_proxy_enabled ? [1] : []
    content {
      proxy_enabled = true
      servers       = length(var.dns_servers) > 0 ? var.dns_servers : null
    }
  }

  tags = local.all_tags
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  name               = "${local.name_base}-fwrcg-${var.name_suffix}"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 100

  dynamic "network_rule_collection" {
    for_each = var.network_rule_collections
    content {
      name     = network_rule_collection.key
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.key
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_fqdns     = rule.value.destination_fqdns
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }

  dynamic "application_rule_collection" {
    for_each = var.application_rule_collections
    content {
      name     = application_rule_collection.key
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name              = rule.key
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }

  dynamic "nat_rule_collection" {
    for_each = var.nat_rule_collections
    content {
      name     = nat_rule_collection.key
      priority = nat_rule_collection.value.priority
      action   = "Dnat"

      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.key
          protocols           = rule.value.protocols
          source_addresses    = rule.value.source_addresses
          destination_address = azurerm_public_ip.this.ip_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Firewall
# ---------------------------------------------------------------------------
resource "azurerm_firewall" "this" {
  name                = "${local.name_base}-fw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id
  zones               = length(var.zones) > 0 ? var.zones : null

  ip_configuration {
    name                 = "primary"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Management lock (governance/resource-locks)
# ---------------------------------------------------------------------------
resource "azurerm_management_lock" "firewall" {
  count = var.enable_management_lock ? 1 : 0

  name       = "${local.name_base}-lock-fw-${var.name_suffix}"
  scope      = azurerm_firewall.this.id
  lock_level = "CanNotDelete"
  notes      = "Connectivity-critical resource protected by framework convention (governance/resource-locks)."
}
