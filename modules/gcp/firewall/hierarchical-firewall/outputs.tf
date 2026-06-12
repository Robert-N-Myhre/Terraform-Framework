# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids, rule_ids

output "firewall_ids" {
  description = "Map with single key 'policy' to the hierarchical firewall policy ID."
  value       = { policy = google_compute_firewall_policy.this.id }
}

output "rule_ids" {
  description = "Map of logical rule name to firewall policy rule priority (rules are addressed by priority within the policy)."
  value       = { for k, r in google_compute_firewall_policy_rule.this : k => r.priority }
}

output "association_ids" {
  description = "Map of logical association name to association ID."
  value       = { for k, a in google_compute_firewall_policy_association.this : k => a.id }
}
