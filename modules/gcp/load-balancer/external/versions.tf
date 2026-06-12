# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: v5.0.0. The global external HTTP(S) LB
#   chain (forwarding rule -> target proxy -> URL map -> backend service)
#   is stable; EXTERNAL_MANAGED became the recommended scheme in 4.x and
#   is the default here. Managed certs provision only after DNS points at
#   the LB IP.
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
