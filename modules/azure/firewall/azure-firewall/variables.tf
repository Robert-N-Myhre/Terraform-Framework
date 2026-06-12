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
  description = "Name of the existing resource group for the firewall."
}

variable "location" {
  type        = string
  description = "Azure region for the firewall."
}

variable "firewall_subnet_id" {
  type        = string
  description = "ID of the AzureFirewallSubnet (must be named exactly 'AzureFirewallSubnet', minimum /26). Supplied by ID — no framework dependency is implied."
}

variable "sku_tier" {
  type        = string
  description = "Firewall SKU tier: Standard or Premium (Premium adds TLS inspection, IDPS, URL filtering)."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Standard or Premium."
  }
}

variable "zones" {
  type        = list(string)
  description = "Availability zones for the firewall (e.g., [\"1\", \"2\", \"3\"]). Empty = regional (non-zonal)."
  default     = []
}

variable "threat_intelligence_mode" {
  type        = string
  description = "Threat-intel mode on the policy: Off, Alert, or Deny."
  default     = "Alert"

  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.threat_intelligence_mode)
    error_message = "threat_intelligence_mode must be Off, Alert, or Deny."
  }
}

variable "dns_proxy_enabled" {
  type        = bool
  description = "Enable DNS proxy on the firewall policy (required when using FQDNs in network rules)."
  default     = false
}

variable "dns_servers" {
  type        = list(string)
  description = "Custom DNS servers the firewall uses for resolution when DNS proxy is enabled. Empty = Azure DNS."
  default     = []
}

variable "network_rule_collections" {
  type = map(object({
    priority = number
    action   = string # "Allow" | "Deny"
    rules = map(object({
      protocols             = list(string) # "TCP" | "UDP" | "ICMP" | "Any"
      source_addresses      = optional(list(string), [])
      destination_addresses = optional(list(string), [])
      destination_fqdns     = optional(list(string), []) # requires dns_proxy_enabled
      destination_ports     = list(string)
    }))
  }))
  description = "L3/L4 network rule collections keyed by logical name."
  default     = {}
}

variable "application_rule_collections" {
  type = map(object({
    priority = number
    action   = string # "Allow" | "Deny"
    rules = map(object({
      source_addresses  = optional(list(string), [])
      destination_fqdns = optional(list(string), [])
      protocols = optional(list(object({
        type = string # "Http" | "Https"
        port = number
      })), [{ type = "Https", port = 443 }])
    }))
  }))
  description = "L7 application (FQDN) rule collections keyed by logical name."
  default     = {}
}

variable "nat_rule_collections" {
  type = map(object({
    priority = number
    rules = map(object({
      protocols           = list(string) # "TCP" | "UDP"
      source_addresses    = list(string)
      destination_ports   = list(string)
      translated_address  = string
      translated_port     = number
    }))
  }))
  description = "DNAT rule collections keyed by logical name. Destination address is always the firewall public IP."
  default     = {}
}

variable "enable_management_lock" {
  type        = bool
  description = "Apply a CanNotDelete management lock to the firewall (governance/resource-locks)."
  default     = true
}
