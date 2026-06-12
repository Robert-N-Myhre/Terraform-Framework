# Output contract for the load-balancer domain (see docs/adr/002):
# lb_id, lb_address, listener_ids, backend_ids

output "lb_id" {
  description = "OCID of the load balancer."
  value       = oci_load_balancer_load_balancer.this.id
}

output "lb_address" {
  description = "First IP address of the load balancer (public for public LBs, private otherwise)."
  value       = oci_load_balancer_load_balancer.this.ip_address_details[0].ip_address
}

output "listener_ids" {
  description = "Map of logical listener name to listener name on the LB (OCI listeners are LB-scoped, addressed by name)."
  value       = { for k, l in oci_load_balancer_listener.this : k => l.name }
}

output "backend_ids" {
  description = "Map of logical backend set name to backend set name on the LB. Register dynamic backends against these in the consumer root."
  value       = { for k, bs in oci_load_balancer_backend_set.this : k => bs.name }
}
