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
  description = "Team or individual that owns the deployed resources. Retained for convention parity (classic firewall rules are not labelable)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Retained for convention parity (classic firewall rules are not labelable)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Retained for convention parity; classic VPC firewall rules do not support labels."
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
  description = "GCP project ID owning the network and rules."
}

variable "network_name" {
  type        = string
  description = "Name (or self-link) of the VPC network the rules attach to. Supplied as a plain value — no framework dependency is implied."
}

variable "rules" {
  type = map(object({
    description = optional(string)
    direction   = string # "INGRESS" | "EGRESS"
    action      = string # "allow" | "deny"
    priority    = optional(number, 1000) # lower wins; 0-65535

    # Traffic selection — INGRESS uses source_*, EGRESS uses destination_ranges.
    source_ranges           = optional(list(string), [])
    source_tags             = optional(list(string), [])
    source_service_accounts = optional(list(string), [])
    destination_ranges      = optional(list(string), [])

    # Targets — instances the rule applies to (empty = all in network).
    target_tags             = optional(list(string), [])
    target_service_accounts = optional(list(string), [])

    # Protocols/ports for the action.
    allow_deny = list(object({
      protocol = string # "tcp" | "udp" | "icmp" | "esp" | "ah" | "sctp" | "all"
      ports    = optional(list(string), []) # ["443", "8000-8100"]
    }))

    log_enabled = optional(bool, false)
  }))
  description = <<-EOT
    Map of firewall rules keyed by logical name. GCP rules are NETWORK-GLOBAL
    and stateful; they target instances via network tags or service accounts
    (never both in one rule — GCP rejects mixing tags and service accounts).
    Implied rules: allow-egress-all and deny-ingress-all exist at priority
    65535 in every VPC.
  EOT

  validation {
    condition = alltrue([
      for r in var.rules : contains(["INGRESS", "EGRESS"], r.direction) && contains(["allow", "deny"], r.action)
    ])
    error_message = "direction must be INGRESS/EGRESS and action must be allow/deny."
  }

  validation {
    condition = alltrue([
      for r in var.rules :
      !(length(r.target_tags) > 0 && length(r.target_service_accounts) > 0)
    ])
    error_message = "A rule cannot mix target_tags and target_service_accounts (GCP API restriction)."
  }
}
