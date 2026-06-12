# Output contract for the hybrid-connectivity domain (see docs/adr/002):
# gateway_id, connection_ids, circuit metadata

output "gateway_id" {
  description = "OCID of the DRG terminating private circuits (as supplied)."
  value       = var.drg_id
}

output "connection_ids" {
  description = "Map of logical virtual circuit name to virtual circuit OCID."
  value       = { for k, vc in oci_core_virtual_circuit.this : k => vc.id }
}

output "circuit_states" {
  description = "Map of logical virtual circuit name to BGP management state and provider state."
  value = {
    for k, vc in oci_core_virtual_circuit.this :
    k => { bgp_state = vc.bgp_session_state, provider_state = vc.provider_state }
  }
}

output "oracle_bgp_asn" {
  description = "Map of logical virtual circuit name to the Oracle-side BGP ASN."
  value       = { for k, vc in oci_core_virtual_circuit.this : k => vc.oracle_bgp_asn }
}
