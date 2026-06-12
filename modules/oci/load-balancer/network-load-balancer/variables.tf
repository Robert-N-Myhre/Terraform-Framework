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
  description = "OCID of the compartment for the network load balancer."
}

variable "subnet_id" {
  type        = string
  description = "Subnet OCID for the NLB (single regional subnet)."
}

variable "is_private" {
  type        = bool
  description = "Whether the NLB is private (no public IP)."
  default     = true
}

variable "is_preserve_source_destination" {
  type        = bool
  description = "Preserve source/destination IPs through the NLB (transparent mode for firewalls/appliances)."
  default     = false
}

variable "nsg_ids" {
  type        = list(string)
  description = "Network security group OCIDs attached to the NLB."
  default     = []
}

variable "backend_sets" {
  type = map(object({
    policy                  = optional(string, "FIVE_TUPLE") # FIVE_TUPLE | THREE_TUPLE | TWO_TUPLE
    is_preserve_source      = optional(bool, true)
    health_checker = object({
      protocol    = string # "TCP" | "UDP" | "HTTP" | "HTTPS"
      port        = number
      url_path    = optional(string, "/")
      return_code = optional(number, 200)
      interval_ms = optional(number, 10000)
      timeout_ms  = optional(number, 3000)
      retries     = optional(number, 3)
    })
    backends = optional(map(object({
      ip_address = optional(string) # IP-based backend
      target_id  = optional(string) # OR instance OCID
      port       = number
      weight     = optional(number, 1)
    })), {})
  }))
  description = "Backend sets keyed by logical name. Hashing policy controls flow distribution (FIVE_TUPLE default)."
}

variable "listeners" {
  type = map(object({
    port                    = number # 0 with any-port backend sets for full passthrough
    protocol                = string # "TCP" | "UDP" | "TCP_AND_UDP"
    default_backend_set_key = string
  }))
  description = "Listeners keyed by logical name pointing at backend sets."
}
