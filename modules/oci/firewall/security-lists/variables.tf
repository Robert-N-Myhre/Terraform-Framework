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
  description = "OCID of the compartment for the security lists."
}

variable "vcn_id" {
  type        = string
  description = "OCID of the VCN the security lists belong to. Supplied by OCID — no framework dependency is implied."
}

variable "security_lists" {
  type = map(object({
    ingress_rules = optional(map(object({
      protocol    = string # "6"=TCP, "17"=UDP, "1"=ICMP, "all"
      source      = string # CIDR or service string
      source_type = optional(string, "CIDR_BLOCK") # CIDR_BLOCK | SERVICE_CIDR_BLOCK
      stateless   = optional(bool, false)
      description = optional(string)
      tcp_min     = optional(number) # destination port range
      tcp_max     = optional(number)
      udp_min     = optional(number)
      udp_max     = optional(number)
      icmp_type   = optional(number)
      icmp_code   = optional(number)
    })), {})
    egress_rules = optional(map(object({
      protocol         = string
      destination      = string
      destination_type = optional(string, "CIDR_BLOCK")
      stateless        = optional(bool, false)
      description      = optional(string)
      tcp_min          = optional(number)
      tcp_max          = optional(number)
      udp_min          = optional(number)
      udp_max          = optional(number)
      icmp_type        = optional(number)
      icmp_code        = optional(number)
    })), {})
  }))
  description = <<-EOT
    Map of security lists keyed by logical name. Rules are STATEFUL by
    default (stateless = true opts out per rule). Protocols use IANA
    numbers as strings ("6" TCP, "17" UDP, "1" ICMP) or "all". Security
    lists apply to subnets — pass the resulting IDs into oci_core_subnet
    security_list_ids in the consumer root (or use the VCN default list).
  EOT
}
