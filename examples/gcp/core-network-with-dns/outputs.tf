output "network_self_link" {
  description = "Self-link of the created VPC."
  value       = module.core_network.network_self_link
}

output "subnet_self_links" {
  description = "Logical name to subnet self-link."
  value       = module.core_network.subnet_self_links
}

output "zone_ids" {
  description = "Logical name to managed zone ID."
  value       = module.private_dns.zone_ids
}
