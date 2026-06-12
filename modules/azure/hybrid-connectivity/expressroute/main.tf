# ===========================================================================
# Azure Hybrid Connectivity — ExpressRoute
#
# Independently invocable: this module sources no other module in this
# framework. The GatewaySubnet (when a gateway is requested) is a plain
# ID input.
#
# NOTE: after the circuit is created, hand the service key to the
# connectivity provider; the circuit stays 'NotProvisioned' until the
# provider completes the L2 work. Gateway-to-circuit connections fail
# until then — gate with connect_gateway_to_circuit.
#
# Provider API divergence note (see README): ExpressRoute = circuit +
# peering + gateway connection. AWS DX = connection + VIFs + DX gateway;
# GCP Interconnect = VLAN attachments on Cloud Routers; OCI FastConnect =
# virtual circuits on a DRG. Azure uniquely requires TWO BGP sessions
# (primary/secondary /30) per peering for SLA.
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
    module_source = "modules/azure/hybrid-connectivity/expressroute"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

# ---------------------------------------------------------------------------
# Circuit
# ---------------------------------------------------------------------------
resource "azurerm_express_route_circuit" "this" {
  name                  = "${local.name_base}-erc-${var.name_suffix}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  service_provider_name = var.service_provider_name
  peering_location      = var.peering_location
  bandwidth_in_mbps     = var.bandwidth_in_mbps

  sku {
    tier   = var.sku_tier
    family = var.sku_family
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Private peering (two BGP sessions: primary + secondary /30)
# ---------------------------------------------------------------------------
resource "azurerm_express_route_circuit_peering" "private" {
  count = var.private_peering.enabled ? 1 : 0

  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.this.name
  resource_group_name           = var.resource_group_name
  peer_asn                      = var.private_peering.peer_asn
  primary_peer_address_prefix   = var.private_peering.primary_peer_address_prefix
  secondary_peer_address_prefix = var.private_peering.secondary_peer_address_prefix
  vlan_id                       = var.private_peering.vlan_id
  shared_key                    = var.private_peering.shared_key
}

# ---------------------------------------------------------------------------
# ExpressRoute gateway (optional) — vnet mode (classic VNet gateway)
# ---------------------------------------------------------------------------
resource "azurerm_public_ip" "gateway" {
  count = var.create_gateway && var.attachment_type == "vnet" ? 1 : 0

  name                = "${local.name_base}-pip-ergw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.all_tags
}

resource "azurerm_virtual_network_gateway" "this" {
  count = var.create_gateway && var.attachment_type == "vnet" ? 1 : 0

  name                = "${local.name_base}-ergw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  type = "ExpressRoute"
  sku  = var.gateway_sku

  ip_configuration {
    name                          = "ipconfig-0"
    public_ip_address_id          = azurerm_public_ip.gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# ExpressRoute gateway (optional) — vhub mode (vWAN hub gateway)
# ---------------------------------------------------------------------------
resource "azurerm_express_route_gateway" "this" {
  count = var.create_gateway && var.attachment_type == "vhub" ? 1 : 0

  name                = "${local.name_base}-vhubergw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_hub_id      = var.virtual_hub_id
  scale_units         = var.er_gateway_scale_units

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Gateway <-> circuit connection (only after provider provisioning)
# vnet mode uses a VNet gateway connection; vhub mode uses the vWAN
# express_route_connection against the circuit's private peering.
# Note: like all branch attachments, the vhub connection associates with
# the hub's DEFAULT route table — steer branch traffic through an NVA via
# default-table hub_routes in azure/transit/vwan.
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network_gateway_connection" "this" {
  count = var.create_gateway && var.attachment_type == "vnet" && var.connect_gateway_to_circuit ? 1 : 0

  name                = "${local.name_base}-erconn-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this[0].id
  express_route_circuit_id   = azurerm_express_route_circuit.this.id

  depends_on = [azurerm_express_route_circuit_peering.private]

  tags = local.all_tags
}

resource "azurerm_express_route_connection" "this" {
  count = var.create_gateway && var.attachment_type == "vhub" && var.connect_gateway_to_circuit ? 1 : 0

  name                             = "${local.name_base}-erconn-${var.name_suffix}"
  express_route_gateway_id         = azurerm_express_route_gateway.this[0].id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.private[0].id
}

# ---------------------------------------------------------------------------
# Management lock (governance/resource-locks)
# ---------------------------------------------------------------------------
resource "azurerm_management_lock" "circuit" {
  count = var.enable_management_lock ? 1 : 0

  name       = "${local.name_base}-lock-erc-${var.name_suffix}"
  scope      = azurerm_express_route_circuit.this.id
  lock_level = "CanNotDelete"
  notes      = "Connectivity-critical resource protected by framework convention (governance/resource-locks)."
}
