# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids (map of logical name -> id), rule_ids

output "firewall_ids" {
  description = "Map of logical NACL name to network ACL ID."
  value       = { for k, acl in aws_network_acl.this : k => acl.id }
}

output "firewall_arns" {
  description = "Map of logical NACL name to network ACL ARN."
  value       = { for k, acl in aws_network_acl.this : k => acl.arn }
}

output "rule_ids" {
  description = "Map of 'ingress|egress/<acl-key>/<rule-key>' to NACL rule ID."
  value = merge(
    { for k, r in aws_network_acl_rule.ingress : "ingress/${k}" => r.id },
    { for k, r in aws_network_acl_rule.egress : "egress/${k}" => r.id }
  )
}

output "subnet_association_ids" {
  description = "Map of '<acl-key>/<subnet-id>' to NACL association ID."
  value       = { for k, a in aws_network_acl_association.this : k => a.id }
}
