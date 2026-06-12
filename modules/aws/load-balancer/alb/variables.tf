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
  description = "ID of the VPC hosting the load balancer and target groups. Supplied by ID — no framework dependency is implied."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the ALB (at least two, in different AZs)."

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "An ALB requires at least two subnets in different availability zones."
  }
}

variable "internal" {
  type        = bool
  description = "Whether the ALB is internal (true) or internet-facing (false)."
  default     = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs attached to the ALB."
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection on the ALB (governance/resource-locks). Must be disabled and applied before destroy."
  default     = true
}

variable "drop_invalid_header_fields" {
  type        = bool
  description = "Drop HTTP headers with invalid fields (security hardening)."
  default     = true
}

variable "idle_timeout" {
  type        = number
  description = "Connection idle timeout in seconds."
  default     = 60
}

variable "access_logs" {
  type = object({
    enabled = bool
    bucket  = optional(string)
    prefix  = optional(string)
  })
  description = "ALB access log configuration. When enabled, bucket must be an existing S3 bucket with the proper ELB log-delivery policy."
  default     = { enabled = false }
}

variable "target_groups" {
  type = map(object({
    port                 = number
    protocol             = string # HTTP | HTTPS
    target_type          = optional(string, "instance") # instance | ip | lambda | alb
    deregistration_delay = optional(number, 300)
    health_check = optional(object({
      path                = optional(string, "/")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      timeout             = optional(number, 5)
      interval            = optional(number, 30)
      matcher             = optional(string, "200-299")
    }), {})
    stickiness = optional(object({
      enabled         = bool
      type            = optional(string, "lb_cookie")
      cookie_duration = optional(number, 86400)
    }))
  }))
  description = "Target groups keyed by logical name. Target registration is the consumer's responsibility (ASG attachment, ECS service, or aws_lb_target_group_attachment in the root module)."
}

variable "listeners" {
  type = map(object({
    port             = number
    protocol         = string # HTTP | HTTPS
    certificate_arn  = optional(string) # required for HTTPS
    ssl_policy       = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    default_action   = object({
      type             = string # "forward" | "redirect" | "fixed-response"
      target_group_key = optional(string) # forward: logical key in target_groups
      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
      }))
      fixed_response = optional(object({
        content_type = optional(string, "text/plain")
        message_body = optional(string, "")
        status_code  = optional(string, "404")
      }))
    })
    rules = optional(map(object({
      priority         = number
      target_group_key = string
      path_patterns    = optional(list(string), [])
      host_headers     = optional(list(string), [])
    })), {})
  }))
  description = "Listeners keyed by logical name with a default action and optional path/host routing rules."

  validation {
    condition = alltrue([
      for l in var.listeners : l.protocol != "HTTPS" || l.certificate_arn != null
    ])
    error_message = "HTTPS listeners require certificate_arn."
  }
}
