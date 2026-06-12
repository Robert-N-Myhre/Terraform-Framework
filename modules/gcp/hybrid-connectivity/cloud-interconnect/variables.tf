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
  description = "Team or individual that owns the deployed resources. Applied as the mandatory 'owner' label where supported (lowercased)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Applied as the mandatory 'cost_center' label where supported (lowercased)."
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
  description = "GCP project ID hosting the attachments."
}

variable "region" {
  type        = string
  description = "Region of the Cloud Router and attachments."
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the VPC network. Supplied as a plain value — no framework dependency is implied."
}

variable "router_asn" {
  type        = number
  description = "Google-side BGP ASN for the Cloud Router. Partner attachments commonly require 16550."
  default     = 16550
}

variable "attachments" {
  type = map(object({
    type = string # "PARTNER" | "DEDICATED"

    # PARTNER: pairing key is generated; hand it to the provider.
    edge_availability_domain = optional(string, "AVAILABILITY_DOMAIN_1") # PARTNER only

    # DEDICATED: reference the physical interconnect + VLAN.
    interconnect_self_link = optional(string) # DEDICATED only
    vlan_tag               = optional(number) # DEDICATED only
    candidate_subnets      = optional(list(string), []) # /29 link-local candidates
    bandwidth              = optional(string, "BPS_1G")  # DEDICATED only

    admin_enabled = optional(bool, true)

    # BGP session (DEDICATED; for PARTNER the partner sets the session up)
    bgp = optional(object({
      session_range = string # GCP-side /29 link-local
      peer_ip       = string
      peer_asn      = number
    }))
  }))
  description = <<-EOT
    Interconnect VLAN attachments keyed by logical name. PARTNER attachments
    output a pairing_key for the service provider and the BGP session is
    established by the partner. DEDICATED attachments reference a physical
    interconnect (ordered out-of-band) and define their own BGP session.
  EOT

  validation {
    condition     = alltrue([for a in var.attachments : contains(["PARTNER", "DEDICATED"], a.type)])
    error_message = "attachment type must be PARTNER or DEDICATED."
  }

  validation {
    condition = alltrue([
      for a in var.attachments :
      a.type != "DEDICATED" || (a.interconnect_self_link != null && a.vlan_tag != null)
    ])
    error_message = "DEDICATED attachments require interconnect_self_link and vlan_tag."
  }
}
