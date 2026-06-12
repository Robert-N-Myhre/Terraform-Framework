# ===========================================================================
# OCI Load Balancer — Load Balancer (L7-capable, flexible shape)
#
# Independently invocable: this module sources no other module in this
# framework. Subnet and NSG OCIDs are plain inputs.
#
# Provider API divergence note (see README): the OCI LB is one resource
# with child resources for backend sets, backends, listeners, and
# certificates — closest to Azure's model; AWS ALB and GCP HTTP(S) LB
# decompose further. Backends register INTO the backend set by IP:port
# (this module supports static backends inline; dynamic registration is
# the consumer's job).
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
    module_source = "modules/oci/load-balancer/load-balancer"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  static_backends = merge([
    for bs_key, bs in var.backend_sets : {
      for b_key, b in bs.backends :
      "${bs_key}/${b_key}" => merge(b, { backend_set_key = bs_key })
    }
  ]...)
}

resource "oci_load_balancer_load_balancer" "this" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-lb-${var.name_suffix}"
  shape          = "flexible"
  subnet_ids     = var.subnet_ids
  is_private     = var.is_private

  network_security_group_ids = length(var.nsg_ids) > 0 ? var.nsg_ids : null

  shape_details {
    minimum_bandwidth_in_mbps = var.shape_min_mbps
    maximum_bandwidth_in_mbps = var.shape_max_mbps
  }

  freeform_tags = local.all_tags
}

resource "oci_load_balancer_backend_set" "this" {
  for_each = var.backend_sets

  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = each.key
  policy           = each.value.policy

  health_checker {
    protocol          = each.value.health_checker.protocol
    port              = each.value.health_checker.port
    url_path          = each.value.health_checker.protocol == "HTTP" ? each.value.health_checker.url_path : null
    return_code       = each.value.health_checker.protocol == "HTTP" ? each.value.health_checker.return_code : null
    interval_ms       = each.value.health_checker.interval_ms
    timeout_in_millis = each.value.health_checker.timeout_ms
    retries           = each.value.health_checker.retries
  }

  dynamic "session_persistence_configuration" {
    for_each = each.value.session_persistence_cookie != null ? [1] : []
    content {
      cookie_name = each.value.session_persistence_cookie
    }
  }
}

resource "oci_load_balancer_backend" "this" {
  for_each = local.static_backends

  load_balancer_id = oci_load_balancer_load_balancer.this.id
  backendset_name  = oci_load_balancer_backend_set.this[each.value.backend_set_key].name

  ip_address = each.value.ip_address
  port       = each.value.port
  weight     = each.value.weight
  backup     = each.value.backup
}

resource "oci_load_balancer_certificate" "this" {
  for_each = var.certificates

  load_balancer_id   = oci_load_balancer_load_balancer.this.id
  certificate_name   = each.key
  public_certificate = each.value.certificate_pem
  private_key        = each.value.private_key_pem
  ca_certificate     = each.value.ca_certificate_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_listener" "this" {
  for_each = var.listeners

  load_balancer_id         = oci_load_balancer_load_balancer.this.id
  name                     = each.key
  port                     = each.value.port
  protocol                 = each.value.protocol == "HTTP2" ? "HTTP" : each.value.protocol
  default_backend_set_name = oci_load_balancer_backend_set.this[each.value.default_backend_set_key].name

  dynamic "ssl_configuration" {
    for_each = each.value.certificate_name != null ? [1] : []
    content {
      certificate_name        = oci_load_balancer_certificate.this[each.value.certificate_name].certificate_name
      verify_peer_certificate = each.value.ssl_verify_peer
    }
  }
}
