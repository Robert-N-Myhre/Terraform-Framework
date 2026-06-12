# Output contract for the dns domain (see docs/adr/002):
# resolver endpoints + rule IDs

output "inbound_endpoint_id" {
  description = "ID of the inbound resolver endpoint, or null when not created."
  value       = try(aws_route53_resolver_endpoint.inbound[0].id, null)
}

output "inbound_endpoint_ips" {
  description = "IP addresses of the inbound endpoint ENIs (targets for on-premises conditional forwarders). Empty when not created."
  value       = try([for ip in aws_route53_resolver_endpoint.inbound[0].ip_address : ip.ip], [])
}

output "outbound_endpoint_id" {
  description = "ID of the outbound resolver endpoint, or null when not created."
  value       = try(aws_route53_resolver_endpoint.outbound[0].id, null)
}

output "rule_ids" {
  description = "Map of logical rule name to resolver rule ID."
  value       = { for k, r in aws_route53_resolver_rule.this : k => r.id }
}

output "rule_association_ids" {
  description = "Map of '<rule-key>/<vpc-id>' to resolver rule association ID."
  value       = { for k, a in aws_route53_resolver_rule_association.this : k => a.id }
}

output "query_log_config_id" {
  description = "ID of the resolver query log configuration, or null when query logging is disabled."
  value       = try(aws_route53_resolver_query_log_config.this[0].id, null)
}
