# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: v3.0.0. azurerm_express_route_circuit
#   SKU/family validation and the circuit_peering API surface are stable
#   across 3.x. Physical L2 provisioning by the connectivity provider is
#   an out-of-band step — the circuit reports 'NotProvisioned' until done.
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
