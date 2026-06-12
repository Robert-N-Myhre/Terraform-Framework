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
  description = "ID of the VPC in which the firewall endpoints are created. Supplied by ID — no framework dependency is implied."
}

variable "firewall_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs (one per AZ recommended) dedicated to AWS Network Firewall endpoints. Must not host other workloads."

  validation {
    condition     = length(var.firewall_subnet_ids) > 0
    error_message = "At least one firewall subnet ID is required."
  }
}

variable "stateless_rule_groups" {
  type = map(object({
    capacity = number
    priority = number
    rules = map(object({
      priority              = number
      actions               = list(string) # e.g. ["aws:pass"], ["aws:drop"], ["aws:forward_to_sfe"]
      source_cidrs          = optional(list(string), ["0.0.0.0/0"])
      destination_cidrs     = optional(list(string), ["0.0.0.0/0"])
      protocols             = optional(list(number), []) # IANA numbers; empty = all
      source_port_from      = optional(number)
      source_port_to        = optional(number)
      destination_port_from = optional(number)
      destination_port_to   = optional(number)
    }))
  }))
  description = "Stateless rule groups keyed by logical name. capacity is the AWS rule-group capacity reservation; priority orders groups inside the policy."
  default     = {}
}

variable "stateful_rule_groups" {
  type = map(object({
    capacity     = number
    priority     = number
    rules_string = string # Suricata-compatible rules
  }))
  description = "Stateful rule groups keyed by logical name, expressed as Suricata-compatible rules_string. Policy uses STRICT_ORDER evaluation; priority orders groups."
  default     = {}
}

variable "stateless_default_actions" {
  type        = list(string)
  description = "Default actions for full packets that match no stateless rule (e.g., [\"aws:forward_to_sfe\"] to hand off to the stateful engine)."
  default     = ["aws:forward_to_sfe"]
}

variable "stateless_fragment_default_actions" {
  type        = list(string)
  description = "Default actions for fragmented packets that match no stateless rule."
  default     = ["aws:forward_to_sfe"]
}

variable "stateful_default_actions" {
  type        = list(string)
  description = "Default actions for the stateful engine under STRICT_ORDER (e.g., [\"aws:drop_strict\"] for default-deny, [\"aws:alert_established\"] for monitor mode)."
  default     = ["aws:drop_strict", "aws:alert_strict"]
}

variable "delete_protection" {
  type        = bool
  description = "Enable deletion protection on the firewall (governance/resource-locks). Must be set false and applied before the firewall can be destroyed."
  default     = true
}

variable "subnet_change_protection" {
  type        = bool
  description = "Prevent endpoint subnet changes on the firewall."
  default     = true
}

variable "policy_change_protection" {
  type        = bool
  description = "Prevent the firewall policy association from being changed."
  default     = false
}

variable "enable_logging" {
  type        = bool
  description = "Whether to send ALERT and FLOW logs to module-managed CloudWatch log groups."
  default     = false
}

variable "log_retention_days" {
  type        = number
  description = "Retention period in days for firewall CloudWatch log groups."
  default     = 30
}
