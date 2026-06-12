# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: the "upgraded DRG" model (DRG route
#   tables, route distributions, typed attachments) replaced classic DRGs
#   at provider v4.x; v5.x schemas are stable. Classic DRGs cannot be
#   managed by this module.
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
