# Output contract for the load-balancer domain (see docs/adr/002):
# lb_id, lb_address, listener_ids (rules), backend_ids

output "lb_id" {
  description = "ID of the load balancer."
  value       = azurerm_lb.this.id
}

output "lb_address" {
  description = "Frontend address: public IP for public frontends, private IP for internal frontends."
  value = (
    local.is_public
    ? azurerm_public_ip.this[0].ip_address
    : azurerm_lb.this.frontend_ip_configuration[0].private_ip_address
  )
}

output "listener_ids" {
  description = "Map of logical rule name to load balancing rule ID (Azure's analogue of listeners)."
  value       = { for k, r in azurerm_lb_rule.this : k => r.id }
}

output "backend_ids" {
  description = "Map of logical backend pool name to backend address pool ID. Associate NICs or addresses against these in the consumer root module."
  value       = { for k, p in azurerm_lb_backend_address_pool.this : k => p.id }
}

output "probe_ids" {
  description = "Map of logical probe name to health probe ID."
  value       = { for k, p in azurerm_lb_probe.this : k => p.id }
}
