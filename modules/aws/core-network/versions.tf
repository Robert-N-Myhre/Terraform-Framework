# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0 (default_tags engine rework, removal
#   of deprecated EC2-Classic attributes). v6.x is expected to change the
#   flow-log destination schema; do not widen the range past ~> 5.0 without
#   re-validating aws_flow_log and aws_nat_gateway behavior.
# Rationale: "~> 5.0" accepts all 5.x patch/minor releases (bug fixes, new
#   resources) while excluding the next major version, which may contain
#   breaking schema changes.
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
