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
  description = "OCID of the compartment for the DRG."
}

variable "drg_route_tables" {
  type        = set(string)
  description = "Logical names of custom DRG route tables to create (e.g., [\"prod\", \"shared\", \"inspection\"])."
  default     = []
}

variable "vcn_attachments" {
  type = map(object({
    vcn_id              = string
    drg_route_table_key = optional(string) # custom DRG RT this attachment uses
    # Optional VCN-side route table for advanced/transit routing scenarios:
    vcn_route_table_id = optional(string)
  }))
  description = "VCN attachments keyed by logical name. drg_route_table_key assigns a custom DRG route table created by this module."
  default     = {}
}

variable "static_routes" {
  type = map(object({
    drg_route_table_key     = string
    destination_cidr        = string
    next_hop_attachment_key = string # logical key from vcn_attachments
  }))
  description = "Static DRG routes keyed by logical name, pointing a CIDR at a VCN attachment."
  default     = {}
}

variable "remote_peering_connections" {
  type = map(object({
    # Set peer fields on ONE side only; leave null on the accepting side.
    peer_rpc_id      = optional(string)
    peer_region_name = optional(string)
  }))
  description = "Remote peering connections (cross-region DRG-to-DRG) keyed by logical name. The initiating side sets peer_rpc_id + peer_region_name; the accepting side leaves both null."
  default     = {}
}
