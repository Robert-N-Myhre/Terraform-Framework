# ===========================================================================
# Example: COMPOSITION — vWAN hub with a THIRD-PARTY firewall services VNet
# (Palo Alto VM-Series pattern).
#
# Routing intent is NOT used: it only supports in-hub next-hops (Azure
# Firewall, integrated hub NVAs, SaaS Cloud NGFW). A VM-Series fleet in a
# connected services VNet is steered with hub route tables + connection
# static routes instead — all wired HERE in the example root. The VM-Series
# VMs themselves (compute, licensing, PAN-OS bootstrap) are out of framework
# scope; this example provides the network seams they plug into.
# ===========================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.prefix}-${var.environment}-vwan-nva"
  location = var.location
}

# ---------------------------------------------------------------------------
# Firewall services VNet — untrust / trust / mgmt subnets for the VM-Series
# ---------------------------------------------------------------------------
module "firewall_vnet" {
  source = "../../../modules/azure/core-network"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center
  name_suffix = "fw"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = [var.firewall_vnet_cidr]

  subnets = {
    untrust = { address_prefixes = [cidrsubnet(var.firewall_vnet_cidr, 8, 0)] }
    trust   = { address_prefixes = [cidrsubnet(var.firewall_vnet_cidr, 8, 1)] }
    mgmt    = { address_prefixes = [cidrsubnet(var.firewall_vnet_cidr, 8, 2)] }
  }

  enable_management_lock = false
}

# ---------------------------------------------------------------------------
# Spoke VNets (workloads)
# ---------------------------------------------------------------------------
module "spoke1_vnet" {
  source = "../../../modules/azure/core-network"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center
  name_suffix = "spoke1"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = [var.spoke1_cidr]

  subnets = {
    app = { address_prefixes = [cidrsubnet(var.spoke1_cidr, 8, 0)] }
  }

  enable_management_lock = false
}

module "spoke2_vnet" {
  source = "../../../modules/azure/core-network"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center
  name_suffix = "spoke2"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = [var.spoke2_cidr]

  subnets = {
    app = { address_prefixes = [cidrsubnet(var.spoke2_cidr, 8, 0)] }
  }

  enable_management_lock = false
}

# ---------------------------------------------------------------------------
# Internal LB sandwich (trust side) — HA-ports rule across the VM-Series
# trust NICs. NIC pool membership is the VM-Series deployment's job: it
# associates against module.firewall_ilb.backend_ids["vmseries-trust"].
# ---------------------------------------------------------------------------
module "firewall_ilb" {
  source = "../../../modules/azure/load-balancer/load-balancer"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center
  name_suffix = "fwtrust"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location

  frontend_type      = "internal"
  subnet_id          = module.firewall_vnet.subnet_ids["trust"]
  private_ip_address = local.firewall_ilb_ip

  backend_pools = ["vmseries-trust"]

  health_probes = {
    # VM-Series health: an interface-mgmt profile answering on the trust NIC.
    pathmonitor = { port = 443 }
  }

  rules = {
    ha-ports = {
      frontend_port      = 0
      backend_port       = 0
      protocol           = "All"
      backend_pool_key   = "vmseries-trust"
      probe_key          = "pathmonitor"
      enable_floating_ip = false
    }
  }
}

locals {
  # Trust-side ILB frontend — the next-hop for all inspected traffic.
  firewall_ilb_ip = cidrhost(cidrsubnet(var.firewall_vnet_cidr, 8, 1), 100)

  inspected_destinations = ["0.0.0.0/0", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  private_destinations   = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# ---------------------------------------------------------------------------
# vWAN: hub + custom 'spokes' route table + connections + steering routes
# ---------------------------------------------------------------------------
module "vwan" {
  source = "../../../modules/azure/transit/vwan"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location

  hubs = {
    main = { location = var.location, address_prefix = var.hub_cidr }
  }

  hub_route_tables = {
    spokes = { hub_key = "main" }
  }

  vnet_connections = {
    # Firewall services VNet: default-RT association, normal propagation,
    # and the next-hop-IP static route to the trust ILB for traffic
    # entering this VNet via the hub.
    firewall = {
      hub_key = "main"
      vnet_id = module.firewall_vnet.network_id
      static_routes = {
        inspect = {
          address_prefixes    = local.inspected_destinations
          next_hop_ip_address = local.firewall_ilb_ip
        }
      }
    }

    # Spokes: associate with the custom RT, propagate to none (isolation).
    spoke1 = {
      hub_key                    = "main"
      vnet_id                    = module.spoke1_vnet.network_id
      associated_route_table_key = "spokes"
      propagate_none             = true
    }
    spoke2 = {
      hub_key                    = "main"
      vnet_id                    = module.spoke2_vnet.network_id
      associated_route_table_key = "spokes"
      propagate_none             = true
    }
  }

  hub_routes = {
    # Spoke-originated traffic (internet + east-west) -> firewall connection.
    spokes-via-fw = {
      hub_key                 = "main"
      route_table_key         = "spokes"
      destinations            = local.inspected_destinations
      next_hop_connection_key = "firewall"
    }
    # Branch (VPN/ER) traffic lives on the DEFAULT route table — steer the
    # private ranges through the firewall there. (Attach hub gateways with
    # the hybrid modules in vhub mode; see README.)
    branches-via-fw = {
      hub_key                 = "main"
      route_table_key         = null
      destinations            = local.private_destinations
      next_hop_connection_key = "firewall"
    }
  }

  enable_management_lock = false
}
