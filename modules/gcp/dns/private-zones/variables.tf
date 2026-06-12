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
  description = "Cost center code for chargeback/showback. Applied as the mandatory 'cost_center' label (lowercased)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional additional labels merged beneath the mandatory label set (lowercased). Mandatory labels win on key collision."
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
  description = "GCP project ID owning the DNS zones."
}

variable "private_zones" {
  type = map(object({
    domain_name        = string # MUST end with a dot, e.g. "prod.internal.example.com."
    description        = optional(string, "Managed by Terraform")
    network_self_links = list(string) # VPCs that can resolve the zone

    # Optional: turn the zone into a forwarding zone (queries go to targets)
    forwarding_targets = optional(list(object({
      ipv4_address    = string
      forwarding_path = optional(string, "default") # default | private
    })), [])

    # Optional: peer the zone to another VPC's DNS namespace
    peering_network_self_link = optional(string)

    records = optional(map(object({
      name    = string # relative name; "" or "@" for apex
      type    = string # A, AAAA, CNAME, TXT, MX, SRV, PTR
      ttl     = optional(number, 300)
      rrdatas = list(string)
    })), {})
  }))
  description = <<-EOT
    Map of private managed zones keyed by logical name. domain_name requires
    a trailing dot. A zone may be a plain private zone (records), a
    forwarding zone (forwarding_targets), or a peering zone
    (peering_network_self_link) — these modes are mutually exclusive per
    GCP API.
  EOT

  validation {
    condition     = alltrue([for z in var.private_zones : endswith(z.domain_name, ".")])
    error_message = "Each domain_name must end with a trailing dot (e.g., \"prod.internal.example.com.\")."
  }

  validation {
    condition = alltrue([
      for z in var.private_zones :
      !(length(z.forwarding_targets) > 0 && z.peering_network_self_link != null)
    ])
    error_message = "A zone cannot be both a forwarding zone and a peering zone."
  }
}
