# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: v3.0.0. azurerm_virtual_network_gateway
#   generation/SKU validation tightened during 3.x. Gateway creation takes
#   30-45 minutes; active-active requires two ip_configurations and a
#   compatible SKU (VpnGw1+ generation 1/2, not Basic).
# Rationale: "~> 3.80" tracks late-3.x patch releases while excluding 4.0.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}
