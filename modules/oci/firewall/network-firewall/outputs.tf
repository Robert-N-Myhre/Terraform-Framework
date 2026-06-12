# Output contract for the firewall domain (see docs/adr/002):
# firewall_ids, rule_ids, routing metadata

output "firewall_ids" {
  description = "Map with single key 'firewall' to the OCI Network Firewall OCID."
  value       = { firewall = oci_network_firewall_network_firewall.this.id }
}

output "firewall_private_ip" {
  description = "Private IPv4 address of the firewall — target this in VCN route rules to steer traffic through the firewall."
  value       = oci_network_firewall_network_firewall.this.ipv4address
}

output "policy_id" {
  description = "OCID of the network firewall policy."
  value       = oci_network_firewall_network_firewall_policy.this.id
}

output "rule_ids" {
  description = "Map of logical rule name to security rule name within the policy (rules are policy-scoped, not standalone OCIDs)."
  value       = { for k, r in oci_network_firewall_network_firewall_policy_security_rule.this : k => r.name }
}
