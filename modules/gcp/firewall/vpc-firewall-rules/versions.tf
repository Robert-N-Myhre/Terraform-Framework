# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: v5.0.0. google_compute_firewall is
#   long-stable; v5 changed default logging metadata handling. The newer
#   "network firewall policy" resource family (Cloud NGFW) is a separate
#   API — this module manages classic VPC firewall rules only.
# Rationale: "~> 5.0" accepts all 5.x releases while excluding the next major.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
