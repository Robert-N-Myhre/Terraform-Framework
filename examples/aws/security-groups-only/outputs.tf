output "security_group_ids" {
  description = "Logical name to security group ID."
  value       = module.security_groups.firewall_ids
}

output "rule_ids" {
  description = "All created rule IDs."
  value       = module.security_groups.rule_ids
}
