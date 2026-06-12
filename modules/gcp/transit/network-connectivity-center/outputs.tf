# Output contract for the transit domain (see docs/adr/002):
# hub_id, attachment_ids

output "hub_id" {
  description = "ID of the Network Connectivity Center hub."
  value       = google_network_connectivity_hub.this.id
}

output "attachment_ids" {
  description = "Map of logical spoke name to spoke ID across VPC and hybrid spokes."
  value = merge(
    { for k, s in google_network_connectivity_spoke.vpc : k => s.id },
    { for k, s in google_network_connectivity_spoke.hybrid : k => s.id }
  )
}

output "vpc_spoke_ids" {
  description = "Map of logical VPC spoke name to spoke ID."
  value       = { for k, s in google_network_connectivity_spoke.vpc : k => s.id }
}

output "hybrid_spoke_ids" {
  description = "Map of logical hybrid spoke name to spoke ID."
  value       = { for k, s in google_network_connectivity_spoke.hybrid : k => s.id }
}
