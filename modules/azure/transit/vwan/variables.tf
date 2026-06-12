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
  description = "Name of the existing resource group for the virtual WAN."
}

variable "location" {
  type        = string
  description = "Azure region for the virtual WAN resource itself."
}

variable "wan_type" {
  type        = string
  description = "Virtual WAN type: 'Standard' (full transit) or 'Basic' (S2S VPN only)."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Basic"], var.wan_type)
    error_message = "wan_type must be Standard or Basic."
  }
}

variable "hubs" {
  type = map(object({
    location               = string
    address_prefix         = string                           # /23 or larger recommended (e.g., "10.100.0.0/23")
    hub_routing_preference = optional(string, "ExpressRoute") # ExpressRoute | VpnGateway | ASPath
  }))
  description = "Virtual hubs keyed by logical name, one per region. Address prefix must not overlap any connected VNet or branch."
}

variable "vnet_connections" {
  type = map(object({
    hub_key                   = string
    vnet_id                   = string
    internet_security_enabled = optional(bool, false)

    # Routing configuration (NVA-in-spoke / firewall services hub patterns):
    # associated_route_table_key = custom route table this connection
    # associates with (null = hub default route table).
    associated_route_table_key = optional(string)
    # propagate_none = true isolates the connection (propagates only to the
    # hub's built-in noneRouteTable) — the standard spoke pattern when a
    # custom route table steers 0/0 + RFC1918 through a firewall connection.
    propagate_none = optional(bool, false)
    # Or propagate to specific custom route tables / labels:
    propagated_route_table_keys = optional(list(string), [])
    propagated_labels           = optional(list(string), [])

    # Static routes that apply to traffic entering THIS VNet via the hub —
    # for a firewall services VNet this points at the internal LB frontend
    # in front of the NVA trust interfaces.
    static_routes = optional(map(object({
      address_prefixes    = list(string)
      next_hop_ip_address = string
    })), {})
  }))
  description = <<-EOT
    VNet-to-hub connections keyed by logical name, referencing hubs by
    logical key. Spoke VNet IDs may come from any source. propagate_none and
    propagated_route_table_keys/labels are mutually exclusive per connection.
  EOT
  default     = {}

  validation {
    condition = alltrue([
      for c in var.vnet_connections :
      !(c.propagate_none && (length(c.propagated_route_table_keys) > 0 || length(c.propagated_labels) > 0))
    ])
    error_message = "propagate_none cannot be combined with propagated_route_table_keys or propagated_labels on the same connection."
  }
}

variable "hub_route_tables" {
  type = map(object({
    hub_key = string
    labels  = optional(list(string), [])
  }))
  description = "Custom hub route tables keyed by logical name (e.g., 'spokes'). Routes are defined separately in hub_routes to keep the resource graph acyclic (route tables <- connections <- routes)."
  default     = {}
}

variable "hub_routes" {
  type = map(object({
    hub_key                 = string
    route_table_key         = optional(string) # null = the hub's DEFAULT route table
    destinations            = list(string)     # CIDRs
    destinations_type       = optional(string, "CIDR")
    next_hop_connection_key = string # logical key in vnet_connections
  }))
  description = <<-EOT
    Static hub routes keyed by logical name, targeting a custom route table
    (route_table_key) or the hub's default route table (route_table_key =
    null — required for steering BRANCH traffic, since VPN/ER connections can
    only associate with the default route table). next_hop is always a VNet
    connection (next_hop_type ResourceId) — the firewall services VNet
    connection in the NVA pattern.
  EOT
  default     = {}
}

variable "bgp_connections" {
  type = map(object({
    hub_key        = string
    peer_asn       = number           # NVA's ASN; must NOT be 65515 (hub router) — eBGP only
    peer_ip        = string           # NVA interface IP in the connected VNet
    connection_key = optional(string) # vnet_connections key hosting the NVA
  }))
  description = "Hub router BGP peerings with NVAs in connected VNets (e.g., Palo Alto VM-Series), keyed by logical name. Lets the NVA advertise routes dynamically instead of relying on static hub_routes. Requires a Standard WAN."
  default     = {}

  validation {
    condition     = alltrue([for b in var.bgp_connections : b.peer_asn != 65515])
    error_message = "peer_asn must not be 65515 — that ASN is reserved for the vWAN hub router."
  }
}

variable "enable_management_lock" {
  type        = bool
  description = "Apply a CanNotDelete management lock to the virtual WAN (governance/resource-locks)."
  default     = true
}
