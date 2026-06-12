output "nsg_ids" {
  description = "Logical name to NSG ID."
  value       = module.nsgs.firewall_ids
}

output "rule_ids" {
  description = "All created rule IDs."
  value       = module.nsgs.rule_ids
}
