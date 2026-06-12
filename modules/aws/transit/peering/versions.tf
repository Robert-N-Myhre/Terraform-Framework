# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0. aws_vpc_peering_connection and the
#   accepter/options resources are long-stable; the tagging engine changed
#   at 5.0. Cross-account acceptance still requires a second provider alias
#   in the consumer root — out of scope for a leaf module.
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
