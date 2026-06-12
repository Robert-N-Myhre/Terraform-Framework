output "zone_ids" {
  description = "Logical name to private zone ID."
  value       = module.private_dns.zone_ids
}

output "vnet_link_ids" {
  description = "Zone/link to VNet link ID."
  value       = module.private_dns.vnet_link_ids
}
