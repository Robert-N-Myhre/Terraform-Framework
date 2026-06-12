# Output contract for the hybrid-connectivity domain (see docs/adr/002):
# gateway_id, connection_ids, circuit metadata

output "gateway_id" {
  description = "ID of the Direct Connect gateway."
  value       = aws_dx_gateway.this.id
}

output "connection_ids" {
  description = "Map with key 'connection' to the DX connection ID in use (newly created or supplied)."
  value       = { connection = local.connection_id }
}

output "vif_ids" {
  description = "Map of logical private VIF name to virtual interface ID."
  value       = { for k, vif in aws_dx_private_virtual_interface.this : k => vif.id }
}

output "association_ids" {
  description = "Map of logical association name to DX gateway association ID."
  value       = { for k, a in aws_dx_gateway_association.this : k => a.id }
}

output "vif_bgp_auth_keys" {
  description = "Map of logical private VIF name to BGP auth key. SENSITIVE — required by the on-premises router configuration."
  value       = { for k, vif in aws_dx_private_virtual_interface.this : k => vif.bgp_auth_key }
  sensitive   = true
}
