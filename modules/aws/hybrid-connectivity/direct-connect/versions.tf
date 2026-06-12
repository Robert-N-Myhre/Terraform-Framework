# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0. aws_dx_gateway_association
#   allowed-prefix handling and dx_connection encryption arguments changed
#   in late 4.x; 5.x is stable. Physical cross-connect provisioning (LOA)
#   is an out-of-band manual/partner step Terraform cannot perform.
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
