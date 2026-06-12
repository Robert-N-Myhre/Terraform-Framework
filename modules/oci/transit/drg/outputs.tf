# Output contract for the transit domain (see docs/adr/002):
# hub_id, attachment_ids, route_table_ids

output "hub_id" {
  description = "OCID of the DRG. VCN route rules targeting the DRG use this OCID; hybrid-connectivity modules attach to it."
  value       = oci_core_drg.this.id
}

output "attachment_ids" {
  description = "Map of logical attachment name to DRG attachment OCID."
  value       = { for k, a in oci_core_drg_attachment.this : k => a.id }
}

output "route_table_ids" {
  description = "Map of logical route table name to DRG route table OCID."
  value       = { for k, rt in oci_core_drg_route_table.this : k => rt.id }
}

output "rpc_ids" {
  description = "Map of logical remote peering connection name to RPC OCID (hand to the peer region's initiating side)."
  value       = { for k, rpc in oci_core_remote_peering_connection.this : k => rpc.id }
}
