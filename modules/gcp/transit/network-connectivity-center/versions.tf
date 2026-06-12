# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: google_network_connectivity_hub and
#   _spoke graduated from beta in v4.46; VPC-network spokes
#   (linked_vpc_network) require >= 4.74. Pin no lower than 5.0 for
#   stable spoke schemas.
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
