# ===========================================================================
# Example: COMPOSITION — core-network + NSGs.
# Both modules are independently invocable; composition happens HERE by
# wiring core-network subnet outputs into the NSG module's subnet_ids.
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
  name     = "rg-${var.prefix}-${var.environment}-network"
  location = var.location
}

module "core_network" {
  source = "../../../modules/azure/core-network"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = [var.address_space]

  subnets = {
    app  = { address_prefixes = [cidrsubnet(var.address_space, 8, 10)] }
    data = { address_prefixes = [cidrsubnet(var.address_space, 8, 20)] }
  }

  enable_management_lock = false
}

module "nsgs" {
  source = "../../../modules/azure/firewall/nsgs"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location

  network_security_groups = {
    app = {
      # Composition point: consumer wires output -> input.
      subnet_ids = [module.core_network.subnet_ids["app"]]
      rules = {
        allow-https-in = {
          priority                     = 100
          direction                    = "Inbound"
          access                       = "Allow"
          protocol                     = "Tcp"
          destination_port_ranges      = ["443"]
          source_address_prefixes      = ["Internet"]
          destination_address_prefixes = [cidrsubnet(var.address_space, 8, 10)]
        }
      }
    }
    data = {
      subnet_ids = [module.core_network.subnet_ids["data"]]
      rules = {
        allow-sql-from-app = {
          priority                     = 100
          direction                    = "Inbound"
          access                       = "Allow"
          protocol                     = "Tcp"
          destination_port_ranges      = ["1433"]
          source_address_prefixes      = [cidrsubnet(var.address_space, 8, 10)]
          destination_address_prefixes = [cidrsubnet(var.address_space, 8, 20)]
        }
        deny-all-in = {
          priority  = 4096
          direction = "Inbound"
          access    = "Deny"
          protocol  = "*"
        }
      }
    }
  }
}
