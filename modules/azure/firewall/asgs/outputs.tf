# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids — here the ASG IDs consumed by NSG rules

output "firewall_ids" {
  description = "Map of logical ASG name to application security group ID. Pass these into NSG rules (azure/firewall/nsgs) and NIC associations."
  value       = { for k, asg in azurerm_application_security_group.this : k => asg.id }
}

output "asg_names" {
  description = "Map of logical ASG name to ASG resource name."
  value       = { for k, asg in azurerm_application_security_group.this : k => asg.name }
}
