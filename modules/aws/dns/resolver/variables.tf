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
variable "create_inbound_endpoint" {
  type        = bool
  description = "Whether to create an inbound resolver endpoint (lets on-premises resolvers query Route 53 private zones)."
  default     = false
}

variable "inbound_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the inbound endpoint ENIs. At least two subnets in different AZs are required by AWS when the inbound endpoint is created."
  default     = []
}

variable "inbound_security_group_ids" {
  type        = list(string)
  description = "Security group IDs attached to the inbound endpoint ENIs (must allow TCP/UDP 53 from on-premises resolver ranges)."
  default     = []
}

variable "create_outbound_endpoint" {
  type        = bool
  description = "Whether to create an outbound resolver endpoint (forwards queries from the VPC to on-premises or other resolvers)."
  default     = false
}

variable "outbound_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the outbound endpoint ENIs. At least two subnets in different AZs are required by AWS when the outbound endpoint is created."
  default     = []
}

variable "outbound_security_group_ids" {
  type        = list(string)
  description = "Security group IDs attached to the outbound endpoint ENIs (must allow TCP/UDP 53 egress to target resolvers)."
  default     = []
}

variable "forwarding_rules" {
  type = map(object({
    domain_name = string
    rule_type   = optional(string, "FORWARD") # FORWARD | SYSTEM
    target_ips = optional(list(object({
      ip   = string
      port = optional(number, 53)
    })), [])
    vpc_ids = optional(list(string), []) # VPCs to associate the rule with
  }))
  description = <<-EOT
    Map of resolver rules keyed by logical name. FORWARD rules require
    target_ips and the outbound endpoint (create_outbound_endpoint = true).
    SYSTEM rules override a broader FORWARD rule to restore Route 53
    resolution for a subdomain. vpc_ids associates each rule with VPCs.
  EOT
  default     = {}

  validation {
    condition = alltrue([
      for r in var.forwarding_rules :
      r.rule_type != "FORWARD" || length(r.target_ips) > 0
    ])
    error_message = "FORWARD rules must define at least one target_ip."
  }
}

variable "query_log_destination_arn" {
  type        = string
  description = "Optional ARN of a CloudWatch log group, S3 bucket, or Kinesis Firehose for resolver query logging. Null disables query logging."
  default     = null
}

variable "query_log_vpc_ids" {
  type        = list(string)
  description = "VPC IDs to associate with the query logging configuration. Only used when query_log_destination_arn is set."
  default     = []
}
