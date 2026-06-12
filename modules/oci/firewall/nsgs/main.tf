# ===========================================================================
# OCI Firewall — Network Security Groups (VNIC-level)
#
# Independently invocable: this module sources no other module in this
# framework. The VCN is supplied by OCID; VNIC membership is declared
# where the workloads are managed.
#
# Provider API divergence note (see README): OCI NSGs are VNIC-scoped with
# standalone rule resources supporting NSG-to-NSG references — the
# closest analogue to AWS security groups. OCI uniquely offers BOTH this
# model and subnet-level security lists; rules from both apply (union).
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
    module_source = "modules/oci/firewall/nsgs"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  rules = merge([
    for nsg_key, nsg in var.network_security_groups : {
      for rule_key, rule in nsg.rules :
      "${nsg_key}/${rule_key}" => merge(rule, { nsg_key = nsg_key })
    }
  ]...)
}

resource "oci_core_network_security_group" "this" {
  for_each = var.network_security_groups

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_base}-nsg-${each.key}-${var.name_suffix}"

  freeform_tags = local.all_tags
}

resource "oci_core_network_security_group_security_rule" "this" {
  for_each = local.rules

  network_security_group_id = oci_core_network_security_group.this[each.value.nsg_key].id

  direction   = each.value.direction
  protocol    = each.value.protocol
  description = each.value.description
  stateless   = each.value.stateless

  # Source (INGRESS) / destination (EGRESS) resolution — exactly one style.
  source = each.value.direction == "INGRESS" ? coalesce(
    each.value.cidr,
    each.value.service,
    each.value.nsg_key != null ? oci_core_network_security_group.this[each.value.nsg_key].id : null,
    each.value.external_nsg_id
  ) : null

  source_type = each.value.direction == "INGRESS" ? (
    each.value.cidr != null ? "CIDR_BLOCK" :
    each.value.service != null ? "SERVICE_CIDR_BLOCK" :
    "NETWORK_SECURITY_GROUP"
  ) : null

  destination = each.value.direction == "EGRESS" ? coalesce(
    each.value.cidr,
    each.value.service,
    each.value.nsg_key != null ? oci_core_network_security_group.this[each.value.nsg_key].id : null,
    each.value.external_nsg_id
  ) : null

  destination_type = each.value.direction == "EGRESS" ? (
    each.value.cidr != null ? "CIDR_BLOCK" :
    each.value.service != null ? "SERVICE_CIDR_BLOCK" :
    "NETWORK_SECURITY_GROUP"
  ) : null

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" && each.value.tcp_min != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.tcp_min
        max = coalesce(each.value.tcp_max, each.value.tcp_min)
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "17" && each.value.udp_min != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.udp_min
        max = coalesce(each.value.udp_max, each.value.udp_min)
      }
    }
  }

  dynamic "icmp_options" {
    for_each = each.value.protocol == "1" && each.value.icmp_type != null ? [1] : []
    content {
      type = each.value.icmp_type
      code = each.value.icmp_code
    }
  }
}
