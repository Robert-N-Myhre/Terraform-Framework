output "vnet_id" {
  description = "ID of the created VNet."
  value       = module.core_network.network_id
}

output "subnet_ids" {
  description = "Logical name to subnet ID."
  value       = module.core_network.subnet_ids
}

output "nsg_ids" {
  description = "Logical name to NSG ID."
  value       = module.nsgs.firewall_ids
}

output "nsg_subnet_associations" {
  description = "NSG-to-subnet association IDs."
  value       = module.nsgs.subnet_association_ids
}
