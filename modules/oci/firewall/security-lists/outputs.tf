# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids, rule_ids

output "firewall_ids" {
  description = "Map of logical security list name to security list OCID. Attach to subnets via security_list_ids in the consumer root."
  value       = { for k, sl in oci_core_security_list.this : k => sl.id }
}

output "rule_ids" {
  description = "OCI security list rules are inline blocks without standalone IDs; this output maps logical list names to their rule counts for parity."
  value = {
    for k, sl in var.security_lists :
    k => { ingress = length(sl.ingress_rules), egress = length(sl.egress_rules) }
  }
}
