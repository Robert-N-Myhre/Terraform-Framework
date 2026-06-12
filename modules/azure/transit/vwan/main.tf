# ===========================================================================
# Azure Transit — Virtual WAN (hub-and-spoke, third-party-NVA-ready)
#
# Independently invocable: this module sources no other module in this
# framework. Spoke VNet IDs are plain inputs.
#
# Provider API divergence note (see README): Virtual WAN is Azure's managed
# transit hub — the analogue of AWS Transit Gateway, GCP Network
# Connectivity Center, and OCI DRG. Unlike TGW, the vWAN hub embeds its
# own router and (optionally) gateways; VPN/ExpressRoute gateways attach
# to the hub rather than to spoke VNets (see the vhub mode of the
# azure/hybrid-connectivity modules). Hub provisioning takes 20-30
# minutes.
#
# Third-party firewall (NVA-in-spoke) support: routing INTENT only accepts
# in-hub next-hops (Azure Firewall, integrated hub NVAs, SaaS like Palo
# Alto Cloud NGFW), so it is deliberately NOT modeled here. A VM-Series
# style firewall in a connected services VNet is steered with:
#   1. hub_routes whose next_hop is the firewall VNet CONNECTION,
#   2. static_routes on that connection pointing at the internal LB IP,
#   3. optionally bgp_connections so the NVA advertises routes via eBGP.
#
# Dependency design: route tables are created BARE, then connections
# (which may associate with them), then routes as standalone resources
# (which reference connections as next-hops). Inlining routes on the
# route table would create a cycle: route table -> connection -> route
# table.
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
    module_source = "modules/azure/transit/vwan"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  # Connections that need an explicit routing block.
  routed_connections = {
    for k, c in var.vnet_connections : k => c
    if length(c.static_routes) > 0 ||
    c.associated_route_table_key != null ||
    c.propagate_none ||
    length(c.propagated_route_table_keys) > 0 ||
    length(c.propagated_labels) > 0
  }
}

resource "azurerm_virtual_wan" "this" {
  name                = "${local.name_base}-vwan-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = var.wan_type

  tags = local.all_tags
}

resource "azurerm_virtual_hub" "this" {
  for_each = var.hubs

  name                   = "${local.name_base}-vhub-${each.key}-${var.name_suffix}"
  resource_group_name    = var.resource_group_name
  location               = each.value.location
  virtual_wan_id         = azurerm_virtual_wan.this.id
  address_prefix         = each.value.address_prefix
  hub_routing_preference = each.value.hub_routing_preference

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Custom hub route tables (bare — routes live in hub_routes below)
# ---------------------------------------------------------------------------
resource "azurerm_virtual_hub_route_table" "this" {
  for_each = var.hub_route_tables

  name           = "${local.name_base}-vhubrt-${each.key}-${var.name_suffix}"
  virtual_hub_id = azurerm_virtual_hub.this[each.value.hub_key].id
  labels         = length(each.value.labels) > 0 ? each.value.labels : null
}

# ---------------------------------------------------------------------------
# VNet connections (association/propagation + static next-hop-IP routes)
# ---------------------------------------------------------------------------
resource "azurerm_virtual_hub_connection" "this" {
  for_each = var.vnet_connections

  name                      = "${local.name_base}-vhubconn-${each.key}-${var.name_suffix}"
  virtual_hub_id            = azurerm_virtual_hub.this[each.value.hub_key].id
  remote_virtual_network_id = each.value.vnet_id
  internet_security_enabled = each.value.internet_security_enabled

  dynamic "routing" {
    for_each = contains(keys(local.routed_connections), each.key) ? [1] : []
    content {
      associated_route_table_id = (
        each.value.associated_route_table_key != null
        ? azurerm_virtual_hub_route_table.this[each.value.associated_route_table_key].id
        : null
      )

      # Spoke isolation: propagate only to the hub's built-in noneRouteTable.
      # Its ID is constructed from the hub ID (Azure creates it implicitly).
      dynamic "propagated_route_table" {
        for_each = each.value.propagate_none ? [1] : []
        content {
          labels          = ["none"]
          route_table_ids = ["${azurerm_virtual_hub.this[each.value.hub_key].id}/hubRouteTables/noneRouteTable"]
        }
      }

      dynamic "propagated_route_table" {
        for_each = (!each.value.propagate_none && (length(each.value.propagated_route_table_keys) > 0 || length(each.value.propagated_labels) > 0)) ? [1] : []
        content {
          labels = length(each.value.propagated_labels) > 0 ? each.value.propagated_labels : null
          route_table_ids = length(each.value.propagated_route_table_keys) > 0 ? [
            for rt_key in each.value.propagated_route_table_keys :
            azurerm_virtual_hub_route_table.this[rt_key].id
          ] : null
        }
      }

      dynamic "static_vnet_route" {
        for_each = each.value.static_routes
        content {
          name                = static_vnet_route.key
          address_prefixes    = static_vnet_route.value.address_prefixes
          next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Hub routes (custom or DEFAULT route table -> a VNet connection next-hop).
# Standalone resources so they can depend on connections without cycling.
# Default-table routes are how BRANCH (VPN/ER) traffic is steered through a
# firewall services VNet — branches can only associate with the default RT.
# ---------------------------------------------------------------------------
resource "azurerm_virtual_hub_route_table_route" "this" {
  for_each = var.hub_routes

  route_table_id = (
    each.value.route_table_key != null
    ? azurerm_virtual_hub_route_table.this[each.value.route_table_key].id
    : azurerm_virtual_hub.this[each.value.hub_key].default_route_table_id
  )

  name              = each.key
  destinations_type = each.value.destinations_type
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = azurerm_virtual_hub_connection.this[each.value.next_hop_connection_key].id
}

# ---------------------------------------------------------------------------
# Hub router BGP peerings with NVAs in connected VNets (eBGP; hub ASN 65515)
# ---------------------------------------------------------------------------
resource "azurerm_virtual_hub_bgp_connection" "this" {
  for_each = var.bgp_connections

  name           = "${local.name_base}-vhubbgp-${each.key}-${var.name_suffix}"
  virtual_hub_id = azurerm_virtual_hub.this[each.value.hub_key].id
  peer_asn       = each.value.peer_asn
  peer_ip        = each.value.peer_ip

  virtual_network_connection_id = (
    each.value.connection_key != null
    ? azurerm_virtual_hub_connection.this[each.value.connection_key].id
    : null
  )
}

# ---------------------------------------------------------------------------
# Management lock (governance/resource-locks)
# ---------------------------------------------------------------------------
resource "azurerm_management_lock" "vwan" {
  count = var.enable_management_lock ? 1 : 0

  name       = "${local.name_base}-lock-vwan-${var.name_suffix}"
  scope      = azurerm_virtual_wan.this.id
  lock_level = "CanNotDelete"
  notes      = "Connectivity-critical resource protected by framework convention (governance/resource-locks)."
}
