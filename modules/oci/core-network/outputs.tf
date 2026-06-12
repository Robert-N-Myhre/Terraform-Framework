# Output contract for the core-network domain (see docs/adr/002):
# network_id, network_cidr, subnet_ids, route_table_ids, nat_ids, flow_log_id

output "network_id" {
  description = "OCID of the created VCN."
  value       = oci_core_vcn.this.id
}

output "network_cidr" {
  description = "CIDR blocks of the VCN (list — OCI VCNs support multiple)."
  value       = oci_core_vcn.this.cidr_blocks
}

output "subnet_ids" {
  description = "Map of logical subnet name to subnet OCID."
  value       = { for k, s in oci_core_subnet.this : k => s.id }
}

output "subnet_cidrs" {
  description = "Map of logical subnet name to CIDR block."
  value       = { for k, s in oci_core_subnet.this : k => s.cidr_block }
}

output "route_table_ids" {
  description = "Map of logical subnet name to its route table OCID."
  value       = { for k, rt in oci_core_route_table.this : k => rt.id }
}

output "internet_gateway_id" {
  description = "OCID of the internet gateway, or null when not created."
  value       = try(oci_core_internet_gateway.this[0].id, null)
}

output "nat_ids" {
  description = "Map with key 'natgw' to the NAT gateway OCID. Empty when not created."
  value       = length(oci_core_nat_gateway.this) > 0 ? { natgw = oci_core_nat_gateway.this[0].id } : {}
}

output "service_gateway_id" {
  description = "OCID of the service gateway, or null when not created."
  value       = try(oci_core_service_gateway.this[0].id, null)
}

output "default_security_list_id" {
  description = "OCID of the VCN's default security list (consumed by the oci/firewall/security-lists module if desired)."
  value       = oci_core_vcn.this.default_security_list_id
}

output "flow_log_id" {
  description = "Map of logical subnet name to flow-log OCID. Empty when flow logs are disabled."
  value       = { for k, l in oci_logging_log.flow_logs : k => l.id }
}
