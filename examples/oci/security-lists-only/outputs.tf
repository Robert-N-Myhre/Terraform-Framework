output "security_list_ids" {
  description = "Logical name to security list OCID. Attach to subnets via security_list_ids."
  value       = module.security_lists.firewall_ids
}
