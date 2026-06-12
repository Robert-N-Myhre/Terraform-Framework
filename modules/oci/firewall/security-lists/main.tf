# ===========================================================================
# OCI Firewall — Security Lists (subnet-level)
#
# Independently invocable: this module sources no other module in this
# framework. The VCN is supplied by OCID; attaching lists to subnets
# (security_list_ids on oci_core_subnet) happens in the consumer root.
#
# Provider API divergence note (see README): OCI security lists apply at
# the SUBNET level and are stateful by default with per-rule stateless
# opt-out — the inverse of AWS NACLs (always stateless, subnet-level)
# and distinct from AWS SGs / Azure NSGs / GCP rules. Protocols are IANA
# numbers as strings ("6", "17", "1") rather than names.
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
    module_source = "modules/oci/firewall/security-lists"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

resource "oci_core_security_list" "this" {
  for_each = var.security_lists

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_base}-seclist-${each.key}-${var.name_suffix}"

  dynamic "ingress_security_rules" {
    for_each = each.value.ingress_rules
    content {
      protocol    = ingress_security_rules.value.protocol
      source      = ingress_security_rules.value.source
      source_type = ingress_security_rules.value.source_type
      stateless   = ingress_security_rules.value.stateless
      description = ingress_security_rules.value.description

      dynamic "tcp_options" {
        for_each = ingress_security_rules.value.protocol == "6" && ingress_security_rules.value.tcp_min != null ? [1] : []
        content {
          min = ingress_security_rules.value.tcp_min
          max = coalesce(ingress_security_rules.value.tcp_max, ingress_security_rules.value.tcp_min)
        }
      }

      dynamic "udp_options" {
        for_each = ingress_security_rules.value.protocol == "17" && ingress_security_rules.value.udp_min != null ? [1] : []
        content {
          min = ingress_security_rules.value.udp_min
          max = coalesce(ingress_security_rules.value.udp_max, ingress_security_rules.value.udp_min)
        }
      }

      dynamic "icmp_options" {
        for_each = ingress_security_rules.value.protocol == "1" && ingress_security_rules.value.icmp_type != null ? [1] : []
        content {
          type = ingress_security_rules.value.icmp_type
          code = ingress_security_rules.value.icmp_code
        }
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.egress_rules
    content {
      protocol         = egress_security_rules.value.protocol
      destination      = egress_security_rules.value.destination
      destination_type = egress_security_rules.value.destination_type
      stateless        = egress_security_rules.value.stateless
      description      = egress_security_rules.value.description

      dynamic "tcp_options" {
        for_each = egress_security_rules.value.protocol == "6" && egress_security_rules.value.tcp_min != null ? [1] : []
        content {
          min = egress_security_rules.value.tcp_min
          max = coalesce(egress_security_rules.value.tcp_max, egress_security_rules.value.tcp_min)
        }
      }

      dynamic "udp_options" {
        for_each = egress_security_rules.value.protocol == "17" && egress_security_rules.value.udp_min != null ? [1] : []
        content {
          min = egress_security_rules.value.udp_min
          max = coalesce(egress_security_rules.value.udp_max, egress_security_rules.value.udp_min)
        }
      }

      dynamic "icmp_options" {
        for_each = egress_security_rules.value.protocol == "1" && egress_security_rules.value.icmp_type != null ? [1] : []
        content {
          type = egress_security_rules.value.icmp_type
          code = egress_security_rules.value.icmp_code
        }
      }
    }
  }

  freeform_tags = local.all_tags
}
