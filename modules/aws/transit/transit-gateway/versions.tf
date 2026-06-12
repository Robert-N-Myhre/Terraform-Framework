# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0. The ec2_transit_gateway_* family
#   gained appliance-mode and security-group-referencing arguments through
#   the 5.x line; default route table association/propagation flags have
#   been stable since 4.x but tag handling changed at 5.0.
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
