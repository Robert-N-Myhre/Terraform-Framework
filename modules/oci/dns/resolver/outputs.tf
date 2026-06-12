# Output contract for the dns domain (see docs/adr/002):
# resolver endpoints + rule metadata

output "resolver_id" {
  description = "OCID of the managed VCN resolver."
  value       = oci_dns_resolver.this.id
}

output "inbound_endpoint_ips" {
  description = "Map of logical listening endpoint name to listening address (targets for on-premises conditional forwarders)."
  value       = { for k, ep in oci_dns_resolver_endpoint.listening : k => ep.listening_address }
}

output "outbound_endpoint_ips" {
  description = "Map of logical forwarding endpoint name to forwarding address."
  value       = { for k, ep in oci_dns_resolver_endpoint.forwarding : k => ep.forwarding_address }
}

output "rule_ids" {
  description = "Map of logical forward rule name to its covered domains (rules live inline on the resolver without standalone OCIDs)."
  value       = { for k, r in var.forward_rules : k => r.domain_names }
}
