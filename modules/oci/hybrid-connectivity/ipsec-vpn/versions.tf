# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0. oci_core_ipsec and the
#   oci_core_ipsec_connection_tunnel_management resource (tunnel BGP/PSK
#   configuration) are stable across 5.x. Each IPSec connection always
#   carries TWO tunnels; tunnels are managed (adopted), not created.
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
