output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.core_network.network_id
}

output "subnet_ids" {
  description = "Logical name to subnet ID."
  value       = module.core_network.subnet_ids
}

output "route_table_ids" {
  description = "Route table IDs (public + per-private-subnet)."
  value       = module.core_network.route_table_ids
}

output "nat_public_ips" {
  description = "NAT gateway public IPs by AZ."
  value       = module.core_network.nat_public_ips
}
