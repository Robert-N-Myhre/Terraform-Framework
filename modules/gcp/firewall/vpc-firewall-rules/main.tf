# ===========================================================================
# GCP Firewall — Classic VPC Firewall Rules
#
# Independently invocable: this module sources no other module in this
# framework. The network is supplied by name/self-link.
#
# Provider API divergence note (see README): GCP firewall rules are
# NETWORK-GLOBAL and stateful, targeting instances by network tag or
# service account — there is no subnet/NIC attachment step (unlike Azure
# NSGs) and no SG-to-SG reference (unlike AWS). source_tags provide a
# rough analogue of AWS SG references for intra-VPC traffic.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-gcp-${var.environment}"

  # Tagging convention note: classic VPC firewall rules are not labelable;
  # the governance contract is honored through naming only here.
}

resource "google_compute_firewall" "this" {
  for_each = var.rules

  project = var.project_id
  name    = "${local.name_base}-fwrule-${each.key}-${var.name_suffix}"
  network = var.network_name

  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges           = each.value.direction == "INGRESS" && length(each.value.source_ranges) > 0 ? each.value.source_ranges : null
  source_tags             = each.value.direction == "INGRESS" && length(each.value.source_tags) > 0 ? each.value.source_tags : null
  source_service_accounts = each.value.direction == "INGRESS" && length(each.value.source_service_accounts) > 0 ? each.value.source_service_accounts : null
  destination_ranges      = each.value.direction == "EGRESS" && length(each.value.destination_ranges) > 0 ? each.value.destination_ranges : null

  target_tags             = length(each.value.target_tags) > 0 ? each.value.target_tags : null
  target_service_accounts = length(each.value.target_service_accounts) > 0 ? each.value.target_service_accounts : null

  dynamic "allow" {
    for_each = each.value.action == "allow" ? each.value.allow_deny : []
    content {
      protocol = allow.value.protocol
      ports    = length(allow.value.ports) > 0 ? allow.value.ports : null
    }
  }

  dynamic "deny" {
    for_each = each.value.action == "deny" ? each.value.allow_deny : []
    content {
      protocol = deny.value.protocol
      ports    = length(deny.value.ports) > 0 ? deny.value.ports : null
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_enabled ? [1] : []
    content {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }
}
