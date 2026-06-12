# Output contract for the dns domain (see docs/adr/002):
# resolver endpoints + rule IDs

output "resolver_id" {
  description = "ID of the DNS private resolver."
  value       = azurerm_private_dns_resolver.this.id
}

output "inbound_endpoint_ids" {
  description = "Map of logical inbound endpoint name to endpoint ID."
  value       = { for k, ep in azurerm_private_dns_resolver_inbound_endpoint.this : k => ep.id }
}

output "inbound_endpoint_ips" {
  description = "Map of logical inbound endpoint name to private IP (targets for on-premises conditional forwarders)."
  value = {
    for k, ep in azurerm_private_dns_resolver_inbound_endpoint.this :
    k => ep.ip_configurations[0].private_ip_address
  }
}

output "outbound_endpoint_id" {
  description = "Map of logical outbound endpoint name to endpoint ID."
  value       = { for k, ep in azurerm_private_dns_resolver_outbound_endpoint.this : k => ep.id }
}

output "ruleset_ids" {
  description = "Map of logical ruleset name to forwarding ruleset ID."
  value       = { for k, rs in azurerm_private_dns_resolver_dns_forwarding_ruleset.this : k => rs.id }
}

output "rule_ids" {
  description = "Map of '<ruleset-key>/<rule-key>' to forwarding rule ID."
  value       = { for k, r in azurerm_private_dns_resolver_forwarding_rule.this : k => r.id }
}
