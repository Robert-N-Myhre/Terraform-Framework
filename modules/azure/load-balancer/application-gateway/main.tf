# ===========================================================================
# Azure Load Balancer — Application Gateway v2 (L7)
#
# Independently invocable: this module sources no other module in this
# framework. The dedicated gateway subnet is a plain ID input.
#
# Provider API divergence note (see README): Application Gateway is ONE
# resource with inner blocks for listeners, pools, settings, and rules —
# unlike AWS ALB (separate listener/rule/target-group resources) and GCP
# external HTTP(S) LB (forwarding rule -> proxy -> URL map -> backend
# service chain). Inner blocks are correlated by NAME, so this module
# derives all inner names deterministically from logical keys.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-azure-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/azure/load-balancer/application-gateway"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  # Deterministic inner-block names derived from logical keys.
  frontend_ip_name = "frontend-public"
  gateway_ip_name  = "gateway-ip"

  frontend_port_numbers = distinct([for l in var.http_listeners : l.frontend_port])

  pool_name     = { for k in keys(var.backend_pools) : k => "pool-${k}" }
  settings_name = { for k in keys(var.backend_http_settings) : k => "settings-${k}" }
  probe_name    = { for k in keys(var.probes) : k => "probe-${k}" }
  listener_name = { for k in keys(var.http_listeners) : k => "listener-${k}" }
  cert_name     = { for k in keys(var.ssl_certificates) : k => "cert-${k}" }
  port_name     = { for p in local.frontend_port_numbers : tostring(p) => "port-${p}" }
}

resource "azurerm_public_ip" "this" {
  name                = "${local.name_base}-pip-agw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = length(var.zones) > 0 ? var.zones : null

  tags = local.all_tags
}

resource "azurerm_application_gateway" "this" {
  name                = "${local.name_base}-agw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = length(var.zones) > 0 ? var.zones : null
  firewall_policy_id  = var.waf_policy_id

  sku {
    name = var.sku_name
    tier = var.sku_name
  }

  autoscale_configuration {
    min_capacity = var.autoscale_min_capacity
    max_capacity = var.autoscale_max_capacity
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_name
    subnet_id = var.gateway_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  dynamic "frontend_port" {
    for_each = local.port_name
    content {
      name = frontend_port.value
      port = tonumber(frontend_port.key)
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_pools
    content {
      name         = local.pool_name[backend_address_pool.key]
      fqdns        = length(backend_address_pool.value.fqdns) > 0 ? backend_address_pool.value.fqdns : null
      ip_addresses = length(backend_address_pool.value.ip_addresses) > 0 ? backend_address_pool.value.ip_addresses : null
    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = local.probe_name[probe.key]
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings

      match {
        status_code = probe.value.match_status_codes
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = local.settings_name[backend_http_settings.key]
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      request_timeout                     = backend_http_settings.value.request_timeout
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      probe_name                          = backend_http_settings.value.probe_key != null ? local.probe_name[backend_http_settings.value.probe_key] : null
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = local.cert_name[ssl_certificate.key]
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = local.listener_name[http_listener.key]
      frontend_ip_configuration_name = local.frontend_ip_name
      frontend_port_name             = local.port_name[tostring(http_listener.value.frontend_port)]
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      ssl_certificate_name           = http_listener.value.ssl_certificate_key != null ? local.cert_name[http_listener.value.ssl_certificate_key] : null
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                       = "rule-${request_routing_rule.key}"
      priority                   = request_routing_rule.value.priority
      rule_type                  = "Basic"
      http_listener_name         = local.listener_name[request_routing_rule.value.listener_key]
      backend_address_pool_name  = local.pool_name[request_routing_rule.value.backend_pool_key]
      backend_http_settings_name = local.settings_name[request_routing_rule.value.backend_http_settings_key]
    }
  }

  tags = local.all_tags
}
