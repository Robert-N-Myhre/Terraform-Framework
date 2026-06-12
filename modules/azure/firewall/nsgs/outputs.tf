# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids (map of logical name -> id), rule_ids

output "firewall_ids" {
  description = "Map of logical NSG name to network security group ID."
  value       = { for k, nsg in azurerm_network_security_group.this : k => nsg.id }
}

output "firewall_names" {
  description = "Map of logical NSG name to NSG resource name (needed for NIC-level associations in the consumer root)."
  value       = { for k, nsg in azurerm_network_security_group.this : k => nsg.name }
}

output "rule_ids" {
  description = "Map of '<nsg-key>/<rule-key>' to security rule ID."
  value       = { for k, r in azurerm_network_security_rule.this : k => r.id }
}

output "subnet_association_ids" {
  description = "Map of '<nsg-key>/<subnet-id>' to subnet association ID."
  value       = { for k, a in azurerm_subnet_network_security_group_association.this : k => a.id }
}
