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
  description = "OCID of the compartment for all resources. No hardcoded OCIDs — always supplied by the consumer."
}

variable "vcn_cidr_blocks" {
  type        = list(string)
  description = "IPv4 CIDR blocks for the VCN (e.g., [\"10.80.0.0/16\"])."
}

variable "dns_label" {
  type        = string
  description = "DNS label for the VCN (alphanumeric, <= 15 chars, immutable). Enables '<subnet>.<vcn>.oraclevcn.com' internal resolution."
  default     = null
}

variable "subnets" {
  type = map(object({
    cidr_block                 = string
    prohibit_public_ip_on_vnic = optional(bool, true) # true = private subnet
    dns_label                  = optional(string)
    availability_domain        = optional(string) # null = regional subnet (recommended)
    route_rules = optional(map(object({
      destination        = string                         # CIDR or service string
      destination_type   = optional(string, "CIDR_BLOCK") # CIDR_BLOCK | SERVICE_CIDR_BLOCK
      network_entity_key = optional(string)               # "igw" | "natgw" | "sgw" — module-managed gateways
      network_entity_id  = optional(string)               # explicit OCID (DRG, LPG, private IP)
    })), {})
  }))
  description = <<-EOT
    Map of subnets keyed by logical name. Each subnet gets its own route
    table built from route_rules; rules target module-managed gateways by
    keyword (igw/natgw/sgw) or any external entity by OCID. OCI subnets are
    regional by default (availability_domain = null) — AD-specific subnets
    are legacy.
  EOT
}

variable "create_internet_gateway" {
  type        = bool
  description = "Create an internet gateway (for public subnets)."
  default     = false
}

variable "create_nat_gateway" {
  type        = bool
  description = "Create a NAT gateway (for private subnet egress)."
  default     = false
}

variable "create_service_gateway" {
  type        = bool
  description = "Create a service gateway (private access to OCI services: Object Storage, etc.)."
  default     = false
}

variable "enable_flow_logs" {
  type        = bool
  description = "Enable VCN flow logs (all subnets) into a module-managed log group. Requires flow_log_retention_days."
  default     = false
}

variable "flow_log_retention_days" {
  type        = number
  description = "Retention in days for the flow-log log group (30-180 per OCI Logging limits)."
  default     = 30
}
