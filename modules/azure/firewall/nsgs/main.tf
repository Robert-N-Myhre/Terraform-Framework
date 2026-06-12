# ===========================================================================
# Azure Firewall Domain — Network Security Groups
#
# Independently invocable: this module sources no other module in this
# framework. Subnet IDs (for association) and ASG IDs (for rule targets)
# are plain inputs.
#
# Provider API divergence note (see README): Azure NSGs attach to SUBNETS
# or NICs via association resources — unlike AWS SGs (ENI-attached at the
# instance/service) and GCP firewall rules (network-global, tag-targeted).
# NSG rules reference ASGs for workload grouping where AWS uses SG-to-SG
# references; the two models do not map 1:1.
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
    module_source = "modules/azure/firewall/nsgs"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  rules = merge([
    for nsg_key, nsg in var.network_security_groups : {
      for rule_key, rule in nsg.rules :
      "${nsg_key}/${rule_key}" => merge(rule, { nsg_key = nsg_key, rule_key = rule_key })
    }
  ]...)

  subnet_associations = merge([
    for nsg_key, nsg in var.network_security_groups : {
      for subnet_id in nsg.subnet_ids :
      "${nsg_key}/${subnet_id}" => { nsg_key = nsg_key, subnet_id = subnet_id }
    }
  ]...)
}

resource "azurerm_network_security_group" "this" {
  for_each = var.network_security_groups

  name                = "${local.name_base}-nsg-${each.key}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.all_tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = local.rules

  name                        = each.value.rule_key
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.nsg_key].name

  priority    = each.value.priority
  direction   = each.value.direction
  access      = each.value.access
  protocol    = each.value.protocol
  description = each.value.description

  source_port_ranges      = each.value.source_port_ranges
  destination_port_ranges = each.value.destination_port_ranges

  # Plural-form arguments only (see versions.tf). ASG references and address
  # prefixes are mutually exclusive per side — enforced by Azure API.
  source_address_prefixes = (
    length(each.value.source_application_security_group_ids) == 0
    ? coalesce(each.value.source_address_prefixes, ["*"])
    : null
  )
  destination_address_prefixes = (
    length(each.value.destination_application_security_group_ids) == 0
    ? coalesce(each.value.destination_address_prefixes, ["*"])
    : null
  )

  source_application_security_group_ids = (
    length(each.value.source_application_security_group_ids) > 0
    ? each.value.source_application_security_group_ids
    : null
  )
  destination_application_security_group_ids = (
    length(each.value.destination_application_security_group_ids) > 0
    ? each.value.destination_application_security_group_ids
    : null
  )
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnet_associations

  subnet_id                 = each.value.subnet_id
  network_security_group_id = azurerm_network_security_group.this[each.value.nsg_key].id
}
