# Output contract for the transit domain (see docs/adr/002):
# connection_ids

output "connection_ids" {
  description = "Map of '<peering-key>/a-to-b' and '<peering-key>/b-to-a' to peering resource IDs."
  value = merge(
    { for k, p in google_compute_network_peering.a_to_b : "${k}/a-to-b" => p.id },
    { for k, p in google_compute_network_peering.b_to_a : "${k}/b-to-a" => p.id }
  )
}

output "connection_states" {
  description = "Map of '<peering-key>/a-to-b' and '<peering-key>/b-to-a' to peering state (ACTIVE when both sides exist)."
  value = merge(
    { for k, p in google_compute_network_peering.a_to_b : "${k}/a-to-b" => p.state },
    { for k, p in google_compute_network_peering.b_to_a : "${k}/b-to-a" => p.state }
  )
}
