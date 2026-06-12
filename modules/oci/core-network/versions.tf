# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0 (resource discovery rework and
#   default-tag handling). oci_core_vcn / subnet / route_table schemas are
#   stable across 5.x. NOTE the provider source is oracle/oci, not
#   hashicorp/oci.
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
