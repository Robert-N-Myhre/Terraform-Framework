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
variable "private_zones" {
  type = map(object({
    domain_name = string
    comment     = optional(string, "Managed by Terraform")
    vpc_associations = list(object({
      vpc_id     = string
      vpc_region = optional(string) # defaults to provider region
    }))
    records = optional(map(object({
      name    = string # relative or FQDN within the zone
      type    = string # A, AAAA, CNAME, TXT, MX, SRV, PTR, NS
      ttl     = optional(number, 300)
      values  = list(string)
    })), {})
  }))
  description = <<-EOT
    Map of private hosted zones keyed by logical name. Each zone requires at
    least one VPC association (Route 53 private zones cannot exist without
    one) and may define a map of records. Cross-account VPC associations are
    out of scope — use aws_route53_vpc_association_authorization in the
    consumer root module for that pattern.
  EOT

  validation {
    condition     = alltrue([for z in var.private_zones : length(z.vpc_associations) > 0])
    error_message = "Each private zone must declare at least one VPC association."
  }
}
