# Output contract for the dns domain (see docs/adr/002)

output "policy_id" {
  description = "ID of the DNS policy."
  value       = google_dns_policy.this.id
}

output "inbound_forwarding_enabled" {
  description = "Whether inbound forwarding is active. The allocated forwarder IPs are visible per network in the console/API (compute addresses named 'dns-forwarding-...'); GCP does not expose them as resource attributes."
  value       = var.enable_inbound_forwarding
}
