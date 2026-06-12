# Output contract for the hybrid-connectivity domain (see docs/adr/002):
# gateway_id, connection_ids, circuit metadata

output "circuit_id" {
  description = "ID of the ExpressRoute circuit."
  value       = azurerm_express_route_circuit.this.id
}

output "service_key" {
  description = "Circuit service key — hand to the connectivity provider to provision the L2 link. SENSITIVE."
  value       = azurerm_express_route_circuit.this.service_key
  sensitive   = true
}

output "service_provider_provisioning_state" {
  description = "Provider provisioning state (NotProvisioned / Provisioning / Provisioned / Deprovisioning)."
  value       = azurerm_express_route_circuit.this.service_provider_provisioning_state
}

output "gateway_id" {
  description = "ID of the ExpressRoute gateway — virtual network gateway (vnet mode) or vWAN ExpressRoute gateway (vhub mode), or null when create_gateway = false."
  value = try(
    azurerm_virtual_network_gateway.this[0].id,
    azurerm_express_route_gateway.this[0].id,
    null
  )
}

output "connection_ids" {
  description = "Map with key 'gateway' to the gateway-circuit connection ID (vnet or vhub mode), empty when not connected."
  value = merge(
    length(azurerm_virtual_network_gateway_connection.this) > 0 ? { gateway = azurerm_virtual_network_gateway_connection.this[0].id } : {},
    length(azurerm_express_route_connection.this) > 0 ? { gateway = azurerm_express_route_connection.this[0].id } : {}
  )
}

output "private_peering_id" {
  description = "ID of the Azure private peering, or null when disabled."
  value       = try(azurerm_express_route_circuit_peering.private[0].id, null)
}
