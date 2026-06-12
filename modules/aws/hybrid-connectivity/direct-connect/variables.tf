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
variable "create_connection" {
  type        = bool
  description = "Whether to order a new dedicated DX connection. Set false when using an existing or hosted connection (supply existing_connection_id for private VIFs)."
  default     = false
}

variable "connection_bandwidth" {
  type        = string
  description = "Bandwidth for a new dedicated connection (1Gbps, 10Gbps, 100Gbps). Ignored when create_connection = false."
  default     = "1Gbps"
}

variable "connection_location" {
  type        = string
  description = "DX location code for a new connection (e.g., 'EqDC2'). Ignored when create_connection = false."
  default     = null
}

variable "existing_connection_id" {
  type        = string
  description = "ID of an existing DX (or hosted) connection to attach private VIFs to. Required when create_connection = false and private_vifs is non-empty."
  default     = null
}

variable "dx_gateway_name" {
  type        = string
  description = "Name override for the Direct Connect gateway. Null derives the name from the framework naming convention."
  default     = null
}

variable "dx_gateway_asn" {
  type        = number
  description = "Amazon-side ASN of the Direct Connect gateway (private range, must differ from on-premises ASN)."
  default     = 64513
}

variable "private_vifs" {
  type = map(object({
    vlan           = number
    bgp_asn        = number # on-premises/customer ASN
    bgp_auth_key   = optional(string) # sensitive; null lets AWS generate
    amazon_address   = optional(string) # e.g. "169.254.20.1/30"
    customer_address = optional(string) # e.g. "169.254.20.2/30"
    mtu              = optional(number, 1500) # 1500 or 9001 (jumbo)
  }))
  description = "Private virtual interfaces keyed by logical name, attached to the connection and the DX gateway."
  default     = {}
  sensitive   = true
}

variable "gateway_associations" {
  type = map(object({
    type                  = string # "vgw" | "tgw"
    gateway_id            = string # VGW or TGW ID
    allowed_prefixes      = optional(list(string), [])
  }))
  description = "Associations between the DX gateway and VGWs or transit gateways, keyed by logical name. allowed_prefixes filters which VPC CIDRs are advertised on-premises (required for TGW associations)."
  default     = {}

  validation {
    condition     = alltrue([for a in var.gateway_associations : contains(["vgw", "tgw"], a.type)])
    error_message = "Each gateway association type must be \"vgw\" or \"tgw\"."
  }
}
