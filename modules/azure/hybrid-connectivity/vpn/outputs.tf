# Output contract for the hybrid-connectivity domain (see docs/adr/002):
# gateway_id, connection_ids, tunnel endpoint metadata

output "gateway_id" {
  description = "ID of the gateway: virtual network gateway (vnet mode) or vWAN VPN gateway (vhub mode)."
  value       = var.attachment_type == "vnet" ? azurerm_virtual_network_gateway.this[0].id : azurerm_vpn_gateway.this[0].id
}

output "gateway_public_ips" {
  description = "Gateway public IPs (vnet mode; two when active_active). Empty in vhub mode — vWAN gateway instance IPs surface in the Azure portal/API after provisioning, not as a Terraform attribute."
  value       = [for pip in azurerm_public_ip.this : pip.ip_address]
}

output "local_gateway_ids" {
  description = "Map of logical site name to local network gateway ID (vnet mode). Empty in vhub mode."
  value       = { for k, lngw in azurerm_local_network_gateway.this : k => lngw.id }
}

output "vpn_site_ids" {
  description = "Map of logical site name to vWAN VPN site ID (vhub mode). Empty in vnet mode."
  value       = { for k, s in azurerm_vpn_site.this : k => s.id }
}

output "connection_ids" {
  description = "Map of logical connection name to connection ID (vnet or vhub mode)."
  value = merge(
    { for k, c in azurerm_virtual_network_gateway_connection.this : k => c.id },
    { for k, c in azurerm_vpn_gateway_connection.this : k => c.id }
  )
}

output "bgp_peering_address" {
  description = "Azure-side BGP peering addresses of the gateway (vnet mode with BGP enabled), or null. In vhub mode the hub router (ASN 65515) owns the BGP sessions."
  value       = var.attachment_type == "vnet" && var.enable_bgp ? azurerm_virtual_network_gateway.this[0].bgp_settings[0].peering_addresses : null
}
