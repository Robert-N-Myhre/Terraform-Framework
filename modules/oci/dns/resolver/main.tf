# ===========================================================================
# OCI DNS — VCN Resolver (endpoints, attached views, forwarding rules)
#
# Independently invocable: this module sources no other module in this
# framework. The resolver OCID (implicit per VCN), subnet OCIDs, and view
# OCIDs are plain inputs.
#
# NOTE: OCI creates the VCN resolver implicitly — this module MANAGES the
# existing resolver rather than creating one. Obtain its OCID via the
# oci_core_vcn_dns_resolver_association data source in the consumer root.
#
# Provider API divergence note (see README): OCI hangs everything off the
# per-VCN resolver: views (zone visibility), listening endpoints
# (inbound), forwarding endpoints (outbound), and rules — where AWS/Azure
# split these across separate endpoint/rule/association resources and GCP
# uses zone types + server policies.
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
    module_source = "modules/oci/dns/resolver"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

# ---------------------------------------------------------------------------
# Endpoints (must exist before rules can reference them)
# ---------------------------------------------------------------------------
resource "oci_dns_resolver_endpoint" "listening" {
  for_each = var.listening_endpoints

  resolver_id        = var.resolver_id
  name               = "listen-${each.key}"
  endpoint_type      = "VNIC"
  scope              = "PRIVATE"
  is_listening       = true
  is_forwarding      = false
  subnet_id          = each.value.subnet_id
  listening_address  = each.value.listening_address
  nsg_ids            = each.value.nsg_ids
}

resource "oci_dns_resolver_endpoint" "forwarding" {
  for_each = var.forwarding_endpoints

  resolver_id        = var.resolver_id
  name               = "forward-${each.key}"
  endpoint_type      = "VNIC"
  scope              = "PRIVATE"
  is_listening       = false
  is_forwarding      = true
  subnet_id          = each.value.subnet_id
  forwarding_address = each.value.forwarding_address
  nsg_ids            = each.value.nsg_ids
}

# ---------------------------------------------------------------------------
# Resolver management: attached views + forwarding rules
# (Views and rules live ON the resolver resource in OCI.)
# ---------------------------------------------------------------------------
resource "oci_dns_resolver" "this" {
  resolver_id  = var.resolver_id
  scope        = "PRIVATE"
  display_name = "${local.name_base}-resolver-${var.name_suffix}"

  dynamic "attached_views" {
    for_each = var.attached_view_ids
    content {
      view_id = attached_views.value
    }
  }

  dynamic "rules" {
    for_each = var.forward_rules
    content {
      action                = "FORWARD"
      qname_cover_conditions = rules.value.domain_names
      destination_addresses = rules.value.destination_addresses
      source_endpoint_name  = oci_dns_resolver_endpoint.forwarding[rules.value.forwarding_endpoint_key].name
    }
  }

  freeform_tags = local.all_tags

  depends_on = [
    oci_dns_resolver_endpoint.listening,
    oci_dns_resolver_endpoint.forwarding,
  ]
}
