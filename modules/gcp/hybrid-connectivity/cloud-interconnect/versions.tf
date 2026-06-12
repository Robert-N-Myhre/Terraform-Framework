# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: v5.0.0.
#   google_compute_interconnect_attachment encryption and stack_type
#   arguments stabilized in 5.x. Dedicated Interconnect (the physical
#   port) is ordered out-of-band; this module manages PARTNER and
#   DEDICATED attachments plus their Cloud Router BGP sessions.
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
