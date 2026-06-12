output "vnet_id" {
  description = "ID of the created VNet."
  value       = module.core_network.network_id
}

output "subnet_ids" {
  description = "Logical name to subnet ID."
  value       = module.core_network.subnet_ids
}

output "nat_public_ips" {
  description = "NAT gateway public IP."
  value       = module.core_network.nat_public_ips
}
