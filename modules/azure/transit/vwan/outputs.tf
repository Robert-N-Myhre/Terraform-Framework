# Output contract for the transit domain (see docs/adr/002):
# hub_id(s), attachment_ids/connection_ids, route_table_ids

output "wan_id" {
  description = "ID of the virtual WAN."
  value       = azurerm_virtual_wan.this.id
}

output "hub_id" {
  description = "Map of logical hub name to virtual hub ID."
  value       = { for k, h in azurerm_virtual_hub.this : k => h.id }
}

output "hub_default_route_table_ids" {
  description = "Map of logical hub name to the hub's default route table ID (branch connections always associate here)."
  value       = { for k, h in azurerm_virtual_hub.this : k => h.default_route_table_id }
}

output "route_table_ids" {
  description = "Map of custom hub route table IDs keyed by logical name, plus 'default/<hub-key>' entries for each hub's default route table."
  value = merge(
    { for k, rt in azurerm_virtual_hub_route_table.this : k => rt.id },
    { for k, h in azurerm_virtual_hub.this : "default/${k}" => h.default_route_table_id }
  )
}

output "attachment_ids" {
  description = "Map of logical connection name to virtual hub connection ID. Use these as next_hop_connection_key targets and as gateway attachment references."
  value       = { for k, c in azurerm_virtual_hub_connection.this : k => c.id }
}

output "hub_route_ids" {
  description = "Map of logical route name to hub route resource ID."
  value       = { for k, r in azurerm_virtual_hub_route_table_route.this : k => r.id }
}

output "bgp_connection_ids" {
  description = "Map of logical BGP peering name to hub BGP connection ID."
  value       = { for k, b in azurerm_virtual_hub_bgp_connection.this : k => b.id }
}
