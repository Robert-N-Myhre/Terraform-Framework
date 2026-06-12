# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0.
#   oci_core_virtual_circuit schemas are stable across 5.x. Physical
#   cross-connects (dedicated model) and partner provisioning are
#   out-of-band steps Terraform cannot perform.
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
