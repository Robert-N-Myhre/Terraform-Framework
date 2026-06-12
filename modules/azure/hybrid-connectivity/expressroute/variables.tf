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
  description = "Name of the existing resource group for the ExpressRoute resources."
}

variable "location" {
  type        = string
  description = "Azure region for the ExpressRoute resources."
}

variable "service_provider_name" {
  type        = string
  description = "Connectivity provider name (e.g., 'Equinix', 'Megaport'). Must match an Azure-listed provider."
}

variable "peering_location" {
  type        = string
  description = "Provider peering location (e.g., 'Washington DC'). Distinct from the Azure region."
}

variable "bandwidth_in_mbps" {
  type        = number
  description = "Circuit bandwidth in Mbps (50 to 10000 for provider model)."
  default     = 1000
}

variable "sku_tier" {
  type        = string
  description = "Circuit SKU tier: Standard, Premium (global reach across geopolitical regions), or Local."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium", "Local"], var.sku_tier)
    error_message = "sku_tier must be Standard, Premium, or Local."
  }
}

variable "sku_family" {
  type        = string
  description = "Billing family: MeteredData or UnlimitedData."
  default     = "MeteredData"

  validation {
    condition     = contains(["MeteredData", "UnlimitedData"], var.sku_family)
    error_message = "sku_family must be MeteredData or UnlimitedData."
  }
}

variable "private_peering" {
  type = object({
    enabled                       = bool
    peer_asn                      = optional(number)
    primary_peer_address_prefix   = optional(string) # /30
    secondary_peer_address_prefix = optional(string) # /30
    vlan_id                       = optional(number)
    shared_key                    = optional(string) # sensitive, MD5 auth
  })
  description = "Azure private peering configuration on the circuit. Both /30 prefixes and the VLAN are agreed with the connectivity provider."
  default     = { enabled = false }
  sensitive   = true
}

variable "create_gateway" {
  type        = bool
  description = "Whether to create an ExpressRoute gateway: a virtual network gateway in gateway_subnet_id (attachment_type = 'vnet') or a vWAN ExpressRoute gateway in virtual_hub_id (attachment_type = 'vhub')."
  default     = false
}

variable "attachment_type" {
  type        = string
  description = "Where the ER gateway lives: 'vnet' creates a classic virtual network gateway in gateway_subnet_id; 'vhub' creates a vWAN ExpressRoute gateway inside the virtual hub given by virtual_hub_id."
  default     = "vnet"

  validation {
    condition     = contains(["vnet", "vhub"], var.attachment_type)
    error_message = "attachment_type must be \"vnet\" or \"vhub\"."
  }
}

variable "virtual_hub_id" {
  type        = string
  description = "ID of an existing vWAN virtual hub (e.g., azure/transit/vwan hub_id output, supplied as a plain value). Required when attachment_type = 'vhub' and create_gateway = true."
  default     = null
}

variable "er_gateway_scale_units" {
  type        = number
  description = "Scale units of the vWAN ExpressRoute gateway (vhub mode). Each unit ~2 Gbps."
  default     = 1
}

variable "gateway_subnet_id" {
  type        = string
  description = "ID of the GatewaySubnet for the ER gateway. Required when create_gateway = true."
  default     = null
}

variable "gateway_sku" {
  type        = string
  description = "ExpressRoute gateway SKU (Standard, HighPerformance, UltraPerformance, ErGw1AZ..ErGw3AZ)."
  default     = "Standard"
}

variable "connect_gateway_to_circuit" {
  type        = bool
  description = "Create the connection between the module-managed gateway and circuit. Requires create_gateway = true and the circuit provisioned by the provider."
  default     = false
}

variable "enable_management_lock" {
  type        = bool
  description = "Apply a CanNotDelete management lock to the circuit (governance/resource-locks)."
  default     = true
}
