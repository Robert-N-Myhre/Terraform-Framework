# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids (map of logical name -> id), rule_ids

output "firewall_ids" {
  description = "Map of logical security group name to security group ID."
  value       = { for k, sg in aws_security_group.this : k => sg.id }
}

output "firewall_arns" {
  description = "Map of logical security group name to security group ARN."
  value       = { for k, sg in aws_security_group.this : k => sg.arn }
}

output "rule_ids" {
  description = "Map of '<sg-key>/<rule-key>' to rule ID for all ingress and egress rules."
  value = merge(
    { for k, r in aws_vpc_security_group_ingress_rule.this : "ingress/${k}" => r.security_group_rule_id },
    { for k, r in aws_vpc_security_group_egress_rule.this : "egress/${k}" => r.security_group_rule_id }
  )
}
