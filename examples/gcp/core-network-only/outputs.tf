output "network_id" {
  description = "ID of the created VPC."
  value       = module.core_network.network_id
}

output "network_self_link" {
  description = "Self-link of the VPC (input for firewall/DNS/VPN modules)."
  value       = module.core_network.network_self_link
}

output "subnet_self_links" {
  description = "Logical name to subnet self-link."
  value       = module.core_network.subnet_self_links
}
