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
variable "attachment_type" {
  type        = string
  description = "Where the VPN terminates: 'vgw' creates and attaches a virtual private gateway to vpc_id; 'tgw' attaches the VPN to an existing transit gateway given by transit_gateway_id."
  default     = "vgw"

  validation {
    condition     = contains(["vgw", "tgw"], var.attachment_type)
    error_message = "attachment_type must be \"vgw\" or \"tgw\"."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the virtual private gateway. Required when attachment_type = 'vgw'."
  default     = null
}

variable "transit_gateway_id" {
  type        = string
  description = "Existing transit gateway ID. Required when attachment_type = 'tgw'. May come from any source — no framework dependency is implied."
  default     = null
}

variable "amazon_side_asn" {
  type        = number
  description = "Amazon-side BGP ASN for the virtual private gateway (vgw mode only)."
  default     = 64512
}

variable "customer_gateways" {
  type = map(object({
    bgp_asn     = number
    ip_address  = string
    device_name = optional(string)
  }))
  description = "Customer gateways keyed by logical name: on-premises device public IP and BGP ASN (use 65000-range private ASN for static routing)."
}

variable "vpn_connections" {
  type = map(object({
    customer_gateway_key  = string
    static_routes_only    = optional(bool, false)
    static_routes         = optional(list(string), []) # on-prem CIDRs (vgw + static only)
    tunnel1_inside_cidr   = optional(string)
    tunnel2_inside_cidr   = optional(string)
    tunnel1_preshared_key = optional(string) # sensitive; null lets AWS generate
    tunnel2_preshared_key = optional(string)
    tunnel_ike_versions   = optional(list(string), ["ikev2"])
  }))
  description = "Site-to-site VPN connections keyed by logical name, each referencing a customer gateway by logical key. Prefer BGP (static_routes_only = false); static routes are only injected in vgw mode."
  sensitive   = true
}

variable "enable_route_propagation" {
  type        = list(string)
  description = "Route table IDs in the VPC that should learn VGW routes via propagation (vgw mode only)."
  default     = []
}
