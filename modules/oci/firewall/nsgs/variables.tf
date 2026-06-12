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
  description = "OCID of the compartment for the NSGs."
}

variable "vcn_id" {
  type        = string
  description = "OCID of the VCN the NSGs belong to. Supplied by OCID — no framework dependency is implied."
}

variable "network_security_groups" {
  type = map(object({
    rules = optional(map(object({
      direction   = string # "INGRESS" | "EGRESS"
      protocol    = string # "6"=TCP, "17"=UDP, "1"=ICMP, "all"
      description = optional(string)
      stateless   = optional(bool, false)

      # Source/destination — exactly one style per rule:
      cidr            = optional(string) # CIDR block
      service         = optional(string) # service CIDR string (e.g. Object Storage)
      nsg_key         = optional(string) # logical key of another NSG in this map
      external_nsg_id = optional(string) # OCID of an NSG outside this module

      tcp_min   = optional(number)
      tcp_max   = optional(number)
      udp_min   = optional(number)
      udp_max   = optional(number)
      icmp_type = optional(number)
      icmp_code = optional(number)
    })), {})
  }))
  description = <<-EOT
    Map of NSGs keyed by logical name, each with a map of rules. nsg_key
    references another NSG in this map (OCI's analogue of AWS SG-to-SG
    rules); external_nsg_id references any pre-existing NSG. VNIC
    membership is declared on the VNIC/LB/etc. where the workload is
    managed — outside this module by design.
  EOT

  validation {
    condition = alltrue(flatten([
      for nsg in var.network_security_groups : [
        for r in nsg.rules :
        length([for x in [r.cidr, r.service, r.nsg_key, r.external_nsg_id] : x if x != null]) == 1
      ]
    ]))
    error_message = "Each NSG rule must set exactly one of: cidr, service, nsg_key, external_nsg_id."
  }
}
