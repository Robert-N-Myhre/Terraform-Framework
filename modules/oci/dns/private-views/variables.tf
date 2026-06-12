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
  description = "OCID of the compartment for the views and zones."
}

variable "views" {
  type = map(object({
    zones = optional(map(object({
      domain_name = string # e.g. "prod.internal.example.com"
      records = optional(map(object({
        name  = string # relative or FQDN within the zone
        type  = string # A, AAAA, CNAME, TXT, MX, SRV, PTR
        ttl   = optional(number, 300)
        rdata = list(string)
      })), {})
    })), {})
  }))
  description = <<-EOT
    Map of private DNS views keyed by logical name, each containing private
    zones with optional records. Views are resolution scopes: attach a view
    to a VCN resolver (oci/dns/resolver module, or any other means) to make
    its zones resolvable from that VCN. Zones here are scope = PRIVATE.
  EOT
}
