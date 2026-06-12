# Output contract for the core-network domain (see docs/adr/002):
# network_id, network_cidr, subnet_ids, route_table_ids (n/a), nat_ids, flow_log_id

output "network_id" {
  description = "ID (self-link form) of the created VPC network."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "Name of the VPC network (needed by firewall/peering/DNS modules)."
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "Self-link of the VPC network."
  value       = google_compute_network.this.self_link
}

output "network_cidr" {
  description = "GCP VPCs have no network-level CIDR (subnets carry ranges); always null. Present for cross-cloud output-contract parity."
  value       = null
}

output "subnet_ids" {
  description = "Map of logical subnet name to subnet ID."
  value       = { for k, s in google_compute_subnetwork.this : k => s.id }
}

output "subnet_self_links" {
  description = "Map of logical subnet name to subnet self-link."
  value       = { for k, s in google_compute_subnetwork.this : k => s.self_link }
}

output "subnet_cidrs" {
  description = "Map of logical subnet name to primary CIDR range."
  value       = { for k, s in google_compute_subnetwork.this : k => s.ip_cidr_range }
}

output "route_ids" {
  description = "Map of logical static route name to route ID. (GCP has no route tables — routes attach to the network.)"
  value       = { for k, r in google_compute_route.this : k => r.id }
}

output "nat_ids" {
  description = "Map with key 'nat' to the Cloud NAT ID. Empty when Cloud NAT is disabled."
  value       = length(google_compute_router_nat.this) > 0 ? { nat = google_compute_router_nat.this[0].id } : {}
}

output "flow_log_id" {
  description = "Always null — GCP flow logs are subnet-level settings, not standalone resources. Present for output-contract parity; see subnet log_config."
  value       = null
}
