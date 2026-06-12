# ===========================================================================
# Azure Transit — VNet Peering
#
# Independently invocable: this module sources no other module in this
# framework. VNet names/IDs are plain inputs.
#
# Provider API divergence note (see README): Azure peering is TWO one-way
# resources (this module creates both); AWS is a requester/accepter
# handshake on one resource; GCP is symmetric per-network config; OCI uses
# LPG pairs. Azure peering is non-transitive; hub-spoke transit requires
# gateway transit flags or Virtual WAN (see azure/transit/vwan).
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-azure-${var.environment}"

  # Tagging convention note: azurerm_virtual_network_peering does not accept
  # tags; the governance contract is honored through naming only here.
}

resource "azurerm_virtual_network_peering" "a_to_b" {
  for_each = var.peerings

  name                      = "${local.name_base}-peer-${each.key}-ab-${var.name_suffix}"
  resource_group_name       = each.value.vnet_a_resource_group_name
  virtual_network_name      = each.value.vnet_a_name
  remote_virtual_network_id = each.value.vnet_b_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = each.value.a_to_b.allow_forwarded_traffic
  allow_gateway_transit        = each.value.a_to_b.allow_gateway_transit
  use_remote_gateways          = each.value.a_to_b.use_remote_gateways
}

resource "azurerm_virtual_network_peering" "b_to_a" {
  for_each = var.peerings

  name                      = "${local.name_base}-peer-${each.key}-ba-${var.name_suffix}"
  resource_group_name       = each.value.vnet_b_resource_group_name
  virtual_network_name      = each.value.vnet_b_name
  remote_virtual_network_id = each.value.vnet_a_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = each.value.b_to_a.allow_forwarded_traffic
  allow_gateway_transit        = each.value.b_to_a.allow_gateway_transit
  use_remote_gateways          = each.value.b_to_a.use_remote_gateways

  # Creating both directions concurrently can race in Azure; serialize.
  depends_on = [azurerm_virtual_network_peering.a_to_b]
}
