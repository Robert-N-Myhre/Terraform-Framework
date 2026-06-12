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
variable "amazon_side_asn" {
  type        = number
  description = "Private ASN for the Amazon side of BGP sessions (64512-65534 for 16-bit). Must not collide with on-premises or other cloud ASNs in the routing domain."
  default     = 64512
}

variable "description" {
  type        = string
  description = "Human-readable description of the transit gateway."
  default     = "Managed by Terraform"
}

variable "enable_default_route_table_association" {
  type        = bool
  description = "Automatically associate new attachments with the default TGW route table. Set false for segmented (multi-route-table) topologies."
  default     = false
}

variable "enable_default_route_table_propagation" {
  type        = bool
  description = "Automatically propagate routes from new attachments into the default TGW route table. Set false for segmented topologies."
  default     = false
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS support on the transit gateway."
  default     = true
}

variable "enable_vpn_ecmp_support" {
  type        = bool
  description = "Enable equal-cost multi-path routing across VPN attachments."
  default     = true
}

variable "auto_accept_shared_attachments" {
  type        = bool
  description = "Auto-accept attachment requests from accounts sharing via RAM."
  default     = false
}

variable "vpc_attachments" {
  type = map(object({
    vpc_id          = string
    subnet_ids      = list(string)
    appliance_mode  = optional(bool, false)
    dns_support     = optional(bool, true)
    route_table_key = optional(string)           # association target (custom RT key)
    propagate_to    = optional(list(string), []) # custom RT keys to propagate into
  }))
  description = "VPC attachments keyed by logical name. route_table_key associates the attachment with a custom route table defined in route_tables; propagate_to lists route table keys that learn this attachment's routes."
  default     = {}
}

variable "route_tables" {
  type        = set(string)
  description = "Logical names of custom TGW route tables to create (e.g., [\"prod\", \"shared\", \"inspection\"])."
  default     = []
}

variable "static_routes" {
  type = map(object({
    route_table_key  = string
    destination_cidr = string
    attachment_key   = optional(string) # null + blackhole=true for blackhole
    blackhole        = optional(bool, false)
  }))
  description = "Static TGW routes keyed by logical name. Point destination_cidr at an attachment or blackhole it."
  default     = {}

  validation {
    condition = alltrue([
      for r in var.static_routes : r.blackhole || r.attachment_key != null
    ])
    error_message = "Each static route must either set attachment_key or blackhole = true."
  }
}
