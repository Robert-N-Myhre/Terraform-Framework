output "hub_id" {
  description = "vWAN hub ID — pass to the hybrid-connectivity modules (vhub mode) to attach VPN/ExpressRoute gateways."
  value       = module.vwan.hub_id["main"]
}

output "wan_id" {
  description = "Virtual WAN ID — required by azure/hybrid-connectivity/vpn in vhub mode (sites are WAN-scoped)."
  value       = module.vwan.wan_id
}

output "firewall_ilb_frontend_ip" {
  description = "Trust-side internal LB frontend IP — the next-hop all inspected traffic is steered to."
  value       = module.firewall_ilb.lb_address
}

output "vmseries_backend_pool_id" {
  description = "Backend pool ID the VM-Series trust NICs must join (azurerm_network_interface_backend_address_pool_association in the VM-Series deployment)."
  value       = module.firewall_ilb.backend_ids["vmseries-trust"]
}

output "firewall_vnet_subnet_ids" {
  description = "untrust / trust / mgmt subnet IDs for the VM-Series NICs."
  value       = module.firewall_vnet.subnet_ids
}

output "spoke_connection_ids" {
  description = "Hub connection IDs for the firewall and spoke VNets."
  value       = module.vwan.attachment_ids
}

output "spokes_route_table_id" {
  description = "Custom 'spokes' hub route table ID."
  value       = module.vwan.route_table_ids["spokes"]
}
