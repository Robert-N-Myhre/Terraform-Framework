# ===========================================================================
# Example: Azure NSGs ONLY — demonstrates independent invocability.
# Targets an EXISTING resource group and (optionally) existing subnets.
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

module "nsgs" {
  source = "../../../modules/azure/firewall/nsgs"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  resource_group_name = var.resource_group_name
  location            = var.location

  network_security_groups = {
    app = {
      subnet_ids = var.subnet_ids
      rules = {
        allow-https-in = {
          priority                = 100
          direction               = "Inbound"
          access                  = "Allow"
          protocol                = "Tcp"
          destination_port_ranges = ["443"]
          source_address_prefixes = ["Internet"]
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
