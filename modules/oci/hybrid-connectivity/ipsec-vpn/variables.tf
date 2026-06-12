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
  description = "OCID of the compartment for the CPE and IPSec connections."
}

variable "drg_id" {
  type        = string
  description = "OCID of the DRG terminating the VPN. May come from any source (oci/transit/drg output, existing DRG) — no framework dependency is implied."
}

variable "customer_premises_equipment" {
  type = map(object({
    ip_address          = string # on-prem device public IP
    cpe_device_shape_id = optional(string) # device shape OCID for config helpers
  }))
  description = "CPE objects (on-premises devices) keyed by logical name."
}

variable "ipsec_connections" {
  type = map(object({
    cpe_key        = string
    static_routes  = optional(list(string), []) # on-prem CIDRs; required for STATIC tunnels, [] for BGP
    tunnels = optional(map(object({
      tunnel_index  = number # 1 or 2
      routing_type  = optional(string, "BGP") # "BGP" | "STATIC"
      shared_secret = optional(string) # null lets OCI generate
      ike_version   = optional(string, "V2")
      # BGP session (routing_type = "BGP"):
      customer_bgp_asn      = optional(string)
      oracle_interface_ip   = optional(string) # e.g. "169.254.50.1/30"
      customer_interface_ip = optional(string) # e.g. "169.254.50.2/30"
    })), {})
  }))
  description = <<-EOT
    IPSec connections keyed by logical name, each referencing a CPE. OCI
    always provisions TWO tunnels per connection; entries in tunnels
    (keyed 1:1 by tunnel_index) configure BGP/PSK per tunnel via tunnel
    management. static_routes must be non-empty when any tunnel uses
    STATIC routing.
  EOT
  sensitive   = true
}
