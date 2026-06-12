# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
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
  description = "Team or individual that owns the deployed resources. Retained for convention parity (network peerings are not labelable)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Retained for convention parity (network peerings are not labelable)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Retained for convention parity; VPC network peerings do not support labels."
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
    network_a_self_link = string
    network_b_self_link = string

    a_to_b = optional(object({
      export_custom_routes                = optional(bool, false)
      import_custom_routes                = optional(bool, false)
      export_subnet_routes_with_public_ip = optional(bool, true)
      import_subnet_routes_with_public_ip = optional(bool, false)
    }), {})
    b_to_a = optional(object({
      export_custom_routes                = optional(bool, false)
      import_custom_routes                = optional(bool, false)
      export_subnet_routes_with_public_ip = optional(bool, true)
      import_subnet_routes_with_public_ip = optional(bool, false)
    }), {})
  }))
  description = <<-EOT
    Map of VPC peering pairs keyed by logical name. GCP requires a peering
    resource on EACH network (this module creates both); the connection
    activates only when both exist. Subnet ranges must not overlap.
    export/import_custom_routes propagate static/dynamic routes (e.g., to
    share a hub's VPN routes with a spoke).
  EOT
}
