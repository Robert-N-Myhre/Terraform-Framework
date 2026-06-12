output "vcn_id" {
  description = "OCID of the created VCN."
  value       = module.core_network.network_id
}

output "subnet_ids" {
  description = "Logical name to subnet OCID."
  value       = module.core_network.subnet_ids
}

output "default_security_list_id" {
  description = "VCN default security list OCID."
  value       = module.core_network.default_security_list_id
}
