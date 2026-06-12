# ===========================================================================
# OCI Firewall — OCI Network Firewall (Palo Alto-backed appliance)
#
# Independently invocable: this module sources no other module in this
# framework. The firewall subnet is a plain OCID input; steering traffic
# to the firewall IP via VCN route rules is the consumer's job.
#
# Provider API divergence note (see README): OCI Network Firewall composes
# a policy from LIST sub-resources (address lists, service lists,
# security rules) attached to a policy shell — vs AWS Network Firewall's
# Suricata rules_string, Azure Firewall's rule collection groups, and
# GCP's policy attachments. Rule syntax does not port across clouds.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-oci-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/oci/firewall/network-firewall"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

# ---------------------------------------------------------------------------
# Policy shell + list sub-resources
# ---------------------------------------------------------------------------
resource "oci_network_firewall_network_firewall_policy" "this" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-nfwpolicy-${var.name_suffix}"

  freeform_tags = local.all_tags
}

resource "oci_network_firewall_network_firewall_policy_address_list" "this" {
  for_each = var.address_lists

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.this.id
  name                       = each.key
  type                       = "IP"
  addresses                  = each.value
}

resource "oci_network_firewall_network_firewall_policy_service" "this" {
  # Flatten service lists into individual services: "<list>/<service>"
  for_each = merge([
    for list_name, services in var.service_lists : {
      for svc_name, svc in services :
      "${list_name}/${svc_name}" => merge(svc, { list_name = list_name, svc_name = svc_name })
    }
  ]...)

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.this.id
  name                       = replace(each.key, "/", "-")
  type                       = each.value.protocol == "TCP" ? "TCP_SERVICE" : "UDP_SERVICE"

  port_ranges {
    minimum_port = each.value.min_port
    maximum_port = coalesce(each.value.max_port, each.value.min_port)
  }
}

resource "oci_network_firewall_network_firewall_policy_service_list" "this" {
  for_each = var.service_lists

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.this.id
  name                       = each.key

  services = [
    for svc_name in keys(each.value) :
    oci_network_firewall_network_firewall_policy_service.this["${each.key}/${svc_name}"].name
  ]
}

resource "oci_network_firewall_network_firewall_policy_security_rule" "this" {
  for_each = var.security_rules

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.this.id
  name                       = each.key
  action                     = each.value.action

  condition {
    source_address = [
      for list_name in each.value.source_address_lists :
      oci_network_firewall_network_firewall_policy_address_list.this[list_name].name
    ]
    destination_address = [
      for list_name in each.value.destination_address_lists :
      oci_network_firewall_network_firewall_policy_address_list.this[list_name].name
    ]
    service = [
      for list_name in each.value.service_lists :
      oci_network_firewall_network_firewall_policy_service_list.this[list_name].name
    ]
  }
}

# ---------------------------------------------------------------------------
# Firewall instance
# ---------------------------------------------------------------------------
resource "oci_network_firewall_network_firewall" "this" {
  compartment_id             = var.compartment_id
  display_name               = "${local.name_base}-nfw-${var.name_suffix}"
  subnet_id                  = var.firewall_subnet_id
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.this.id
  availability_domain        = var.availability_domain
  ipv4address                = var.ipv4_address

  freeform_tags = local.all_tags

  depends_on = [oci_network_firewall_network_firewall_policy_security_rule.this]
}
