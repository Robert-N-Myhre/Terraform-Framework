# Output contract for the dns domain (see docs/adr/002):
# zone_ids, zone_names, record_ids, plus view IDs

output "view_ids" {
  description = "Map of logical view name to DNS view OCID. Attach these to VCN resolvers (oci/dns/resolver) to enable resolution."
  value       = { for k, v in oci_dns_view.this : k => v.id }
}

output "zone_ids" {
  description = "Map of '<view-key>/<zone-key>' to private zone OCID."
  value       = { for k, z in oci_dns_zone.this : k => z.id }
}

output "zone_names" {
  description = "Map of '<view-key>/<zone-key>' to zone domain name."
  value       = { for k, z in oci_dns_zone.this : k => z.name }
}

output "record_ids" {
  description = "Map of '<view-key>/<zone-key>/<record-key>' to rrset ID."
  value       = { for k, r in oci_dns_rrset.this : k => r.id }
}
