# Output contract for the dns domain (see docs/adr/002):
# zone_ids, zone_names, record_ids

output "zone_ids" {
  description = "Map of logical zone name to managed zone ID."
  value       = { for k, z in google_dns_managed_zone.this : k => z.id }
}

output "zone_names" {
  description = "Map of logical zone name to DNS domain name (with trailing dot)."
  value       = { for k, z in google_dns_managed_zone.this : k => z.dns_name }
}

output "zone_resource_names" {
  description = "Map of logical zone name to the GCP zone resource name (needed by record sets created elsewhere)."
  value       = { for k, z in google_dns_managed_zone.this : k => z.name }
}

output "record_ids" {
  description = "Map of '<zone-key>/<record-key>' to record set ID."
  value       = { for k, r in google_dns_record_set.this : k => r.id }
}
