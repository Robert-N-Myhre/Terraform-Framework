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
variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group for the load balancer."
}

variable "location" {
  type        = string
  description = "Azure region for the load balancer."
}

variable "frontend_type" {
  type        = string
  description = "Frontend type: 'public' creates a Standard public IP; 'internal' binds to subnet_id with an optional static private IP."
  default     = "internal"

  validation {
    condition     = contains(["public", "internal"], var.frontend_type)
    error_message = "frontend_type must be \"public\" or \"internal\"."
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the internal frontend. Required when frontend_type = 'internal'."
  default     = null
}

variable "private_ip_address" {
  type        = string
  description = "Static private IP for the internal frontend. Null = dynamic allocation."
  default     = null
}

variable "zones" {
  type        = list(string)
  description = "Availability zones for the frontend (e.g., [\"1\", \"2\", \"3\"] for zone-redundant). Empty = regional."
  default     = []
}

variable "backend_pools" {
  type        = set(string)
  description = "Logical names of backend address pools to create. Pool membership (NIC association or address-based) is the consumer's responsibility."
}

variable "health_probes" {
  type = map(object({
    port                = number
    protocol            = optional(string, "Tcp") # Tcp | Http | Https
    request_path        = optional(string)        # Http/Https only
    interval_in_seconds = optional(number, 15)
    number_of_probes    = optional(number, 2)
  }))
  description = "Health probes keyed by logical name."
  default     = {}
}

variable "rules" {
  type = map(object({
    frontend_port           = number
    backend_port            = number
    protocol                = optional(string, "Tcp") # Tcp | Udp | All
    backend_pool_key        = string
    probe_key               = optional(string)
    enable_floating_ip      = optional(bool, false)
    idle_timeout_in_minutes = optional(number, 4)
    load_distribution       = optional(string, "Default") # Default | SourceIP | SourceIPProtocol
    disable_outbound_snat   = optional(bool, true)        # prefer explicit outbound rules
  }))
  description = "Load balancing rules keyed by logical name, referencing backend pools and probes by logical key."
  default     = {}
}

variable "outbound_rules" {
  type = map(object({
    backend_pool_key         = string
    protocol                 = optional(string, "All")
    allocated_outbound_ports = optional(number, 1024)
    idle_timeout_in_minutes  = optional(number, 4)
  }))
  description = "Explicit outbound SNAT rules (public frontend only). Preferred over implicit outbound SNAT."
  default     = {}
}
