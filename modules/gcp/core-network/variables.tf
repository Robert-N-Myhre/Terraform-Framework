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
  description = "Team or individual that owns the deployed resources. Applied as the mandatory 'owner' label. GCP labels require lowercase letters, numbers, hyphens, underscores."
}

variable "cost_center" {
  type        = string
  description = "Cost center code for chargeback/showback. Applied as the mandatory 'cost_center' label (lowercase)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional additional labels merged beneath the mandatory label set. GCP label keys/values must be lowercase. Mandatory labels win on key collision."
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
  description = "GCP project ID hosting the VPC. No hardcoded project IDs — always supplied by the consumer."
}

variable "routing_mode" {
  type        = string
  description = "Dynamic routing mode for the VPC's Cloud Routers: REGIONAL or GLOBAL."
  default     = "GLOBAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "delete_default_routes_on_create" {
  type        = bool
  description = "Delete the auto-created 0.0.0.0/0 route at VPC creation (strict egress posture; re-add explicit routes as needed)."
  default     = false
}

variable "subnets" {
  type = map(object({
    ip_cidr_range            = string
    region                   = string
    private_ip_google_access = optional(bool, true)
    secondary_ip_ranges = optional(map(string), {}) # name -> CIDR (GKE pods/services)
    flow_logs = optional(object({
      enabled              = bool
      aggregation_interval = optional(string, "INTERVAL_5_SEC")
      flow_sampling        = optional(number, 0.5)
      metadata             = optional(string, "INCLUDE_ALL_METADATA")
    }), { enabled = false })
  }))
  description = <<-EOT
    Map of subnets keyed by logical name. GCP subnets are REGIONAL (region
    per subnet, unlike AWS/Azure zonal-or-regional models). Flow logs are
    configured per subnet, not per network. secondary_ip_ranges supports
    GKE alias IPs.
  EOT
}

variable "static_routes" {
  type = map(object({
    dest_range       = string
    priority         = optional(number, 1000)
    next_hop_gateway = optional(string) # "default-internet-gateway"
    next_hop_ip      = optional(string)
    next_hop_ilb     = optional(string) # forwarding rule self-link
    tags             = optional(list(string), []) # instance tags the route applies to
  }))
  description = "Static routes keyed by logical name. Exactly one next_hop_* must be set per route."
  default     = {}
}

variable "cloud_nat" {
  type = object({
    enabled                            = bool
    region                             = optional(string)
    source_subnetwork_ip_ranges_to_nat = optional(string, "ALL_SUBNETWORKS_ALL_IP_RANGES")
    min_ports_per_vm                   = optional(number, 64)
    log_errors_only                    = optional(bool, true)
  })
  description = "Cloud NAT configuration. Creates a Cloud Router + NAT in the given region for private-subnet egress."
  default     = { enabled = false }
}
