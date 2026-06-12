# ===========================================================================
# OCI Load Balancer — Network Load Balancer (L4 passthrough)
#
# Independently invocable: this module sources no other module in this
# framework. Subnet and NSG OCIDs are plain inputs.
#
# Provider API divergence note (see README): the OCI NLB is a separate
# service/API from the OCI LB (oci_network_load_balancer_* vs
# oci_load_balancer_*). It is non-proxying — client IP preserved, no TLS
# termination (AWS NLB uniquely terminates TLS at L4). Transparent
# source/destination preservation supports firewall-appliance insertion.
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
    module_source = "modules/oci/load-balancer/network-load-balancer"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  static_backends = merge([
    for bs_key, bs in var.backend_sets : {
      for b_key, b in bs.backends :
      "${bs_key}/${b_key}" => merge(b, { backend_set_key = bs_key })
    }
  ]...)
}

resource "oci_network_load_balancer_network_load_balancer" "this" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-nlb-${var.name_suffix}"
  subnet_id      = var.subnet_id

  is_private                     = var.is_private
  is_preserve_source_destination = var.is_preserve_source_destination

  network_security_group_ids = length(var.nsg_ids) > 0 ? var.nsg_ids : null

  freeform_tags = local.all_tags
}

resource "oci_network_load_balancer_backend_set" "this" {
  for_each = var.backend_sets

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this.id
  name                     = each.key
  policy                   = each.value.policy
  is_preserve_source       = each.value.is_preserve_source

  health_checker {
    protocol           = each.value.health_checker.protocol
    port               = each.value.health_checker.port
    url_path           = contains(["HTTP", "HTTPS"], each.value.health_checker.protocol) ? each.value.health_checker.url_path : null
    return_code        = contains(["HTTP", "HTTPS"], each.value.health_checker.protocol) ? each.value.health_checker.return_code : null
    interval_in_millis = each.value.health_checker.interval_ms
    timeout_in_millis  = each.value.health_checker.timeout_ms
    retries            = each.value.health_checker.retries
  }
}

resource "oci_network_load_balancer_backend" "this" {
  for_each = local.static_backends

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this.id
  backend_set_name         = oci_network_load_balancer_backend_set.this[each.value.backend_set_key].name

  name       = each.key
  ip_address = each.value.ip_address
  target_id  = each.value.target_id
  port       = each.value.port
  weight     = each.value.weight
}

resource "oci_network_load_balancer_listener" "this" {
  for_each = var.listeners

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this.id
  name                     = each.key
  port                     = each.value.port
  protocol                 = each.value.protocol
  default_backend_set_name = oci_network_load_balancer_backend_set.this[each.value.default_backend_set_key].name
}
