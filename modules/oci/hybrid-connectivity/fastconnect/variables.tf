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
  description = "OCID of the compartment for the virtual circuits."
}

variable "drg_id" {
  type        = string
  description = "OCID of the DRG terminating private virtual circuits. Supplied by OCID — no framework dependency is implied."
}

variable "virtual_circuits" {
  type = map(object({
    bandwidth_shape_name = string                      # e.g. "1 Gbps", "10 Gbps" — provider-specific shape names
    circuit_type         = optional(string, "PRIVATE") # PRIVATE (to DRG) | PUBLIC

    # Partner (provider) model:
    provider_service_id = optional(string) # FastConnect partner service OCID

    # Dedicated (colocation) model:
    cross_connect_mappings = optional(map(object({
      cross_connect_or_cross_connect_group_id = string
      vlan                                    = number
      customer_bgp_peering_ip                 = optional(string) # "10.0.0.18/31"
      oracle_bgp_peering_ip                   = optional(string) # "10.0.0.19/31"
    })), {})

    customer_asn = number
    # PUBLIC circuits advertise these prefixes instead of peering privately:
    public_prefixes = optional(list(string), [])
  }))
  description = <<-EOT
    Virtual circuits keyed by logical name. Use provider_service_id for the
    partner model (provider completes their side out-of-band) or
    cross_connect_mappings for the dedicated colocation model. PRIVATE
    circuits attach to the DRG; PUBLIC circuits advertise public_prefixes.
  EOT

  validation {
    condition     = alltrue([for vc in var.virtual_circuits : contains(["PRIVATE", "PUBLIC"], vc.circuit_type)])
    error_message = "circuit_type must be PRIVATE or PUBLIC."
  }

  validation {
    condition = alltrue([
      for vc in var.virtual_circuits :
      vc.circuit_type != "PUBLIC" || length(vc.public_prefixes) > 0
    ])
    error_message = "PUBLIC circuits require at least one public prefix."
  }
}
