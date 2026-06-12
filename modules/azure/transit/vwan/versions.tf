# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: v3.0.0. azurerm_virtual_hub and
#   azurerm_virtual_hub_connection routing blocks were reworked mid-3.x
#   (static_vnet_route, routing_configuration) — pin no lower than 3.40.
#   Hub provisioning takes 20-30 minutes; plan timeouts accordingly.
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
