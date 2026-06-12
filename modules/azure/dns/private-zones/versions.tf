# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: v3.0.0. azurerm_private_dns_zone and
#   virtual_network_link are stable across 3.x; record resources renamed
#   (azurerm_private_dns_*_record) at the 2.x->3.x boundary.
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
