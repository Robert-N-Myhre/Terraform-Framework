# ===========================================================================
# GCP DNS — DNS Server Policy
#
# Independently invocable: this module sources no other module in this
# framework. Network self-links are plain inputs.
#
# Provider API divergence note (see README): GCP's DNS policy fills the role
# of AWS/Azure INBOUND resolver endpoints (enable_inbound_forwarding
# allocates forwarder IPs per network) plus network-wide alternative name
# servers. Outbound per-domain forwarding lives in forwarding ZONES
# (gcp/dns/private-zones), not here. Only one policy per network.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-gcp-${var.environment}"

  # Tagging convention note: DNS policies are not labelable; the governance
  # contract is honored through naming only here.
}

resource "google_dns_policy" "this" {
  project = var.project_id
  name    = "${local.name_base}-dnspolicy-${var.name_suffix}"

  enable_inbound_forwarding = var.enable_inbound_forwarding
  enable_logging            = var.enable_logging

  dynamic "alternative_name_server_config" {
    for_each = length(var.alternative_name_servers) > 0 ? [1] : []
    content {
      dynamic "target_name_servers" {
        for_each = var.alternative_name_servers
        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          forwarding_path = target_name_servers.value.forwarding_path
        }
      }
    }
  }

  dynamic "networks" {
    for_each = toset(var.network_self_links)
    content {
      network_url = networks.value
    }
  }
}
