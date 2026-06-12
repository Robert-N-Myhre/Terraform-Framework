# ===========================================================================
# GCP Transit — VPC Network Peering
#
# Independently invocable: this module sources no other module in this
# framework. Network self-links are plain inputs.
#
# Provider API divergence note (see README): GCP peering is configured
# symmetrically on each network and activates when both sides exist —
# vs AWS's requester/accepter handshake, Azure's two one-way resources,
# and OCI's LPG pairs. Subnet routes exchange automatically; only custom
# (static/dynamic) routes need the export/import flags. Non-transitive,
# like every cloud's basic peering.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-gcp-${var.environment}"

  # Tagging convention note: network peerings are not labelable; the
  # governance contract is honored through naming only here.
}

resource "google_compute_network_peering" "a_to_b" {
  for_each = var.peerings

  name         = "${local.name_base}-peer-${each.key}-ab-${var.name_suffix}"
  network      = each.value.network_a_self_link
  peer_network = each.value.network_b_self_link

  export_custom_routes                = each.value.a_to_b.export_custom_routes
  import_custom_routes                = each.value.a_to_b.import_custom_routes
  export_subnet_routes_with_public_ip = each.value.a_to_b.export_subnet_routes_with_public_ip
  import_subnet_routes_with_public_ip = each.value.a_to_b.import_subnet_routes_with_public_ip
}

resource "google_compute_network_peering" "b_to_a" {
  for_each = var.peerings

  name         = "${local.name_base}-peer-${each.key}-ba-${var.name_suffix}"
  network      = each.value.network_b_self_link
  peer_network = each.value.network_a_self_link

  export_custom_routes                = each.value.b_to_a.export_custom_routes
  import_custom_routes                = each.value.b_to_a.import_custom_routes
  export_subnet_routes_with_public_ip = each.value.b_to_a.export_subnet_routes_with_public_ip
  import_subnet_routes_with_public_ip = each.value.b_to_a.import_subnet_routes_with_public_ip

  # GCP serializes peering operations per network; avoid concurrent-op errors.
  depends_on = [google_compute_network_peering.a_to_b]
}
