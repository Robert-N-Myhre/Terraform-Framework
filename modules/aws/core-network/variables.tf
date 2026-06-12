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
  description = "Final token of every resource name, used to disambiguate multiple instances of this module (e.g., '01', 'hub')."
  default     = "01"
}

# ---------------------------------------------------------------------------
# Module-specific variables
# ---------------------------------------------------------------------------
variable "region" {
  type        = string
  description = "AWS region in which to create the VPC and all child resources (e.g., 'us-east-1'). Must match the region of the configured provider."
}

variable "vpc_cidr_block" {
  type        = string
  description = "IPv4 CIDR block for the VPC (e.g., '10.0.0.0/16')."
}

variable "enable_dns_support" {
  type        = bool
  description = "Whether to enable DNS resolution inside the VPC via the Amazon-provided DNS server."
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Whether instances launched in the VPC receive Amazon-provided DNS hostnames."
  default     = true
}

variable "subnets" {
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    tier                    = string # "public" | "private"
    map_public_ip_on_launch = optional(bool, false)
  }))
  description = <<-EOT
    Map of subnets to create, keyed by a stable logical name (e.g., 'app-a').
    tier = "public" attaches the subnet to the public route table (internet
    gateway default route); tier = "private" attaches it to a private route
    table (NAT gateway default route when NAT is enabled).
  EOT

  validation {
    condition     = alltrue([for s in var.subnets : contains(["public", "private"], s.tier)])
    error_message = "Each subnet tier must be either \"public\" or \"private\"."
  }
}

variable "enable_internet_gateway" {
  type        = bool
  description = "Whether to create an internet gateway and a default route for public-tier subnets."
  default     = true
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Whether to create NAT gateway(s) for private-tier subnet egress. Requires at least one public-tier subnet and enable_internet_gateway = true."
  default     = false
}

variable "nat_gateway_strategy" {
  type        = string
  description = "NAT gateway placement: 'single' creates one NAT gateway in the first public subnet; 'per_az' creates one per availability zone that hosts a public subnet (higher cost, AZ-fault isolation)."
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_strategy)
    error_message = "nat_gateway_strategy must be \"single\" or \"per_az\"."
  }
}

variable "enable_flow_logs" {
  type        = bool
  description = "Whether to enable VPC flow logs delivered to a module-managed CloudWatch log group."
  default     = false
}

variable "flow_log_retention_days" {
  type        = number
  description = "Retention period in days for the flow-log CloudWatch log group."
  default     = 30
}

variable "flow_log_traffic_type" {
  type        = string
  description = "Traffic type captured by flow logs: ACCEPT, REJECT, or ALL."
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be ACCEPT, REJECT, or ALL."
  }
}
