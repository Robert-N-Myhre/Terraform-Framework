# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0. NLB security group support
#   (attach-at-create) arrived in 5.x and cannot be retrofitted to an
#   existing NLB without replacement — a 4.x-created NLB will plan a
#   destroy/create if security groups are added under 5.x.
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
