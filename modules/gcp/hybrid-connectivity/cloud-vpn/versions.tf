# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/google v5.10.0
# Known breaking-change boundary: v5.0.0. HA VPN resources
#   (google_compute_ha_vpn_gateway, vpn_tunnel with vpn_gateway_interface,
#   router_peer) are stable across 5.x. Classic (target) VPN gateways are
#   deprecated — this module implements HA VPN only.
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
