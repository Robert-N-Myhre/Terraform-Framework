# ===========================================================================
# GCP Load Balancer — Internal Passthrough Network LB (L4)
#
# Independently invocable: this module sources no other module in this
# framework. Network/subnet self-links and backend groups are plain inputs.
#
# Provider API divergence note (see README): the GCP internal passthrough
# LB decomposes into health check -> region backend service -> forwarding
# rule; there is no LB "appliance" resource. Traffic is NOT proxied —
# backends see the original client IP (like AWS NLB with client IP
# preservation; unlike Azure LB which DNATs). No TLS termination at L4.
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
    module_source = "modules-gcp-load-balancer-internal" # label values disallow "/"
  }
  all_tags = merge({ for k, v in var.additional_tags : lower(k) => lower(v) }, local.mandatory_tags)
}

# ---------------------------------------------------------------------------
# Health check (regional)
# ---------------------------------------------------------------------------
resource "google_compute_region_health_check" "this" {
  project = var.project_id
  name    = "${local.name_base}-hc-ilb-${var.name_suffix}"
  region  = var.region

  check_interval_sec  = var.health_check.check_interval_sec
  timeout_sec         = var.health_check.timeout_sec
  healthy_threshold   = var.health_check.healthy_threshold
  unhealthy_threshold = var.health_check.unhealthy_threshold

  dynamic "tcp_health_check" {
    for_each = var.health_check.protocol == "TCP" ? [1] : []
    content {
      port = var.health_check.port
    }
  }

  dynamic "http_health_check" {
    for_each = var.health_check.protocol == "HTTP" ? [1] : []
    content {
      port         = var.health_check.port
      request_path = var.health_check.request_path
    }
  }

  dynamic "https_health_check" {
    for_each = var.health_check.protocol == "HTTPS" ? [1] : []
    content {
      port         = var.health_check.port
      request_path = var.health_check.request_path
    }
  }
}

# ---------------------------------------------------------------------------
# Backend service (regional, INTERNAL scheme)
# ---------------------------------------------------------------------------
resource "google_compute_region_backend_service" "this" {
  project = var.project_id
  name    = "${local.name_base}-bes-ilb-${var.name_suffix}"
  region  = var.region

  load_balancing_scheme = "INTERNAL"
  protocol              = var.protocol
  network               = var.network_self_link
  session_affinity      = var.session_affinity
  health_checks         = [google_compute_region_health_check.this.id]

  dynamic "backend" {
    for_each = var.backend_groups
    content {
      group          = backend.value.group
      balancing_mode = backend.value.balancing_mode
      failover       = backend.value.failover
    }
  }
}

# ---------------------------------------------------------------------------
# Forwarding rule (the "frontend")
# ---------------------------------------------------------------------------
resource "google_compute_forwarding_rule" "this" {
  project = var.project_id
  name    = "${local.name_base}-fr-ilb-${var.name_suffix}"
  region  = var.region

  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.this.id
  network               = var.network_self_link
  subnetwork            = var.subnet_self_link
  ip_address            = var.ip_address
  ip_protocol           = var.protocol
  ports                 = var.all_ports ? null : var.ports
  all_ports             = var.all_ports
  allow_global_access   = var.allow_global_access

  labels = local.all_tags
}
