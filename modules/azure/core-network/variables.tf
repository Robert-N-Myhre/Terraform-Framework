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
  description = "Name of the existing resource group in which to create the VNet and child resources. Resource group lifecycle belongs to the consumer."
}

variable "location" {
  type        = string
  description = "Azure region for all resources (e.g., 'eastus2'). No hardcoded regions — always supplied by the consumer."
}

variable "address_space" {
  type        = list(string)
  description = "IPv4 address space(s) for the virtual network (e.g., [\"10.40.0.0/16\"])."
}

variable "dns_servers" {
  type        = list(string)
  description = "Custom DNS server IPs for the VNet. Empty list uses Azure-provided DNS."
  default     = []
}

variable "subnets" {
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name    = string # e.g. "Microsoft.Web/serverFarms"
      actions = optional(list(string), ["Microsoft.Network/virtualNetworks/subnets/action"])
    }))
    private_endpoint_network_policies_enabled = optional(bool, true)
    create_route_table                        = optional(bool, true)
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string # VirtualAppliance | VirtualNetworkGateway | Internet | VnetLocal | None
      next_hop_in_ip_address = optional(string)
    })), {})
  }))
  description = <<-EOT
    Map of subnets keyed by logical name. Each subnet optionally gets its own
    route table (create_route_table, default true) with UDRs from routes.
    NSG association is intentionally NOT handled here — invoke the
    azure/firewall/nsgs module independently for that.
  EOT
}

variable "nat_gateway_subnet_keys" {
  type        = list(string)
  description = "Logical subnet keys that should egress through a module-managed NAT gateway. Empty list disables NAT gateway creation."
  default     = []
}

variable "nat_gateway_zones" {
  type        = list(string)
  description = "Availability zones for the NAT gateway public IP (e.g., [\"1\"]). Azure NAT Gateway is zonal, not zone-redundant."
  default     = []
}

variable "enable_flow_logs" {
  type        = bool
  description = "Whether to enable VNet flow logs via Network Watcher. Requires network_watcher_name/network_watcher_resource_group and flow_log_storage_account_id."
  default     = false
}

variable "network_watcher_name" {
  type        = string
  description = "Name of the existing Network Watcher instance (typically 'NetworkWatcher_<region>'). Required when enable_flow_logs = true."
  default     = null
}

variable "network_watcher_resource_group" {
  type        = string
  description = "Resource group of the Network Watcher instance (typically 'NetworkWatcherRG'). Required when enable_flow_logs = true."
  default     = null
}

variable "flow_log_storage_account_id" {
  type        = string
  description = "ID of the storage account receiving flow logs. Required when enable_flow_logs = true."
  default     = null
}

variable "flow_log_retention_days" {
  type        = number
  description = "Retention in days for flow logs in the storage account."
  default     = 30
}

variable "enable_management_lock" {
  type        = bool
  description = "Apply a CanNotDelete management lock to the VNet (governance/resource-locks). Remove the lock (apply with false) before destroying."
  default     = true
}
