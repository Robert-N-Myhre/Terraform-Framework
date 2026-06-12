# Output contract for the transit domain (see docs/adr/002):
# connection_ids

output "connection_ids" {
  description = "Map of '<peering-key>/a' and '<peering-key>/b' to LPG OCIDs. Use these as route-rule network entities in each VCN's route tables."
  value = merge(
    { for k, lpg in oci_core_local_peering_gateway.a : "${k}/a" => lpg.id },
    { for k, lpg in oci_core_local_peering_gateway.b : "${k}/b" => lpg.id }
  )
}

output "peering_status" {
  description = "Map of logical peering name to the side-A peering status (PEERED when established)."
  value       = { for k, lpg in oci_core_local_peering_gateway.a : k => lpg.peering_status }
}

output "peer_advertised_cidrs" {
  description = "Map of logical peering name to the CIDR advertised by the peer (side A's view)."
  value       = { for k, lpg in oci_core_local_peering_gateway.a : k => lpg.peer_advertised_cidr }
}
