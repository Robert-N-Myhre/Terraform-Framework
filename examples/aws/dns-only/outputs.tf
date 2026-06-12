output "zone_ids" {
  description = "Logical name to hosted zone ID."
  value       = module.private_dns.zone_ids
}

output "record_fqdns" {
  description = "Created record FQDNs."
  value       = module.private_dns.record_ids
}
