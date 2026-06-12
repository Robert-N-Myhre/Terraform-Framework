output "view_ids" {
  description = "Logical name to DNS view OCID (attach to a VCN resolver to enable resolution)."
  value       = module.private_dns.view_ids
}

output "zone_ids" {
  description = "View/zone to zone OCID."
  value       = module.private_dns.zone_ids
}
