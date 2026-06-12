# ===========================================================================
# Example: Azure core network ONLY — VNet, subnets, route tables.
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

  nat_gateway_subnet_keys = ["app"]

  # Keep teardown easy in a lab; set true (default) for real environments.
  enable_management_lock = false
}
