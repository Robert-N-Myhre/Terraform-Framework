# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: the network_firewall resource family
#   moved to LIST-BASED policy sub-resources (address lists, service
#   lists, security rules as standalone resources) at provider v5.0 —
#   pre-5.0 inline policy documents do not migrate automatically. Do not
#   pin below 5.0.
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
