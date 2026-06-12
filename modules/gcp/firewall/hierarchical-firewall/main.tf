# ===========================================================================
# GCP Firewall — Hierarchical Firewall Policy (org/folder level)
#
# Independently invocable: this module sources no other module in this
# framework.
#
# Provider API divergence note (see README): Hierarchical policies evaluate
# BEFORE project VPC rules and cascade to all projects under the attached
# node — there is no AWS/OCI equivalent (closest: AWS Firewall Manager,
# which is an account-management service, not a data-plane resource), and
# Azure's analogue (Azure Firewall Manager policies) governs Azure
# Firewall instances rather than NSGs. Rules here cannot target network
# tags — only service accounts.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-gcp-${var.environment}"

  # Tagging convention note: firewall policies are not labelable; the
  # governance contract is honored through naming only here.
}

resource "google_compute_firewall_policy" "this" {
  parent      = var.parent_node
  short_name  = "${local.name_base}-hfwpolicy-${var.name_suffix}"
  description = var.policy_description
}

resource "google_compute_firewall_policy_rule" "this" {
  for_each = var.rules

  firewall_policy = google_compute_firewall_policy.this.id

  priority    = each.value.priority
  direction   = each.value.direction
  action      = each.value.action
  description = each.value.description

  enable_logging          = each.value.enable_logging
  target_service_accounts = length(each.value.target_service_accounts) > 0 ? each.value.target_service_accounts : null

  match {
    src_ip_ranges  = each.value.direction == "INGRESS" && length(each.value.src_ip_ranges) > 0 ? each.value.src_ip_ranges : null
    dest_ip_ranges = each.value.direction == "EGRESS" && length(each.value.dest_ip_ranges) > 0 ? each.value.dest_ip_ranges : null

    dynamic "layer4_configs" {
      for_each = each.value.layer4_configs
      content {
        ip_protocol = layer4_configs.value.ip_protocol
        ports       = length(layer4_configs.value.ports) > 0 ? layer4_configs.value.ports : null
      }
    }
  }
}

resource "google_compute_firewall_policy_association" "this" {
  for_each = var.associations

  name              = "${local.name_base}-hfwassoc-${each.key}-${var.name_suffix}"
  firewall_policy   = google_compute_firewall_policy.this.id
  attachment_target = each.value
}
