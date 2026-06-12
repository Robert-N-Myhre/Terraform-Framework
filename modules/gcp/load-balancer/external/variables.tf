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

variable "backend_services" {
  type = map(object({
    protocol           = optional(string, "HTTP") # HTTP | HTTPS | HTTP2
    port_name          = optional(string, "http") # named port on instance groups
    timeout_sec        = optional(number, 30)
    enable_cdn         = optional(bool, false)
    security_policy_id = optional(string) # Cloud Armor policy (gcp/firewall/cloud-armor output)
    groups = map(object({
      group           = string # instance group or NEG self-link
      balancing_mode  = optional(string, "UTILIZATION")
      capacity_scaler = optional(number, 1.0)
      max_utilization = optional(number, 0.8)
    }))
    health_check = object({
      port                = number
      protocol            = optional(string, "HTTP") # HTTP | HTTPS | TCP
      request_path        = optional(string, "/")
      check_interval_sec  = optional(number, 5)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 2)
    })
  }))
  description = "Global backend services keyed by logical name, each with backend groups and a health check. Attach a Cloud Armor policy via security_policy_id."
}

variable "default_backend_service_key" {
  type        = string
  description = "Logical key of the backend service receiving unmatched traffic (URL map default)."
}

variable "host_rules" {
  type = map(object({
    hosts               = list(string)
    backend_service_key = string
    path_rules = optional(map(object({
      paths               = list(string)
      backend_service_key = string
    })), {})
  }))
  description = "Host-based routing rules keyed by logical name, with optional path rules per host."
  default     = {}
}

variable "enable_https" {
  type        = bool
  description = "Create an HTTPS frontend (managed or self-managed certs required)."
  default     = false
}

variable "managed_certificate_domains" {
  type        = list(string)
  description = "Domains for a Google-managed SSL certificate. Certificate activates only after DNS resolves to the LB IP."
  default     = []
}

variable "ssl_certificate_ids" {
  type        = list(string)
  description = "Existing SSL certificate self-links to attach instead of (or alongside) the managed certificate."
  default     = []
}

variable "enable_http" {
  type        = bool
  description = "Create an HTTP (port 80) frontend. Commonly kept on for redirect-to-HTTPS handled at the application."
  default     = true
}

variable "static_ip_name" {
  type        = string
  description = "Name for the module-managed global static IP. Null derives the name from the framework naming convention."
  default     = null
}
