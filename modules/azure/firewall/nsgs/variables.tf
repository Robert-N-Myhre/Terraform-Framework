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
  description = "Name of the existing resource group for the NSGs."
}

variable "location" {
  type        = string
  description = "Azure region for the NSGs."
}

variable "network_security_groups" {
  type = map(object({
    subnet_ids = optional(list(string), []) # subnets to associate
    rules = optional(map(object({
      priority  = number # 100-4096, unique per NSG+direction
      direction = string # "Inbound" | "Outbound"
      access    = string # "Allow" | "Deny"
      protocol  = string # "Tcp" | "Udp" | "Icmp" | "*"
      source_port_ranges           = optional(list(string), ["*"])
      destination_port_ranges      = optional(list(string), ["*"])
      source_address_prefixes      = optional(list(string)) # CIDRs or service tags
      destination_address_prefixes = optional(list(string))
      source_application_security_group_ids      = optional(list(string), [])
      destination_application_security_group_ids = optional(list(string), [])
      description = optional(string)
    })), {})
  }))
  description = <<-EOT
    Map of NSGs keyed by logical name. Rules accept CIDRs, Azure service tags
    (e.g. "Internet", "VirtualNetwork", "AzureLoadBalancer"), or ASG IDs (use
    the azure/firewall/asgs module independently to create ASGs and pass its
    IDs here). Exactly one of address prefixes or ASG IDs per side of a rule.
    NSGs are stateful — no return rules needed.
  EOT

  validation {
    condition = alltrue(flatten([
      for nsg in var.network_security_groups : [
        for r in nsg.rules :
        contains(["Inbound", "Outbound"], r.direction) && contains(["Allow", "Deny"], r.access)
      ]
    ]))
    error_message = "Rule direction must be Inbound/Outbound and access must be Allow/Deny."
  }
}
