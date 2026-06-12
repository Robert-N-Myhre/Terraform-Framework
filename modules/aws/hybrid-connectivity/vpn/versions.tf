# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0. aws_vpn_connection tunnel options
#   (IKE versions, phase1/phase2 algorithm lists, tunnel inside CIDRs) were
#   reworked across 4.x and are stable in 5.x. Tunnel pre-shared keys are
#   sensitive — never log plan output from this module.
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
