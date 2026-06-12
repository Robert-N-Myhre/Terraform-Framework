# Output contract for the hybrid-connectivity domain (see docs/adr/002):
# gateway_id, connection_ids, tunnel endpoint metadata

output "gateway_id" {
  description = "OCID of the DRG terminating the VPN (as supplied)."
  value       = var.drg_id
}

output "cpe_ids" {
  description = "Map of logical CPE name to CPE OCID."
  value       = { for k, cpe in oci_core_cpe.this : k => cpe.id }
}

output "connection_ids" {
  description = "Map of logical IPSec connection name to IPSec connection OCID."
  value       = { for k, c in oci_core_ipsec.this : k => c.id }
}

output "tunnel_oracle_ips" {
  description = "Map of logical connection name to the Oracle-side VPN headend IPs of both tunnels. Hand these to the on-premises device configuration."
  value = {
    for k in keys(var.ipsec_connections) :
    k => [for t in data.oci_core_ipsec_connection_tunnels.this[k].ip_sec_connection_tunnels : t.vpn_ip]
  }
}

output "tunnel_status" {
  description = "Map of logical connection name to both tunnels' lifecycle/status."
  value = {
    for k in keys(var.ipsec_connections) :
    k => [for t in data.oci_core_ipsec_connection_tunnels.this[k].ip_sec_connection_tunnels : t.status]
  }
}
