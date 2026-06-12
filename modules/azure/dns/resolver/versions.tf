# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: hashicorp/azurerm v3.85.0
# Known breaking-change boundary: azurerm_private_dns_resolver_* resources
#   were introduced at v3.40 — do not pin below that. The DNS Private
#   Resolver service requires dedicated delegated subnets
#   (Microsoft.Network/dnsResolvers).
# Rationale: "~> 3.80" (>= 3.40 implied) tracks late-3.x while excluding 4.0.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}
