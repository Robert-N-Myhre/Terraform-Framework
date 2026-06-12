# Output contract for the load-balancer domain (see docs/adr/002):
# lb_id, lb_address, listener_ids, backend_ids

output "lb_id" {
  description = "ID of the application gateway."
  value       = azurerm_application_gateway.this.id
}

output "lb_address" {
  description = "Public IP address of the application gateway frontend."
  value       = azurerm_public_ip.this.ip_address
}

output "listener_ids" {
  description = "Map of logical listener name to inner listener name (Application Gateway inner blocks have no standalone IDs — names are the stable handle)."
  value       = { for k in keys(var.http_listeners) : k => "listener-${k}" }
}

output "backend_ids" {
  description = "Map of logical backend pool name to inner pool name. Use with azurerm_network_interface_application_gateway_backend_address_pool_association in the consumer root."
  value       = { for k in keys(var.backend_pools) : k => "pool-${k}" }
}

output "backend_address_pool_resource_ids" {
  description = "Map of logical backend pool name to the full Azure resource ID of the pool (needed for NIC associations)."
  value = {
    for pool in azurerm_application_gateway.this.backend_address_pool :
    trimprefix(pool.name, "pool-") => pool.id
  }
}
