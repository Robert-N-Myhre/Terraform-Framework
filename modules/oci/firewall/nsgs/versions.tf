# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0.
#   oci_core_network_security_group(_security_rule) are stable across 5.x.
#   NSG rules are standalone resources (unlike security-list inline rules),
#   which enables NSG-to-NSG references.
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
