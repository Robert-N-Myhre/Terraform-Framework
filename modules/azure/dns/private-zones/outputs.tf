# Output contract for the dns domain (see docs/adr/002):
# zone_ids, zone_names, record_ids

output "zone_ids" {
  description = "Map of logical zone name to private DNS zone ID."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.id }
}

output "zone_names" {
  description = "Map of logical zone name to DNS domain name."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.name }
}

output "vnet_link_ids" {
  description = "Map of '<zone-key>/<link-key>' to virtual network link ID."
  value       = { for k, l in azurerm_private_dns_zone_virtual_network_link.this : k => l.id }
}

output "record_ids" {
  description = "Map of '<type>/<zone-key>/<record-key>' to record ID across A, CNAME, and TXT records."
  value = merge(
    { for k, r in azurerm_private_dns_a_record.this : "a/${k}" => r.id },
    { for k, r in azurerm_private_dns_cname_record.this : "cname/${k}" => r.id },
    { for k, r in azurerm_private_dns_txt_record.this : "txt/${k}" => r.id }
  )
}
