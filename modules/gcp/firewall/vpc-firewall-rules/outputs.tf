# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids / rule_ids

output "firewall_ids" {
  description = "Map of logical rule name to firewall rule ID. (GCP has no grouping resource; each rule is standalone, so firewall_ids == rule_ids.)"
  value       = { for k, r in google_compute_firewall.this : k => r.id }
}

output "rule_ids" {
  description = "Map of logical rule name to firewall rule ID."
  value       = { for k, r in google_compute_firewall.this : k => r.id }
}

output "rule_self_links" {
  description = "Map of logical rule name to firewall rule self-link."
  value       = { for k, r in google_compute_firewall.this : k => r.self_link }
}
