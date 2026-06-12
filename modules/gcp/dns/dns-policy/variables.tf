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
  description = "Team or individual that owns the deployed resources. Retained for convention parity (DNS policies are not labelable)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Retained for convention parity (DNS policies are not labelable)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Retained for convention parity; DNS policies do not support labels."
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
variable "project_id" {
  type        = string
  description = "GCP project ID owning the DNS policy."
}

variable "network_self_links" {
  type        = list(string)
  description = "Self-links of the VPC networks the policy attaches to. Only ONE DNS policy may exist per network — coordinate ownership."

  validation {
    condition     = length(var.network_self_links) > 0
    error_message = "At least one network self-link is required."
  }
}

variable "enable_inbound_forwarding" {
  type        = bool
  description = "Allocate inbound forwarder IPs in each attached network so on-premises resolvers can query Cloud DNS (GCP's analogue of an inbound resolver endpoint)."
  default     = false
}

variable "enable_logging" {
  type        = bool
  description = "Enable query logging for the attached networks."
  default     = false
}

variable "alternative_name_servers" {
  type = list(object({
    ipv4_address    = string
    forwarding_path = optional(string, "default") # default | private
  }))
  description = "Alternative name servers — ALL queries from attached networks (except Compute internal names) forward to these instead of Cloud DNS. Use sparingly; per-domain forwarding belongs in forwarding zones."
  default     = []
}
