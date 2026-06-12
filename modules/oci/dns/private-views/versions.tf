# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0. oci_dns_view / oci_dns_zone with
#   scope = "PRIVATE" are stable across 5.x; oci_dns_rrset replaced
#   per-record resources as the recommended record management path in 4.x.
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
