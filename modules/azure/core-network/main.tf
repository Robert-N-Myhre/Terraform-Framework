# ===========================================================================
# Azure Core Network Fabric — VNet, subnets, route tables, NAT, flow logs
#
# Independently invocable: this module sources no other module in this
# framework. The resource group must already exist (its lifecycle belongs
# to the consumer).
#
# Provider API divergence note (see README): Azure subnets are standalone
# child resources here (never inline blocks on the VNet — mixing the two
# styles causes perpetual drift). Unlike AWS, Azure has no IGW concept:
# internet egress is default (or via NAT Gateway / Azure Firewall), and
# route tables attach per subnet via a separate association resource.
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
    module_source = "modules/azure/core-network"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  routed_subnets = { for k, s in var.subnets : k => s if s.create_route_table }

  routes = merge([
    for s_key, s in local.routed_subnets : {
      for r_key, r in s.routes :
      "${s_key}/${r_key}" => merge(r, { subnet_key = s_key })
    }
  ]...)

  nat_subnets = toset(var.nat_gateway_subnet_keys)
}

# ---------------------------------------------------------------------------
# Virtual network + subnets
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  name                = "${local.name_base}-vnet-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = local.all_tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = "${local.name_base}-snet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  private_endpoint_network_policies_enabled = each.value.private_endpoint_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = "delegation"
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Route tables (one per subnet that opts in) + UDRs + associations
# ---------------------------------------------------------------------------
resource "azurerm_route_table" "this" {
  for_each = local.routed_subnets

  name                = "${local.name_base}-rt-${each.key}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.all_tags
}

resource "azurerm_route" "this" {
  for_each = local.routes

  name                   = "${local.name_base}-route-${replace(each.key, "/", "-")}"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[each.value.subnet_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_type == "VirtualAppliance" ? each.value.next_hop_in_ip_address : null
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = local.routed_subnets

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.this[each.key].id
}

# ---------------------------------------------------------------------------
# NAT gateway (optional)
# ---------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count = length(local.nat_subnets) > 0 ? 1 : 0

  name                = "${local.name_base}-pip-nat-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = length(var.nat_gateway_zones) > 0 ? var.nat_gateway_zones : null

  tags = local.all_tags
}

resource "azurerm_nat_gateway" "this" {
  count = length(local.nat_subnets) > 0 ? 1 : 0

  name                    = "${local.name_base}-natgw-${var.name_suffix}"
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = length(var.nat_gateway_zones) > 0 ? var.nat_gateway_zones : null

  tags = local.all_tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = length(local.nat_subnets) > 0 ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = local.nat_subnets

  subnet_id      = azurerm_subnet.this[each.value].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

# ---------------------------------------------------------------------------
# VNet flow logs via Network Watcher (optional)
# ---------------------------------------------------------------------------
resource "azurerm_network_watcher_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  name                 = "${local.name_base}-flowlog-${var.name_suffix}"
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group

  target_resource_id = azurerm_virtual_network.this.id
  storage_account_id = var.flow_log_storage_account_id
  enabled            = true
  version            = 2

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Management lock (governance/resource-locks)
# ---------------------------------------------------------------------------
resource "azurerm_management_lock" "vnet" {
  count = var.enable_management_lock ? 1 : 0

  name       = "${local.name_base}-lock-vnet-${var.name_suffix}"
  scope      = azurerm_virtual_network.this.id
  lock_level = "CanNotDelete"
  notes      = "Connectivity-critical resource protected by framework convention (governance/resource-locks)."
}
