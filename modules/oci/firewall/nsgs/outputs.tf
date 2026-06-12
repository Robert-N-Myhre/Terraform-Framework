# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids, rule_ids

output "firewall_ids" {
  description = "Map of logical NSG name to network security group OCID. Reference these from VNICs, load balancers, and other NSG-capable resources."
  value       = { for k, nsg in oci_core_network_security_group.this : k => nsg.id }
}

output "rule_ids" {
  description = "Map of '<nsg-key>/<rule-key>' to security rule OCID."
  value       = { for k, r in oci_core_network_security_group_security_rule.this : k => r.id }
}
