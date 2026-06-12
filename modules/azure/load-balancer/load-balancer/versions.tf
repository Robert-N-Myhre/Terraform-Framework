# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: v3.0.0 removed the Basic LB default —
#   this module pins SKU to Standard explicitly (Basic retires Sept 2025).
#   azurerm_lb_* child resources dropped resource_group_name arguments
#   during 3.x; this module uses the loadbalancer_id-based forms only.
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
