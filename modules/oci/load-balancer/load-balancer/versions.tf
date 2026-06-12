# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0. oci_load_balancer_* resources are
#   stable; flexible shapes (shape = "flexible" + shape_details) replaced
#   the fixed 10/100/400/8000 Mbps shapes, which are deprecated — this
#   module uses flexible shapes exclusively.
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
