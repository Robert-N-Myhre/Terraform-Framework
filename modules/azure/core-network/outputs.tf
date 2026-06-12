# Output contract for the core-network domain (see docs/adr/002):
# network_id, network_cidr, subnet_ids, route_table_ids, nat_ids, flow_log_id

output "network_id" {
  description = "ID of the created virtual network."
  value       = azurerm_virtual_network.this.id
}

output "network_name" {
  description = "Name of the created virtual network (needed by peering and DNS-link modules)."
  value       = azurerm_virtual_network.this.name
}

output "network_cidr" {
  description = "Address space of the virtual network (list — Azure VNets support multiple ranges)."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of logical subnet name to subnet ID."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "subnet_cidrs" {
  description = "Map of logical subnet name to address prefixes."
  value       = { for k, s in azurerm_subnet.this : k => s.address_prefixes }
}

output "route_table_ids" {
  description = "Map of logical subnet name to its route table ID (only subnets with create_route_table = true)."
  value       = { for k, rt in azurerm_route_table.this : k => rt.id }
}

output "nat_ids" {
  description = "Map with key 'natgw' to the NAT gateway ID. Empty when no NAT subnets are configured."
  value       = length(azurerm_nat_gateway.this) > 0 ? { natgw = azurerm_nat_gateway.this[0].id } : {}
}

output "nat_public_ips" {
  description = "Map with key 'natgw' to the NAT gateway public IP. Empty when NAT is disabled."
  value       = length(azurerm_public_ip.nat) > 0 ? { natgw = azurerm_public_ip.nat[0].ip_address } : {}
}

output "flow_log_id" {
  description = "ID of the Network Watcher flow log, or null when disabled."
  value       = try(azurerm_network_watcher_flow_log.this[0].id, null)
}
