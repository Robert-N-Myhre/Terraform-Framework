# ===========================================================================
# Example: Azure private DNS ONLY — private zone + VNet link against an
# EXISTING resource group and VNet.
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

module "private_dns" {
  source = "../../../modules/azure/dns/private-zones"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  resource_group_name = var.resource_group_name

  private_zones = {
    internal = {
      domain_name = var.domain_name
      vnet_links = {
        main = { vnet_id = var.vnet_id }
      }
      a_records = {
        api = { name = "api", records = ["10.40.10.15"] }
      }
    }
  }
}
