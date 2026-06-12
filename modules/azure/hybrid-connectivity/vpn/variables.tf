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
variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group for the VPN gateway."
}

variable "location" {
  type        = string
  description = "Azure region for the VPN gateway."
}

variable "attachment_type" {
  type        = string
  description = "Where the gateway lives: 'vnet' creates a classic virtual network gateway in gateway_subnet_id; 'vhub' creates a vWAN VPN gateway inside the virtual hub given by virtual_hub_id."
  default     = "vnet"

  validation {
    condition     = contains(["vnet", "vhub"], var.attachment_type)
    error_message = "attachment_type must be \"vnet\" or \"vhub\"."
  }
}

# --- vnet mode -------------------------------------------------------------
variable "gateway_subnet_id" {
  type        = string
  description = "ID of the GatewaySubnet (must be named exactly 'GatewaySubnet', /27 or larger). Required when attachment_type = 'vnet'."
  default     = null
}

variable "sku" {
  type        = string
  description = "VPN gateway SKU (VpnGw1, VpnGw2, VpnGw3, VpnGw1AZ, ...). vnet mode only; Basic is not supported by this module."
  default     = "VpnGw1"

  validation {
    condition     = var.sku != "Basic"
    error_message = "Basic SKU is not supported (no BGP, no IKEv2 coexistence, deprecated)."
  }
}

variable "generation" {
  type        = string
  description = "Gateway generation: Generation1 or Generation2 (vnet mode; must match SKU compatibility)."
  default     = "Generation1"
}

variable "active_active" {
  type        = bool
  description = "Deploy active-active (two public IPs, two tunnels per connection side). vnet mode only; recommended for production."
  default     = false
}

# --- vhub mode -------------------------------------------------------------
variable "virtual_hub_id" {
  type        = string
  description = "ID of an existing vWAN virtual hub (e.g., azure/transit/vwan hub_id output, supplied as a plain value). Required when attachment_type = 'vhub'."
  default     = null
}

variable "virtual_wan_id" {
  type        = string
  description = "ID of the virtual WAN owning the hub. Required when attachment_type = 'vhub' (VPN sites are WAN-scoped)."
  default     = null
}

variable "vpn_gateway_scale_unit" {
  type        = number
  description = "Scale units of the vWAN VPN gateway (vhub mode). Each unit ~500 Mbps aggregate."
  default     = 1
}

# --- shared ----------------------------------------------------------------
variable "enable_bgp" {
  type        = bool
  description = "Enable BGP on the gateway (vnet mode). In vhub mode BGP is per-connection (connections.enable_bgp); the hub router ASN is fixed at 65515."
  default     = true
}

variable "bgp_asn" {
  type        = number
  description = "Azure-side BGP ASN (vnet mode; 65515 is the Azure default). vhub mode always uses the hub's 65515."
  default     = 65515
}

variable "local_network_gateways" {
  type = map(object({
    gateway_address = string # on-prem device public IP
    address_space   = optional(list(string), []) # on-prem CIDRs (static routing)
    bgp_asn         = optional(number)
    bgp_peering_address = optional(string)
  }))
  description = "On-premises sites keyed by logical name. vnet mode renders these as local network gateways; vhub mode renders the SAME shape as VPN sites (gateway_address -> site link IP, bgp fields -> link BGP)."
}

variable "connections" {
  type = map(object({
    local_network_gateway_key = string
    shared_key                = string # sensitive
    enable_bgp                = optional(bool, true)
    ipsec_policy = optional(object({
      dh_group         = string # e.g. "DHGroup14"
      ike_encryption   = string # e.g. "AES256"
      ike_integrity    = string # e.g. "SHA256"
      ipsec_encryption = string # e.g. "AES256"
      ipsec_integrity  = string # e.g. "SHA256"
      pfs_group        = string # e.g. "PFS14"
    }))
  }))
  description = "Site-to-site connections keyed by logical name, referencing sites by logical key. shared_key is sensitive. ipsec_policy applies in vnet mode only (vhub link policies are out of scope)."
  sensitive   = true
}

variable "enable_management_lock" {
  type        = bool
  description = "Apply a CanNotDelete management lock to the VPN gateway (governance/resource-locks)."
  default     = true
}
