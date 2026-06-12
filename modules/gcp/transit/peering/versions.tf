# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: v5.0.0. google_compute_network_peering
#   import/export custom-route flags are stable; stack_type was added in
#   late 4.x. Peering requires BOTH sides created before either becomes
#   ACTIVE — this module creates both.
# Rationale: "~> 5.0" accepts all 5.x releases while excluding the next major.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
