# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: v5.0.0. google_compute_firewall_policy*
#   resources moved out of beta during 4.x; association/attachment naming
#   stabilized in 5.x. Requires org-level IAM
#   (roles/compute.orgSecurityResourceAdmin) — project credentials alone
#   cannot apply this module.
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
