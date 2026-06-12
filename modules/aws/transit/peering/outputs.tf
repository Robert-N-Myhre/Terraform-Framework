# Output contract for the transit domain (see docs/adr/002):
# connection_ids, route_ids

output "connection_ids" {
  description = "Map of logical peering name to VPC peering connection ID."
  value       = { for k, p in aws_vpc_peering_connection.this : k => p.id }
}

output "connection_status" {
  description = "Map of logical peering name to acceptance status."
  value       = { for k, p in aws_vpc_peering_connection.this : k => p.accept_status }
}

output "route_ids" {
  description = "Map of 'requester|accepter/<peering-key>/<route-table-id>' to route ID."
  value = merge(
    { for k, r in aws_route.requester : "requester/${k}" => r.id },
    { for k, r in aws_route.accepter : "accepter/${k}" => r.id }
  )
}
