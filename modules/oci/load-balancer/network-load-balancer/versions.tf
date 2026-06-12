# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0. The
#   oci_network_load_balancer_* family (separate service/API from
#   oci_load_balancer_*) is stable across 5.x. NLB is always
#   non-proxying; client IP is preserved by default.
# Rationale: "~> 5.0" accepts all 5.x releases while excluding the next major.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}
