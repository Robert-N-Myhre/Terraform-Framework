# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
#
# Note: VNet peerings are not taggable in Azure; governance variables are
# still required for naming-convention compliance and forward compatibility.
# ---------------------------------------------------------------------------
variable "prefix" {
  type        = string
  description = "Short organization or project prefix. First token of every resource name: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, test, prod). Used in resource names."
}

variable "owner" {
  type        = string
  description = "Team or individual that owns the deployed resources. Retained for convention parity (peerings are not taggable)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Retained for convention parity (peerings are not taggable)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Retained for convention parity; Azure VNet peerings do not support tags."
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
variable "peerings" {
  type = map(object({
    # Side A (the VNet whose subscription/RG this provider manages)
    vnet_a_name                = string
    vnet_a_resource_group_name = string
    vnet_a_id                  = string
    # Side B
    vnet_b_name                = string
    vnet_b_resource_group_name = string
    vnet_b_id                  = string

    a_to_b = optional(object({
      allow_forwarded_traffic = optional(bool, false)
      allow_gateway_transit   = optional(bool, false)
      use_remote_gateways     = optional(bool, false)
    }), {})
    b_to_a = optional(object({
      allow_forwarded_traffic = optional(bool, false)
      allow_gateway_transit   = optional(bool, false)
      use_remote_gateways     = optional(bool, false)
    }), {})
  }))
  description = <<-EOT
    Map of VNet peering pairs keyed by logical name. Azure peering is two
    one-way resources; this module creates both directions. Both VNets must
    be reachable by the configured provider (same tenant; cross-subscription
    works with sufficient RBAC). allow_gateway_transit on one side pairs
    with use_remote_gateways on the other — never both on the same side.
  EOT

  validation {
    condition = alltrue([
      for p in var.peerings :
      !(p.a_to_b.allow_gateway_transit && p.a_to_b.use_remote_gateways) &&
      !(p.b_to_a.allow_gateway_transit && p.b_to_a.use_remote_gateways)
    ])
    error_message = "allow_gateway_transit and use_remote_gateways cannot both be true on the same peering direction."
  }
}
