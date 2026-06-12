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
  description = "Name of the existing resource group for the resolver."
}

variable "location" {
  type        = string
  description = "Azure region for the resolver (must match the VNet's region)."
}

variable "vnet_id" {
  type        = string
  description = "ID of the virtual network the resolver lives in. Supplied by ID — no framework dependency is implied."
}

variable "inbound_endpoints" {
  type = map(object({
    subnet_id = string # delegated to Microsoft.Network/dnsResolvers
  }))
  description = "Inbound endpoints keyed by logical name. Each needs its own dedicated subnet delegated to Microsoft.Network/dnsResolvers. The endpoint IP is the target for on-premises conditional forwarders."
  default     = {}
}

variable "outbound_endpoints" {
  type = map(object({
    subnet_id = string # delegated to Microsoft.Network/dnsResolvers
  }))
  description = "Outbound endpoints keyed by logical name, each in its own delegated subnet. Forwarding rulesets attach to outbound endpoints."
  default     = {}
}

variable "forwarding_rulesets" {
  type = map(object({
    outbound_endpoint_keys = list(string)               # logical keys from outbound_endpoints
    vnet_link_ids          = optional(list(string), []) # VNets that consume the ruleset
    rules = optional(map(object({
      domain_name = string # MUST end with a dot, e.g. "corp.example.com."
      enabled     = optional(bool, true)
      target_dns_servers = list(object({
        ip_address = string
        port       = optional(number, 53)
      }))
    })), {})
  }))
  description = "Forwarding rulesets keyed by logical name, attached to outbound endpoints, with per-domain forwarding rules and VNet links. Rule domain names must be fully qualified WITH trailing dot."
  default     = {}

  validation {
    condition = alltrue(flatten([
      for rs in var.forwarding_rulesets : [
        for r in rs.rules : endswith(r.domain_name, ".")
      ]
    ]))
    error_message = "Forwarding rule domain_name values must end with a trailing dot (e.g., \"corp.example.com.\")."
  }
}
