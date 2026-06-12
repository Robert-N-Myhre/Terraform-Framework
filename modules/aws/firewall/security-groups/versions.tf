# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0 introduced the standalone
#   aws_vpc_security_group_ingress_rule / aws_vpc_security_group_egress_rule
#   resources this module depends on; they do not exist in 4.x. Do not widen
#   below 5.0. v6.x may retire inline rule arguments entirely — re-validate
#   before crossing that boundary.
# Rationale: "~> 5.0" accepts all 5.x releases while excluding the next major.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
