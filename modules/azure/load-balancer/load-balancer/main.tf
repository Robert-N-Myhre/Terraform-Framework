# ===========================================================================
# Azure Load Balancer — Standard Load Balancer (L4)
#
# Independently invocable: this module sources no other module in this
# framework. Subnet IDs are plain inputs; backend pool membership is the
# consumer's responsibility.
#
# Provider API divergence note (see README): Azure Standard LB is the L4
# analogue of AWS NLB, GCP passthrough network LB, and OCI NLB. Unlike AWS
# (target groups register targets), Azure pools are joined FROM the NIC
# side (azurerm_network_interface_backend_address_pool_association) or via
# address-based membership. disable_outbound_snat defaults true here —
# pair public LBs with explicit outbound rules.
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
    module_source = "modules/azure/load-balancer/load-balancer"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  frontend_name = "frontend"
  is_public     = var.frontend_type == "public"
}

resource "azurerm_public_ip" "this" {
  count = local.is_public ? 1 : 0

  name                = "${local.name_base}-pip-lb-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = length(var.zones) > 0 ? var.zones : null

  tags = local.all_tags
}

resource "azurerm_lb" "this" {
  name                = "${local.name_base}-lb-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = local.frontend_name
    public_ip_address_id          = local.is_public ? azurerm_public_ip.this[0].id : null
    subnet_id                     = local.is_public ? null : var.subnet_id
    private_ip_address            = local.is_public ? null : var.private_ip_address
    private_ip_address_allocation = local.is_public ? null : (var.private_ip_address != null ? "Static" : "Dynamic")
    zones                         = local.is_public ? null : (length(var.zones) > 0 ? var.zones : null)
  }

  tags = local.all_tags
}

resource "azurerm_lb_backend_address_pool" "this" {
  for_each = var.backend_pools

  name            = "${local.name_base}-bepool-${each.value}-${var.name_suffix}"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "this" {
  for_each = var.health_probes

  name                = "${local.name_base}-probe-${each.key}-${var.name_suffix}"
  loadbalancer_id     = azurerm_lb.this.id
  port                = each.value.port
  protocol            = each.value.protocol
  request_path        = contains(["Http", "Https"], each.value.protocol) ? each.value.request_path : null
  interval_in_seconds = each.value.interval_in_seconds
  number_of_probes    = each.value.number_of_probes
}

resource "azurerm_lb_rule" "this" {
  for_each = var.rules

  name                           = "${local.name_base}-lbrule-${each.key}-${var.name_suffix}"
  loadbalancer_id                = azurerm_lb.this.id
  frontend_ip_configuration_name = local.frontend_name
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  protocol                       = each.value.protocol

  backend_address_pool_ids = [azurerm_lb_backend_address_pool.this[each.value.backend_pool_key].id]
  probe_id                 = each.value.probe_key != null ? azurerm_lb_probe.this[each.value.probe_key].id : null

  enable_floating_ip      = each.value.enable_floating_ip
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  load_distribution       = each.value.load_distribution
  disable_outbound_snat   = each.value.disable_outbound_snat
}

resource "azurerm_lb_outbound_rule" "this" {
  for_each = local.is_public ? var.outbound_rules : {}

  name                     = "${local.name_base}-obrule-${each.key}-${var.name_suffix}"
  loadbalancer_id          = azurerm_lb.this.id
  protocol                 = each.value.protocol
  backend_address_pool_id  = azurerm_lb_backend_address_pool.this[each.value.backend_pool_key].id
  allocated_outbound_ports = each.value.allocated_outbound_ports
  idle_timeout_in_minutes  = each.value.idle_timeout_in_minutes

  frontend_ip_configuration {
    name = local.frontend_name
  }
}
