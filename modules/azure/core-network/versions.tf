# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: v3.0.0 removed the legacy network blocks;
#   v4.x changes subnet inline-vs-standalone semantics and provider feature
#   flag defaults. This module uses STANDALONE azurerm_subnet resources
#   (never inline subnet blocks on the VNet) — do not mix the two styles.
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
