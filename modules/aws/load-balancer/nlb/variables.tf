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
  description = "ID of the VPC hosting the NLB and target groups. Supplied by ID — no framework dependency is implied."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the NLB (one per AZ; a single subnet is permitted for an NLB, unlike an ALB)."

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID is required."
  }
}

variable "internal" {
  type        = bool
  description = "Whether the NLB is internal (true) or internet-facing (false)."
  default     = true
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs attached to the NLB. NOTE: security groups can only be attached at creation; adding them later forces replacement. Empty list = no SGs (pre-2023 behavior)."
  default     = []
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection on the NLB (governance/resource-locks). Must be disabled and applied before destroy."
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  type        = bool
  description = "Distribute traffic across targets in all enabled AZs (per-AZ data charges may apply)."
  default     = true
}

variable "target_groups" {
  type = map(object({
    port                 = number
    protocol             = string                       # TCP | UDP | TCP_UDP | TLS
    target_type          = optional(string, "instance") # instance | ip | alb
    deregistration_delay = optional(number, 300)
    preserve_client_ip   = optional(bool)
    proxy_protocol_v2    = optional(bool, false)
    health_check = optional(object({
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "TCP")
      path                = optional(string) # HTTP/HTTPS checks only
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      interval            = optional(number, 30)
    }), {})
  }))
  description = "Target groups keyed by logical name. Target registration is the consumer's responsibility."
}

variable "listeners" {
  type = map(object({
    port             = number
    protocol         = string # TCP | UDP | TCP_UDP | TLS
    target_group_key = string
    certificate_arn  = optional(string) # required for TLS
    ssl_policy       = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
  }))
  description = "Listeners keyed by logical name. NLB listeners forward to exactly one target group (no rule-based routing at L4)."

  validation {
    condition = alltrue([
      for l in var.listeners : l.protocol != "TLS" || l.certificate_arn != null
    ])
    error_message = "TLS listeners require certificate_arn."
  }
}
