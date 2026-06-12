output "zone_ids" {
  description = "Logical name to managed zone ID."
  value       = module.private_dns.zone_ids
}

output "record_ids" {
  description = "Created record set IDs."
  value       = module.private_dns.record_ids
}
