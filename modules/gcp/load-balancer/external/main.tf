# ===========================================================================
# GCP Load Balancer — Global External HTTP(S) LB (L7)
#
# Independently invocable: this module sources no other module in this
# framework. Backend groups (MIGs/NEGs) and Cloud Armor policy IDs are
# plain inputs.
#
# Provider API divergence note (see README): the GCP global L7 LB is a
# CHAIN of resources: global IP -> forwarding rule -> target proxy ->
# URL map -> backend service -> health check. AWS ALB and Azure App
# Gateway pack these into 1-2 resources. The LB is global anycast —
# one IP serves all regions; no other cloud's standard L7 LB does this.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-gcp-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = lower(var.environment)
    owner         = lower(var.owner)
    cost_center   = lower(var.cost_center)
    managed_by    = "terraform"
    module_source = "modules-gcp-load-balancer-external" # label values disallow "/"
  }
  all_tags = merge({ for k, v in var.additional_tags : lower(k) => lower(v) }, local.mandatory_tags)

  backend_groups = merge([
    for bs_key, bs in var.backend_services : {
      for g_key, g in bs.groups :
      "${bs_key}/${g_key}" => merge(g, { bs_key = bs_key })
    }
  ]...)

  use_managed_cert = length(var.managed_certificate_domains) > 0
}

# ---------------------------------------------------------------------------
# Global static IP
# ---------------------------------------------------------------------------
resource "google_compute_global_address" "this" {
  project = var.project_id
  name    = coalesce(var.static_ip_name, "${local.name_base}-ip-xlb-${var.name_suffix}")

  labels = local.all_tags
}

# ---------------------------------------------------------------------------
# Health checks (global)
# ---------------------------------------------------------------------------
resource "google_compute_health_check" "this" {
  for_each = var.backend_services

  project = var.project_id
  name    = "${local.name_base}-hc-${each.key}-${var.name_suffix}"

  check_interval_sec  = each.value.health_check.check_interval_sec
  timeout_sec         = each.value.health_check.timeout_sec
  healthy_threshold   = each.value.health_check.healthy_threshold
  unhealthy_threshold = each.value.health_check.unhealthy_threshold

  dynamic "http_health_check" {
    for_each = each.value.health_check.protocol == "HTTP" ? [1] : []
    content {
      port         = each.value.health_check.port
      request_path = each.value.health_check.request_path
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.health_check.protocol == "HTTPS" ? [1] : []
    content {
      port         = each.value.health_check.port
      request_path = each.value.health_check.request_path
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.health_check.protocol == "TCP" ? [1] : []
    content {
      port = each.value.health_check.port
    }
  }
}

# ---------------------------------------------------------------------------
# Backend services (global, EXTERNAL_MANAGED)
# ---------------------------------------------------------------------------
resource "google_compute_backend_service" "this" {
  for_each = var.backend_services

  project = var.project_id
  name    = "${local.name_base}-bes-${each.key}-${var.name_suffix}"

  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = each.value.protocol
  port_name             = each.value.port_name
  timeout_sec           = each.value.timeout_sec
  enable_cdn            = each.value.enable_cdn
  security_policy       = each.value.security_policy_id
  health_checks         = [google_compute_health_check.this[each.key].id]

  dynamic "backend" {
    for_each = each.value.groups
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      max_utilization = backend.value.balancing_mode == "UTILIZATION" ? backend.value.max_utilization : null
    }
  }
}

# ---------------------------------------------------------------------------
# URL map (host/path routing)
# ---------------------------------------------------------------------------
resource "google_compute_url_map" "this" {
  project = var.project_id
  name    = "${local.name_base}-urlmap-${var.name_suffix}"

  default_service = google_compute_backend_service.this[var.default_backend_service_key].id

  dynamic "host_rule" {
    for_each = var.host_rules
    content {
      hosts        = host_rule.value.hosts
      path_matcher = "pm-${host_rule.key}"
    }
  }

  dynamic "path_matcher" {
    for_each = var.host_rules
    content {
      name            = "pm-${path_matcher.key}"
      default_service = google_compute_backend_service.this[path_matcher.value.backend_service_key].id

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules
        content {
          paths   = path_rule.value.paths
          service = google_compute_backend_service.this[path_rule.value.backend_service_key].id
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Certificates + proxies + forwarding rules
# ---------------------------------------------------------------------------
resource "google_compute_managed_ssl_certificate" "this" {
  count = var.enable_https && local.use_managed_cert ? 1 : 0

  project = var.project_id
  name    = "${local.name_base}-cert-${var.name_suffix}"

  managed {
    domains = var.managed_certificate_domains
  }
}

resource "google_compute_target_https_proxy" "this" {
  count = var.enable_https ? 1 : 0

  project = var.project_id
  name    = "${local.name_base}-proxy-https-${var.name_suffix}"
  url_map = google_compute_url_map.this.id

  ssl_certificates = concat(
    local.use_managed_cert ? [google_compute_managed_ssl_certificate.this[0].id] : [],
    var.ssl_certificate_ids
  )
}

resource "google_compute_target_http_proxy" "this" {
  count = var.enable_http ? 1 : 0

  project = var.project_id
  name    = "${local.name_base}-proxy-http-${var.name_suffix}"
  url_map = google_compute_url_map.this.id
}

resource "google_compute_global_forwarding_rule" "https" {
  count = var.enable_https ? 1 : 0

  project = var.project_id
  name    = "${local.name_base}-fr-https-${var.name_suffix}"

  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.this.id
  port_range            = "443"
  target                = google_compute_target_https_proxy.this[0].id

  labels = local.all_tags
}

resource "google_compute_global_forwarding_rule" "http" {
  count = var.enable_http ? 1 : 0

  project = var.project_id
  name    = "${local.name_base}-fr-http-${var.name_suffix}"

  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.this.id
  port_range            = "80"
  target                = google_compute_target_http_proxy.this[0].id

  labels = local.all_tags
}
