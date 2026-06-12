# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: v3.0.0. azurerm_network_security_rule is
#   stable across 3.x; v4.x tightens validation on combined singular/plural
#   rule arguments (source_address_prefix vs _prefixes) — this module always
#   uses the plural forms to stay forward-compatible.
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
