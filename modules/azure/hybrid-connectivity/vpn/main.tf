# ===========================================================================
# Azure Hybrid Connectivity — VPN (VNet gateway OR vWAN hub gateway)
#
# Independently invocable: this module sources no other module in this
# framework. The GatewaySubnet (vnet mode) or virtual hub + WAN IDs (vhub
# mode) are plain inputs — pass azure/transit/vwan outputs as values, never
# as module references.
#
# Provider API divergence note (see README): Azure's tunnel count depends
# on active_active mode (vnet) or gateway instances (vhub — always two
# instances) — AWS always provisions two tunnels per connection; GCP HA
# VPN exposes two interfaces on one gateway; OCI carries two tunnels per
# IPSec connection. Gateway creation takes 30-45 minutes in either mode.
#
# vhub mode mirrors the AWS vpn module's attachment_type vgw|tgw switch:
# the same site/connection variable shapes render as vWAN vpn_site /
# vpn_gateway_connection resources. Branch connections always land on the
# hub's DEFAULT route table — steering branch traffic through an NVA needs
# default-table hub_routes in the vwan module.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-azure-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/azure/hybrid-connectivity/vpn"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  is_vnet = var.attachment_type == "vnet"

  public_ip_count = local.is_vnet ? (var.active_active ? 2 : 1) : 0
}

# ===========================================================================
# vnet mode — classic virtual network gateway
# ===========================================================================
resource "azurerm_public_ip" "this" {
  count = local.public_ip_count

  name                = "${local.name_base}-pip-vpngw-${count.index}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.all_tags
}

resource "azurerm_virtual_network_gateway" "this" {
  count = local.is_vnet ? 1 : 0

  name                = "${local.name_base}-vpngw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  type          = "Vpn"
  vpn_type      = "RouteBased"
  sku           = var.sku
  generation    = var.generation
  active_active = var.active_active
  enable_bgp    = var.enable_bgp

  dynamic "ip_configuration" {
    for_each = azurerm_public_ip.this
    content {
      name                          = "ipconfig-${ip_configuration.key}"
      public_ip_address_id          = ip_configuration.value.id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = var.gateway_subnet_id
    }
  }

  dynamic "bgp_settings" {
    for_each = var.enable_bgp ? [1] : []
    content {
      asn = var.bgp_asn
    }
  }

  tags = local.all_tags
}

resource "azurerm_local_network_gateway" "this" {
  for_each = local.is_vnet ? var.local_network_gateways : {}

  name                = "${local.name_base}-lngw-${each.key}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_space

  dynamic "bgp_settings" {
    for_each = each.value.bgp_asn != null ? [1] : []
    content {
      asn                 = each.value.bgp_asn
      bgp_peering_address = each.value.bgp_peering_address
    }
  }

  tags = local.all_tags
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each = local.is_vnet ? var.connections : {}

  name                = "${local.name_base}-vpnconn-${each.key}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.this[each.value.local_network_gateway_key].id
  shared_key                 = each.value.shared_key
  enable_bgp                 = each.value.enable_bgp

  dynamic "ipsec_policy" {
    for_each = each.value.ipsec_policy != null ? [each.value.ipsec_policy] : []
    content {
      dh_group         = ipsec_policy.value.dh_group
      ike_encryption   = ipsec_policy.value.ike_encryption
      ike_integrity    = ipsec_policy.value.ike_integrity
      ipsec_encryption = ipsec_policy.value.ipsec_encryption
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity
      pfs_group        = ipsec_policy.value.pfs_group
    }
  }

  tags = local.all_tags
}

# ===========================================================================
# vhub mode — vWAN VPN gateway + sites + connections
# ===========================================================================
resource "azurerm_vpn_gateway" "this" {
  count = local.is_vnet ? 0 : 1

  name                = "${local.name_base}-vhubvpngw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_hub_id      = var.virtual_hub_id
  scale_unit          = var.vpn_gateway_scale_unit

  tags = local.all_tags
}

resource "azurerm_vpn_site" "this" {
  for_each = local.is_vnet ? {} : var.local_network_gateways

  name                = "${local.name_base}-vpnsite-${each.key}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_wan_id      = var.virtual_wan_id

  # Static-routing sites advertise address_cidrs; BGP sites advertise via
  # the link's BGP session instead.
  address_cidrs = length(each.value.address_space) > 0 ? each.value.address_space : null

  link {
    name       = "link0"
    ip_address = each.value.gateway_address

    dynamic "bgp" {
      for_each = each.value.bgp_asn != null ? [1] : []
      content {
        asn             = each.value.bgp_asn
        peering_address = each.value.bgp_peering_address
      }
    }
  }

  tags = local.all_tags
}

resource "azurerm_vpn_gateway_connection" "this" {
  for_each = local.is_vnet ? {} : var.connections

  name               = "${local.name_base}-vpnconn-${each.key}-${var.name_suffix}"
  vpn_gateway_id     = azurerm_vpn_gateway.this[0].id
  remote_vpn_site_id = azurerm_vpn_site.this[each.value.local_network_gateway_key].id

  vpn_link {
    name             = "link0"
    vpn_site_link_id = azurerm_vpn_site.this[each.value.local_network_gateway_key].link[0].id
    shared_key       = each.value.shared_key
    bgp_enabled      = each.value.enable_bgp
  }
  # Note: custom IPsec policies (ipsec_policy variable) apply to vnet mode
  # only — vWAN link-level policies are intentionally out of scope.
}

# ---------------------------------------------------------------------------
# Management lock (governance/resource-locks)
# ---------------------------------------------------------------------------
resource "azurerm_management_lock" "gateway" {
  count = var.enable_management_lock ? 1 : 0

  name       = "${local.name_base}-lock-vpngw-${var.name_suffix}"
  scope      = local.is_vnet ? azurerm_virtual_network_gateway.this[0].id : azurerm_vpn_gateway.this[0].id
  lock_level = "CanNotDelete"
  notes      = "Connectivity-critical resource protected by framework convention (governance/resource-locks)."
}
