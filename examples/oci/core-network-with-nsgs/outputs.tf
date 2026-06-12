output "vcn_id" {
  description = "OCID of the created VCN."
  value       = module.core_network.network_id
}

output "subnet_ids" {
  description = "Logical name to subnet OCID."
  value       = module.core_network.subnet_ids
}

output "nsg_ids" {
  description = "Logical name to NSG OCID — attach to VNICs where workloads are managed."
  value       = module.nsgs.firewall_ids
}
