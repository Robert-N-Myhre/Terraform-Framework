# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
# ---------------------------------------------------------------------------
variable "prefix" {
  type        = string
  description = "Short organization or project prefix. First token of every resource name: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, test, prod). Used in resource names and mandatory labels."
}

variable "owner" {
  type        = string
  description = "Team or individual that owns the deployed resources. Applied as the mandatory 'owner' label (lowercased)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Applied as the mandatory 'cost_center' label (lowercased)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional additional labels merged beneath the mandatory label set (lowercased)."
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
  description = "GCP project ID hosting the NCC hub."
}

variable "hub_description" {
  type        = string
  description = "Human-readable description of the hub."
  default     = "Managed by Terraform"
}

variable "vpc_spokes" {
  type = map(object({
    vpc_self_link         = string
    exclude_export_ranges = optional(list(string), [])
  }))
  description = "VPC-network spokes keyed by logical name. Full-mesh subnet reachability between all VPC spokes on the hub."
  default     = {}
}

variable "hybrid_spokes" {
  type = map(object({
    location                   = string # region of the tunnels/attachments
    type                       = string # "vpn" | "interconnect"
    uris                       = list(string) # tunnel or VLAN-attachment self-links
    site_to_site_data_transfer = optional(bool, true)
  }))
  description = "Hybrid spokes (HA VPN tunnels or Interconnect VLAN attachments) keyed by logical name. site_to_site_data_transfer enables branch-to-branch through Google's backbone."
  default     = {}

  validation {
    condition     = alltrue([for s in var.hybrid_spokes : contains(["vpn", "interconnect"], s.type)])
    error_message = "hybrid spoke type must be \"vpn\" or \"interconnect\"."
  }
}
