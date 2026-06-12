# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0. aws_networkfirewall_* resources
#   gained encryption_configuration and policy override arguments during the
#   4.x line; the 5.x line is required for stable stateful rule ordering
#   (STRICT_ORDER) support used here.
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
