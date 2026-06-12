# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids, rule_ids, plus routing metadata

output "firewall_ids" {
  description = "Map with single key 'firewall' to the Azure Firewall ID."
  value       = { firewall = azurerm_firewall.this.id }
}

output "firewall_private_ip" {
  description = "Private IP of the firewall — use as next_hop_in_ip_address in UDRs that steer traffic through the firewall."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP of the firewall (DNAT destination)."
  value       = azurerm_public_ip.this.ip_address
}

output "policy_id" {
  description = "ID of the firewall policy."
  value       = azurerm_firewall_policy.this.id
}

output "rule_ids" {
  description = "Map with single key 'rule_collection_group' to the rule collection group ID (Azure manages rules inside the group, not as standalone resources)."
  value       = { rule_collection_group = azurerm_firewall_policy_rule_collection_group.this.id }
}
