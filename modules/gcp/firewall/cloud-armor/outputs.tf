# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids, rule_ids

output "firewall_ids" {
  description = "Map with single key 'policy' to the Cloud Armor security policy ID. Attach to backend services via this ID."
  value       = { policy = google_compute_security_policy.this.id }
}

output "policy_self_link" {
  description = "Self-link of the security policy (accepted by backend service security_policy arguments)."
  value       = google_compute_security_policy.this.self_link
}

output "rule_ids" {
  description = "Map of logical rule name to rule priority (Cloud Armor rules are addressed by priority within the policy)."
  value       = { for k, r in var.rules : k => r.priority }
}
