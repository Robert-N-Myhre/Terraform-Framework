# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0. oci_core_security_list rule
#   blocks (ingress_security_rules / egress_security_rules) are stable;
#   stateless rules and ICMP options unchanged since 4.x. Provider source
#   is oracle/oci, not hashicorp/oci.
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
