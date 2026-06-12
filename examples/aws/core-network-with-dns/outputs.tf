output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.core_network.network_id
}

output "subnet_ids" {
  description = "Logical name to subnet ID."
  value       = module.core_network.subnet_ids
}

output "zone_ids" {
  description = "Logical name to hosted zone ID."
  value       = module.private_dns.zone_ids
}
