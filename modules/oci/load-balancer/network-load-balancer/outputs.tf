# Output contract for the load-balancer domain (see docs/adr/002):
# lb_id, lb_address, listener_ids, backend_ids

output "lb_id" {
  description = "OCID of the network load balancer."
  value       = oci_network_load_balancer_network_load_balancer.this.id
}

output "lb_address" {
  description = "First IP address of the NLB."
  value       = oci_network_load_balancer_network_load_balancer.this.ip_addresses[0].ip_address
}

output "listener_ids" {
  description = "Map of logical listener name to listener name on the NLB."
  value       = { for k, l in oci_network_load_balancer_listener.this : k => l.name }
}

output "backend_ids" {
  description = "Map of logical backend set name to backend set name. Register dynamic backends against these in the consumer root."
  value       = { for k, bs in oci_network_load_balancer_backend_set.this : k => bs.name }
}
