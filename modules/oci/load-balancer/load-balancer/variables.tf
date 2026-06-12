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
  description = "OCID of the compartment for the load balancer."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet OCIDs for the LB. One regional subnet is typical; two AD-specific subnets for AD-redundant deployments."

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet OCID is required."
  }
}

variable "is_private" {
  type        = bool
  description = "Whether the LB is private (no public IP)."
  default     = true
}

variable "shape_min_mbps" {
  type        = number
  description = "Minimum bandwidth of the flexible shape in Mbps."
  default     = 10
}

variable "shape_max_mbps" {
  type        = number
  description = "Maximum bandwidth of the flexible shape in Mbps."
  default     = 100
}

variable "nsg_ids" {
  type        = list(string)
  description = "Network security group OCIDs attached to the LB."
  default     = []
}

variable "backend_sets" {
  type = map(object({
    policy = optional(string, "ROUND_ROBIN") # ROUND_ROBIN | LEAST_CONNECTIONS | IP_HASH
    health_checker = object({
      protocol    = string # "HTTP" | "TCP"
      port        = number
      url_path    = optional(string, "/") # HTTP only
      return_code = optional(number, 200) # HTTP only
      interval_ms = optional(number, 10000)
      timeout_ms  = optional(number, 3000)
      retries     = optional(number, 3)
    })
    session_persistence_cookie = optional(string) # cookie name; null = no persistence
    backends = optional(map(object({
      ip_address = string
      port       = number
      weight     = optional(number, 1)
      backup     = optional(bool, false)
    })), {})
  }))
  description = "Backend sets keyed by logical name with health checkers and optional static backends. Dynamic registration (instance pools) is the consumer's responsibility."
}

variable "listeners" {
  type = map(object({
    port                    = number
    protocol                = string # "HTTP" | "HTTP2" | "TCP"
    default_backend_set_key = string
    certificate_name        = optional(string) # from certificates map, enables TLS
    ssl_verify_peer         = optional(bool, false)
  }))
  description = "Listeners keyed by logical name, each pointing at a default backend set."
}

variable "certificates" {
  type = map(object({
    certificate_pem    = string
    private_key_pem    = string # sensitive
    ca_certificate_pem = optional(string)
  }))
  description = "TLS certificates keyed by logical name, referenced by listeners via certificate_name."
  default     = {}
  sensitive   = true
}
