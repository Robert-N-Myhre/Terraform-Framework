# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/aws v5.31.0
# Known breaking-change boundary: v5.0.0. aws_lb target group health-check
#   defaults changed across the 4.x->5.x boundary, and 5.x added
#   enforce_security_group_inbound_rules_on_private_link_traffic. Re-validate
#   listener default_action handling before crossing into 6.x.
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
