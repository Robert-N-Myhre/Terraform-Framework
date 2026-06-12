# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
# ---------------------------------------------------------------------------
variable "prefix" {
  type        = string
  description = "Short organization or project prefix. First token of every resource name: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, test, prod). Used in resource names and mandatory tags."
}

variable "owner" {
  type        = string
  description = "Team or individual that owns the deployed resources. Applied as the mandatory 'owner' tag."
}

variable "cost_center" {
  type        = string
  description = "Cost center code for chargeback/showback. Applied as the mandatory 'cost_center' tag."
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional additional tags merged beneath the mandatory tag set. Mandatory tags win on key collision."
  default     = {}
}

variable "name_suffix" {
  type        = string
  description = "Final token of every resource name, used to disambiguate multiple instances of this module."
  default     = "01"
}

# ---------------------------------------------------------------------------
# Module-specific variables
# ---------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group for the application gateway."
}

variable "location" {
  type        = string
  description = "Azure region for the application gateway."
}

variable "gateway_subnet_id" {
  type        = string
  description = "ID of the dedicated subnet for the application gateway (recommended /24, no other workloads). Supplied by ID — no framework dependency is implied."
}

variable "sku_name" {
  type        = string
  description = "v2 SKU name: Standard_v2 or WAF_v2."
  default     = "Standard_v2"

  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_name)
    error_message = "Only v2 SKUs are supported: Standard_v2 or WAF_v2."
  }
}

variable "autoscale_min_capacity" {
  type        = number
  description = "Minimum autoscale capacity units."
  default     = 1
}

variable "autoscale_max_capacity" {
  type        = number
  description = "Maximum autoscale capacity units."
  default     = 4
}

variable "zones" {
  type        = list(string)
  description = "Availability zones (e.g., [\"1\", \"2\", \"3\"])."
  default     = []
}

variable "waf_policy_id" {
  type        = string
  description = "ID of an existing WAF policy to attach (WAF_v2 SKU). Null = no policy."
  default     = null
}

variable "backend_pools" {
  type = map(object({
    fqdns        = optional(list(string), [])
    ip_addresses = optional(list(string), [])
  }))
  description = "Backend address pools keyed by logical name (FQDNs and/or IPs; empty pool = NIC-joined by the consumer)."
}

variable "backend_http_settings" {
  type = map(object({
    port                                = number
    protocol                            = optional(string, "Http") # Http | Https
    cookie_based_affinity               = optional(string, "Disabled")
    request_timeout                     = optional(number, 30)
    pick_host_name_from_backend_address = optional(bool, false)
    probe_key                           = optional(string)
  }))
  description = "Backend HTTP settings keyed by logical name."
}

variable "probes" {
  type = map(object({
    protocol                                  = optional(string, "Http")
    path                                      = string
    interval                                  = optional(number, 30)
    timeout                                   = optional(number, 30)
    unhealthy_threshold                       = optional(number, 3)
    pick_host_name_from_backend_http_settings = optional(bool, true)
    match_status_codes                        = optional(list(string), ["200-399"])
  }))
  description = "Custom health probes keyed by logical name."
  default     = {}
}

variable "http_listeners" {
  type = map(object({
    frontend_port            = number
    protocol                 = optional(string, "Http") # Http | Https
    host_name                = optional(string)
    ssl_certificate_key      = optional(string) # logical key in ssl_certificates
  }))
  description = "HTTP(S) listeners keyed by logical name. HTTPS listeners reference an SSL certificate by logical key."

  validation {
    condition = alltrue([
      for l in var.http_listeners : l.protocol != "Https" || l.ssl_certificate_key != null
    ])
    error_message = "Https listeners require ssl_certificate_key."
  }
}

variable "ssl_certificates" {
  type = map(object({
    key_vault_secret_id = string # versionless Key Vault secret ID recommended
  }))
  description = "SSL certificates keyed by logical name, sourced from Key Vault. The gateway's managed identity (identity_ids) needs Key Vault secret-read access."
  default     = {}
}

variable "identity_ids" {
  type        = list(string)
  description = "User-assigned managed identity IDs for the gateway (required for Key Vault certificate access)."
  default     = []
}

variable "request_routing_rules" {
  type = map(object({
    priority                  = number
    listener_key              = string
    backend_pool_key          = string
    backend_http_settings_key = string
  }))
  description = "Basic routing rules keyed by logical name, joining listener -> pool + settings by logical keys."
}
