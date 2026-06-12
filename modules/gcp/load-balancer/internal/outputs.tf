# Output contract for the load-balancer domain (see docs/adr/002):
# lb_id, lb_address, listener_ids, backend_ids

output "lb_id" {
  description = "ID of the forwarding rule (the ILB frontend)."
  value       = google_compute_forwarding_rule.this.id
}

output "lb_address" {
  description = "Internal IP address of the load balancer."
  value       = google_compute_forwarding_rule.this.ip_address
}

output "listener_ids" {
  description = "Map with single key 'forwarding_rule' to the forwarding rule self-link (GCP's analogue of a listener)."
  value       = { forwarding_rule = google_compute_forwarding_rule.this.self_link }
}

output "backend_ids" {
  description = "Map with single key 'backend_service' to the region backend service ID."
  value       = { backend_service = google_compute_region_backend_service.this.id }
}

output "health_check_id" {
  description = "ID of the regional health check."
  value       = google_compute_region_health_check.this.id
}
