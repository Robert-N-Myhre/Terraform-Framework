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
  description = "ID of the VPC in which to create the security groups. May come from any source (this framework's core-network module, an existing VPC, a data source) — no framework dependency is implied."
}

variable "security_groups" {
  type = map(object({
    description = string
    ingress_rules = optional(map(object({
      description                   = optional(string)
      from_port                     = optional(number)
      to_port                       = optional(number)
      ip_protocol                   = string # "tcp" | "udp" | "icmp" | "-1"
      cidr_ipv4                     = optional(string)
      cidr_ipv6                     = optional(string)
      referenced_security_group_key = optional(string) # logical key of another SG in this map
      referenced_security_group_id  = optional(string) # external SG ID
      prefix_list_id                = optional(string)
    })), {})
    egress_rules = optional(map(object({
      description                   = optional(string)
      from_port                     = optional(number)
      to_port                       = optional(number)
      ip_protocol                   = string
      cidr_ipv4                     = optional(string)
      cidr_ipv6                     = optional(string)
      referenced_security_group_key = optional(string)
      referenced_security_group_id  = optional(string)
      prefix_list_id                = optional(string)
    })), {})
  }))
  description = <<-EOT
    Map of security groups keyed by logical name. Each group carries its own
    ingress and egress rule maps. Exactly one source/destination must be set
    per rule: cidr_ipv4, cidr_ipv6, referenced_security_group_key (another
    group in this map), referenced_security_group_id (external), or
    prefix_list_id. Use ip_protocol = "-1" for all protocols.
  EOT
}

variable "default_egress_allow_all" {
  type        = bool
  description = "When true, adds an allow-all IPv4 egress rule to every group that defines no explicit egress rules (matches the AWS console default behavior). Set false for strict egress posture."
  default     = false
}
