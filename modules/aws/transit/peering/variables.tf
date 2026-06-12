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
variable "peerings" {
  type = map(object({
    requester_vpc_id               = string
    accepter_vpc_id                = string
    peer_region                    = optional(string)     # set for cross-region peering
    auto_accept                    = optional(bool, true) # same-account, same-region only
    allow_requester_dns_resolution = optional(bool, true)
    allow_accepter_dns_resolution  = optional(bool, true)
    # Route injection: route table IDs on each side and the CIDR of the
    # opposite VPC. Omit (empty) if the consumer manages routes elsewhere.
    requester_route_table_ids  = optional(list(string), [])
    requester_destination_cidr = optional(string)
    accepter_route_table_ids   = optional(list(string), [])
    accepter_destination_cidr  = optional(string)
  }))
  description = <<-EOT
    Map of VPC peering connections keyed by logical name. auto_accept only
    works for same-account, same-region peering; cross-region peering is
    accepted by the accepter resource in this module (same account), and
    cross-account peering requires a provider alias in the consumer root —
    out of scope here. Route injection is optional per side.
  EOT

  validation {
    condition = alltrue([
      for p in var.peerings :
      (length(p.requester_route_table_ids) == 0 || p.requester_destination_cidr != null) &&
      (length(p.accepter_route_table_ids) == 0 || p.accepter_destination_cidr != null)
    ])
    error_message = "When route table IDs are given for a side, the corresponding destination CIDR must also be set."
  }
}
