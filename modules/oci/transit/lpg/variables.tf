# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
# ---------------------------------------------------------------------------
variable "prefix" {
  type        = string
  description = "Short organization or project prefix. First token of every resource name: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, test, prod). Used in resource names and mandatory freeform tags."
}

variable "owner" {
  type        = string
  description = "Team or individual that owns the deployed resources. Applied as the mandatory 'owner' freeform tag."
}

variable "cost_center" {
  type        = string
  description = "Cost center code for chargeback/showback. Applied as the mandatory 'cost_center' freeform tag."
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional additional freeform tags merged beneath the mandatory tag set. Mandatory tags win on key collision."
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
variable "compartment_id" {
  type        = string
  description = "OCID of the compartment for the LPGs."
}

variable "peerings" {
  type = map(object({
    vcn_a_id = string
    vcn_b_id = string
    # Optional route table to associate with each LPG (for transit routing
    # through the peering); null uses the VCN default behavior.
    lpg_a_route_table_id = optional(string)
    lpg_b_route_table_id = optional(string)
  }))
  description = <<-EOT
    Map of same-region VCN peering pairs keyed by logical name. Two LPGs are
    created per pair (one in each VCN) and connected by setting peer_id on
    side A. Both VCNs must be reachable by the configured provider identity
    (cross-tenancy LPG peering requires IAM policy + provider aliases — out
    of scope). VCN CIDRs must not overlap.
  EOT
}
