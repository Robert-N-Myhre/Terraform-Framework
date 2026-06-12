# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids, rule_ids (here: rule-group ARNs), plus endpoint metadata

output "firewall_ids" {
  description = "Map with single key 'firewall' to the AWS Network Firewall ARN (the provider uses ARN as ID)."
  value       = { firewall = aws_networkfirewall_firewall.this.arn }
}

output "firewall_policy_arn" {
  description = "ARN of the firewall policy."
  value       = aws_networkfirewall_firewall_policy.this.arn
}

output "rule_ids" {
  description = "Map of 'stateless|stateful/<group-key>' to rule group ARN."
  value = merge(
    { for k, g in aws_networkfirewall_rule_group.stateless : "stateless/${k}" => g.arn },
    { for k, g in aws_networkfirewall_rule_group.stateful : "stateful/${k}" => g.arn }
  )
}

output "endpoint_ids" {
  description = "Map of availability zone to firewall VPC endpoint ID. Use these as route targets to steer traffic through the firewall."
  value = {
    for ss in aws_networkfirewall_firewall.this.firewall_status[0].sync_states :
    ss.availability_zone => ss.attachment[0].endpoint_id
  }
}

output "log_group_names" {
  description = "Names of the ALERT and FLOW CloudWatch log groups, or empty map when logging is disabled."
  value = var.enable_logging ? {
    alert = aws_cloudwatch_log_group.alert[0].name
    flow  = aws_cloudwatch_log_group.flow[0].name
  } : {}
}
