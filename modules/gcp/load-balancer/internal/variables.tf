# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
# ---------------------------------------------------------------------------
variable "prefix" {
  type        = string
  description = "Short organization or project prefix. First token of every resource name: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, test, prod). Used in resource names and mandatory labels."
}

variable "owner" {
  type        = string
  description = "Team or individual that owns the deployed resources. Applied as the mandatory 'owner' label where supported (lowercased)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Applied as the mandatory 'cost_center' label where supported (lowercased)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional additional labels merged beneath the mandatory label set (lowercased)."
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
  description = "GCP project ID hosting the load balancer."
}

variable "region" {
  type        = string
  description = "Region of the internal load balancer and its backend service."
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the VPC network. Supplied as a plain value — no framework dependency is implied."
}

variable "subnet_self_link" {
  type        = string
  description = "Self-link of the subnet hosting the forwarding-rule IP."
}

variable "ip_address" {
  type        = string
  description = "Static internal IP for the forwarding rule. Null = ephemeral from the subnet range."
  default     = null
}

variable "protocol" {
  type        = string
  description = "Load-balanced protocol: TCP or UDP."
  default     = "TCP"

  validation {
    condition     = contains(["TCP", "UDP"], var.protocol)
    error_message = "protocol must be TCP or UDP."
  }
}

variable "ports" {
  type        = list(string)
  description = "Ports the forwarding rule accepts (max 5), or empty with all_ports = true."
  default     = []
}

variable "all_ports" {
  type        = bool
  description = "Forward all ports (mutually exclusive with ports)."
  default     = false
}

variable "allow_global_access" {
  type        = bool
  description = "Allow clients from any region of the VPC (not just the LB region) to reach the ILB."
  default     = false
}

variable "backend_groups" {
  type = map(object({
    group          = string # instance group or NEG self-link
    balancing_mode = optional(string, "CONNECTION")
    failover       = optional(bool, false)
  }))
  description = "Backend instance groups / NEGs keyed by logical name. Group lifecycle (MIGs, NEGs) is the consumer's responsibility."
}

variable "health_check" {
  type = object({
    port                = number
    protocol            = optional(string, "TCP") # TCP | HTTP | HTTPS
    request_path        = optional(string, "/")   # HTTP/HTTPS only
    check_interval_sec  = optional(number, 5)
    timeout_sec         = optional(number, 5)
    healthy_threshold   = optional(number, 2)
    unhealthy_threshold = optional(number, 2)
  })
  description = "Health check configuration for the backend service."
}

variable "session_affinity" {
  type        = string
  description = "Session affinity: NONE, CLIENT_IP, CLIENT_IP_PROTO, or CLIENT_IP_PORT_PROTO."
  default     = "NONE"
}
