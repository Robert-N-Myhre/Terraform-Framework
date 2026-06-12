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
variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to create the network ACLs. Supplied by ID — no framework dependency is implied."
}

variable "network_acls" {
  type = map(object({
    subnet_ids = optional(list(string), [])
    ingress_rules = optional(map(object({
      rule_number = number
      protocol    = string # "tcp" | "udp" | "icmp" | "-1"
      action      = string # "allow" | "deny"
      cidr_block  = optional(string)
      from_port   = optional(number)
      to_port     = optional(number)
      icmp_type   = optional(number)
      icmp_code   = optional(number)
    })), {})
    egress_rules = optional(map(object({
      rule_number = number
      protocol    = string
      action      = string
      cidr_block  = optional(string)
      from_port   = optional(number)
      to_port     = optional(number)
      icmp_type   = optional(number)
      icmp_code   = optional(number)
    })), {})
  }))
  description = <<-EOT
    Map of network ACLs keyed by logical name. Each ACL carries ingress and
    egress rule maps and an optional list of subnet IDs to associate. NACLs
    are STATELESS — return traffic must be explicitly allowed (typically an
    ephemeral-port range rule 1024-65535). Rule numbers must be unique per
    direction within an ACL; lower numbers evaluate first.
  EOT

  validation {
    condition = alltrue(flatten([
      for acl in var.network_acls : [
        for r in merge(acl.ingress_rules, acl.egress_rules) : contains(["allow", "deny"], r.action)
      ]
    ]))
    error_message = "Every NACL rule action must be \"allow\" or \"deny\"."
  }
}
