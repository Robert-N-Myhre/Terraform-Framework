# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: v3.0.0 moved rule management from inline
#   firewall blocks to azurerm_firewall_policy + rule_collection_group —
#   this module uses the policy model exclusively (the classic-rules model
#   is deprecated). v4.x may change policy SKU validation.
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
