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
variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group for the private DNS zones."
}

variable "private_zones" {
  type = map(object({
    domain_name = string # e.g. "prod.internal.example.com" or "privatelink.blob.core.windows.net"
    vnet_links = optional(map(object({
      vnet_id              = string
      registration_enabled = optional(bool, false) # auto-register VM records
    })), {})
    a_records = optional(map(object({
      name    = string
      ttl     = optional(number, 300)
      records = list(string)
    })), {})
    cname_records = optional(map(object({
      name   = string
      ttl    = optional(number, 300)
      record = string
    })), {})
    txt_records = optional(map(object({
      name    = string
      ttl     = optional(number, 300)
      records = list(string)
    })), {})
  }))
  description = <<-EOT
    Map of private DNS zones keyed by logical name. Unlike AWS, an Azure
    private zone can exist with zero VNet links; resolution only works from
    linked VNets. registration_enabled auto-creates records for VMs in the
    linked VNet (max one registration link per VNet).
  EOT
}
