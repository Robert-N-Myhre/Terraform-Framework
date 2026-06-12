# Output contract for the load-balancer domain (see docs/adr/002):
# lb_id, lb_address, listener_ids, backend_ids

output "lb_id" {
  description = "ID of the URL map (the routing core of the global external LB)."
  value       = google_compute_url_map.this.id
}

output "lb_address" {
  description = "Global anycast IP address of the load balancer. Point DNS here (managed certificates activate only after DNS resolves to this IP)."
  value       = google_compute_global_address.this.address
}

output "listener_ids" {
  description = "Map of frontend forwarding rules: keys 'https' and/or 'http' to forwarding rule IDs."
  value = merge(
    var.enable_https ? { https = google_compute_global_forwarding_rule.https[0].id } : {},
    var.enable_http ? { http = google_compute_global_forwarding_rule.http[0].id } : {}
  )
}

output "backend_ids" {
  description = "Map of logical backend service name to backend service ID."
  value       = { for k, bs in google_compute_backend_service.this : k => bs.id }
}

output "managed_certificate_id" {
  description = "ID of the Google-managed SSL certificate, or null when not created."
  value       = try(google_compute_managed_ssl_certificate.this[0].id, null)
}
