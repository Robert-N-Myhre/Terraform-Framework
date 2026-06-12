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
  description = "Team or individual that owns the deployed resources. Retained for convention parity (firewall policies are not labelable)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Retained for convention parity (firewall policies are not labelable)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Retained for convention parity; hierarchical firewall policies do not support labels."
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
variable "parent_node" {
  type        = string
  description = "Organization or folder node the policy attaches under, in 'organizations/<id>' or 'folders/<id>' form. Requires org-level security admin IAM."

  validation {
    condition     = can(regex("^(organizations|folders)/\\d+$", var.parent_node))
    error_message = "parent_node must look like organizations/123456789 or folders/123456789."
  }
}

variable "policy_description" {
  type        = string
  description = "Human-readable description of the hierarchical firewall policy."
  default     = "Managed by Terraform"
}

variable "rules" {
  type = map(object({
    priority    = number # unique within the policy; lower wins
    direction   = string # "INGRESS" | "EGRESS"
    action      = string # "allow" | "deny" | "goto_next"
    description = optional(string)

    src_ip_ranges  = optional(list(string), [])
    dest_ip_ranges = optional(list(string), [])

    layer4_configs = list(object({
      ip_protocol = string
      ports       = optional(list(string), [])
    }))

    target_service_accounts = optional(list(string), [])
    enable_logging          = optional(bool, false)
  }))
  description = <<-EOT
    Map of hierarchical firewall rules keyed by logical name. Rules evaluate
    BEFORE VPC-level rules in every project under parent_node; 'goto_next'
    delegates the decision downward. Hierarchical rules cannot target
    network tags — only service accounts.
  EOT

  validation {
    condition = alltrue([
      for r in var.rules : contains(["allow", "deny", "goto_next"], r.action)
    ])
    error_message = "action must be allow, deny, or goto_next."
  }
}

variable "associations" {
  type        = map(string)
  description = "Map of logical association name to org/folder node ('organizations/<id>' or 'folders/<id>') where the policy is enforced."
  default     = {}
}
