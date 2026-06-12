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
variable "resolver_id" {
  type        = string
  description = "OCID of the VCN's implicit DNS resolver (from the VCN's 'dns_resolver_association' / data source oci_core_vcn_dns_resolver_association). OCI creates this with the VCN; this module manages it."
}

variable "attached_view_ids" {
  type        = list(string)
  description = "DNS view OCIDs to attach to the resolver (e.g., outputs of oci/dns/private-views). Order matters: earlier views win on conflicting names."
  default     = []
}

variable "listening_endpoints" {
  type = map(object({
    subnet_id          = string
    listening_address  = optional(string) # null = auto from subnet
    nsg_ids            = optional(list(string), [])
  }))
  description = "Listening endpoints keyed by logical name (on-premises -> VCN resolution; OCI's analogue of an inbound resolver endpoint)."
  default     = {}
}

variable "forwarding_endpoints" {
  type = map(object({
    subnet_id          = string
    forwarding_address = optional(string) # null = auto from subnet
    nsg_ids            = optional(list(string), [])
  }))
  description = "Forwarding endpoints keyed by logical name (VCN -> on-premises resolution; OCI's analogue of an outbound resolver endpoint)."
  default     = {}
}

variable "forward_rules" {
  type = map(object({
    domain_names             = list(string) # e.g. ["corp.example.com"]
    forwarding_endpoint_key  = string       # logical key from forwarding_endpoints
    destination_addresses    = list(string) # on-prem DNS server IPs
  }))
  description = "Conditional forwarding rules keyed by logical name: matching queries exit via the named forwarding endpoint to the destination addresses."
  default     = {}
}
