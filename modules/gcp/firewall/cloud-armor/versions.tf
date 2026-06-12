# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: v5.0.0. google_compute_security_policy
#   adaptive-protection and rate-limit blocks stabilized late in 4.x;
#   preconfigured WAF expression names (e.g. sqli-v33-stable) track
#   Google's rule-set versions independently of the provider.
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
