# Output contract for the hybrid-connectivity domain (see docs/adr/002):
# gateway_id, connection_ids, tunnel endpoint metadata

output "gateway_id" {
  description = "ID of the virtual private gateway (vgw mode) or the supplied transit gateway ID (tgw mode)."
  value       = local.use_vgw ? aws_vpn_gateway.this[0].id : var.transit_gateway_id
}

output "customer_gateway_ids" {
  description = "Map of logical customer gateway name to customer gateway ID."
  value       = { for k, cgw in aws_customer_gateway.this : k => cgw.id }
}

output "connection_ids" {
  description = "Map of logical VPN connection name to VPN connection ID."
  value       = { for k, c in aws_vpn_connection.this : k => c.id }
}

output "tunnel_addresses" {
  description = "Map of logical VPN connection name to the two AWS-side tunnel outside IPs. Hand these to the on-premises device configuration."
  value = {
    for k, c in aws_vpn_connection.this :
    k => { tunnel1 = c.tunnel1_address, tunnel2 = c.tunnel2_address }
  }
}

output "tunnel_preshared_keys" {
  description = "Map of logical VPN connection name to tunnel pre-shared keys. SENSITIVE — handle via secure channels only."
  value = {
    for k, c in aws_vpn_connection.this :
    k => { tunnel1 = c.tunnel1_preshared_key, tunnel2 = c.tunnel2_preshared_key }
  }
  sensitive = true
}
