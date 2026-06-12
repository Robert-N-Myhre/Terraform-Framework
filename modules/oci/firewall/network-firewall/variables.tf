# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
# ---------------------------------------------------------------------------
variable "prefix" {
  type        = string
  description = "Short organization or project prefix. First token of every resource name: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, test, prod). Used in resource names and mandatory freeform tags."
}

variable "owner" {
  type        = string
  description = "Team or individual that owns the deployed resources. Applied as the mandatory 'owner' freeform tag."
}

variable "cost_center" {
  type        = string
  description = "Cost center code for chargeback/showback. Applied as the mandatory 'cost_center' freeform tag."
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional additional freeform tags merged beneath the mandatory tag set. Mandatory tags win on key collision."
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
variable "compartment_id" {
  type        = string
  description = "OCID of the compartment for the firewall and policy."
}

variable "firewall_subnet_id" {
  type        = string
  description = "OCID of the subnet hosting the firewall endpoint (dedicated subnet recommended). Supplied by OCID — no framework dependency is implied."
}

variable "availability_domain" {
  type        = string
  description = "Availability domain for the firewall instance. Null lets OCI choose (regional subnet)."
  default     = null
}

variable "ipv4_address" {
  type        = string
  description = "Static private IP for the firewall in its subnet. Null = auto-assigned. Route traffic to this IP (or the auto-assigned one) via VCN route rules."
  default     = null
}

variable "address_lists" {
  type        = map(list(string))
  description = "Named IP address lists (CIDRs) referenced by security rules."
  default     = {}
}

variable "service_lists" {
  type = map(map(object({
    protocol = string # "TCP" | "UDP"
    min_port = number
    max_port = optional(number)
  })))
  description = "Named service lists: outer key = service-list name, inner key = service name with protocol and port range."
  default     = {}
}

variable "security_rules" {
  type = map(object({
    position_order            = number                     # ordering hint; rules applied in map iteration order via after/before chaining is out of scope
    action                    = string                     # "ALLOW" | "DROP" | "REJECT" | "INSPECT"
    source_address_lists      = optional(list(string), []) # names from address_lists; empty = any
    destination_address_lists = optional(list(string), [])
    service_lists             = optional(list(string), []) # names from service_lists; empty = any
  }))
  description = "Security rules keyed by logical name, referencing address and service lists by name. Default disposition for unmatched traffic is DROP."

  validation {
    condition     = alltrue([for r in var.security_rules : contains(["ALLOW", "DROP", "REJECT", "INSPECT"], r.action)])
    error_message = "action must be ALLOW, DROP, REJECT, or INSPECT."
  }
}
