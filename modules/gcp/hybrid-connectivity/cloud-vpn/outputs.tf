# Output contract for the hybrid-connectivity domain (see docs/adr/002):
# gateway_id, connection_ids, tunnel endpoint metadata

output "gateway_id" {
  description = "ID of the HA VPN gateway."
  value       = google_compute_ha_vpn_gateway.this.id
}

output "gateway_interface_ips" {
  description = "Map of interface index (0/1) to the Google-side public IP. Hand these to the on-premises device configuration."
  value = {
    for iface in google_compute_ha_vpn_gateway.this.vpn_interfaces :
    tostring(iface.id) => iface.ip_address
  }
}

output "router_id" {
  description = "ID of the Cloud Router carrying the BGP sessions."
  value       = google_compute_router.this.id
}

output "connection_ids" {
  description = "Map of logical tunnel name to VPN tunnel ID."
  value       = { for k, t in google_compute_vpn_tunnel.this : k => t.id }
}

output "tunnel_self_links" {
  description = "Map of logical tunnel name to tunnel self-link (consumable as NCC hybrid-spoke URIs)."
  value       = { for k, t in google_compute_vpn_tunnel.this : k => t.self_link }
}

output "bgp_peer_ids" {
  description = "Map of logical tunnel name to router peer ID."
  value       = { for k, p in google_compute_router_peer.this : k => p.id }
}
