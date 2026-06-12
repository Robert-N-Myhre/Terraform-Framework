# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
# ---------------------------------------------------------------------------
variable "prefix" {
  type        = string
  description = "Short organization or project prefix. First token of every resource name: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, test, prod). Used in resource names."
}

variable "owner" {
  type        = string
  description = "Team or individual that owns the deployed resources. Retained for convention parity (security policies are not labelable)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Retained for convention parity (security policies are not labelable)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Retained for convention parity; Cloud Armor security policies do not support labels."
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
variable "project_id" {
  type        = string
  description = "GCP project ID owning the security policy."
}

variable "default_action" {
  type        = string
  description = "Action of the lowest-priority default rule: 'allow' or 'deny(403)' / 'deny(404)' / 'deny(502)'."
  default     = "allow"
}

variable "rules" {
  type = map(object({
    priority    = number # unique; lower wins; 2147483647 reserved for default
    action      = string # "allow" | "deny(403)" | "deny(404)" | "deny(502)" | "throttle" | "redirect"
    description = optional(string)

    # Exactly one match style per rule:
    src_ip_ranges = optional(list(string), []) # basic IP match (max 10 ranges/rule)
    expression    = optional(string)           # CEL expression, e.g. preconfigured WAF:
    # "evaluatePreconfiguredWaf('sqli-v33-stable')"

    preview = optional(bool, false) # log-only mode

    rate_limit = optional(object({
      count_per_interval = number
      interval_sec       = number
      ban_duration_sec   = optional(number)
      conform_action     = optional(string, "allow")
      exceed_action      = optional(string, "deny(429)")
      enforce_on_key     = optional(string, "IP")
    }))
  }))
  description = <<-EOT
    Map of Cloud Armor rules keyed by logical name. Use src_ip_ranges for
    simple IP allow/deny, or expression for CEL / preconfigured WAF rules
    (SQLi, XSS, LFI, etc). action = "throttle" requires rate_limit. preview
    = true evaluates and logs without enforcing.
  EOT

  validation {
    condition = alltrue([
      for r in var.rules : (length(r.src_ip_ranges) > 0) != (r.expression != null)
    ])
    error_message = "Each rule must set exactly one of src_ip_ranges or expression."
  }

  validation {
    condition = alltrue([
      for r in var.rules : r.action != "throttle" || r.rate_limit != null
    ])
    error_message = "throttle rules require a rate_limit block."
  }
}

variable "adaptive_protection_enabled" {
  type        = bool
  description = "Enable Adaptive Protection (ML-based L7 DDoS detection)."
  default     = false
}

variable "json_parsing" {
  type        = string
  description = "JSON parsing for WAF inspection: DISABLED or STANDARD."
  default     = "DISABLED"
}

variable "log_level" {
  type        = string
  description = "Logging verbosity: NORMAL or VERBOSE."
  default     = "NORMAL"
}
