# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: v5.0.0. google_compute_forwarding_rule
#   gained allow_global_access and is_mirroring_collector across 4.x;
#   region_backend_service connection-tracking arguments stabilized in 5.x.
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
