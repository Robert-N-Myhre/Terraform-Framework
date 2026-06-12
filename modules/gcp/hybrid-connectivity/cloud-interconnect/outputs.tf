# Output contract for the hybrid-connectivity domain (see docs/adr/002):
# gateway_id (router), connection_ids (attachments), circuit metadata

output "gateway_id" {
  description = "ID of the Cloud Router (the BGP speaker for all attachments)."
  value       = google_compute_router.this.id
}

output "connection_ids" {
  description = "Map of logical attachment name to interconnect attachment ID."
  value       = { for k, a in google_compute_interconnect_attachment.this : k => a.id }
}

output "attachment_self_links" {
  description = "Map of logical attachment name to self-link (consumable as NCC hybrid-spoke URIs)."
  value       = { for k, a in google_compute_interconnect_attachment.this : k => a.self_link }
}

output "pairing_keys" {
  description = "Map of logical PARTNER attachment name to pairing key — hand to the service provider. SENSITIVE."
  value = {
    for k, a in google_compute_interconnect_attachment.this :
    k => a.pairing_key if a.pairing_key != null
  }
  sensitive = true
}

output "cloud_router_ip_addresses" {
  description = "Map of logical attachment name to the Google-side BGP address allocated on the attachment."
  value       = { for k, a in google_compute_interconnect_attachment.this : k => a.cloud_router_ip_address }
}
