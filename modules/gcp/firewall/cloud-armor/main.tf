# ===========================================================================
# GCP Firewall — Cloud Armor (edge WAF / DDoS)
#
# Independently invocable: this module sources no other module in this
# framework. Attaching the policy to backend services happens where the
# load balancer is managed (gcp/load-balancer/external accepts
# security_policy_id) — by ID, never by module reference.
#
# Provider API divergence note (see README): Cloud Armor is an EDGE
# security policy attached to global LB backend services — the analogue
# of AWS WAF (ALB/CloudFront) and Azure WAF (App Gateway/Front Door); OCI
# has a WAF service with a different policy document. CEL expressions and
# preconfigured WAF rule names are GCP-specific and do not port.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-gcp-${var.environment}"

  # Tagging convention note: security policies are not labelable; the
  # governance contract is honored through naming only here.
}

resource "google_compute_security_policy" "this" {
  project = var.project_id
  name    = "${local.name_base}-armor-${var.name_suffix}"

  # Default rule: required catch-all at the lowest priority.
  rule {
    action      = var.default_action
    priority    = 2147483647
    description = "Default rule"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      preview     = rule.value.preview

      match {
        # IP-range match
        versioned_expr = length(rule.value.src_ip_ranges) > 0 ? "SRC_IPS_V1" : null

        dynamic "config" {
          for_each = length(rule.value.src_ip_ranges) > 0 ? [1] : []
          content {
            src_ip_ranges = rule.value.src_ip_ranges
          }
        }

        # CEL / preconfigured WAF match
        dynamic "expr" {
          for_each = rule.value.expression != null ? [1] : []
          content {
            expression = rule.value.expression
          }
        }
      }

      dynamic "rate_limit_options" {
        for_each = rule.value.rate_limit != null ? [rule.value.rate_limit] : []
        content {
          conform_action = rate_limit_options.value.conform_action
          exceed_action  = rate_limit_options.value.exceed_action
          enforce_on_key = rate_limit_options.value.enforce_on_key

          rate_limit_threshold {
            count        = rate_limit_options.value.count_per_interval
            interval_sec = rate_limit_options.value.interval_sec
          }

          ban_duration_sec = rate_limit_options.value.ban_duration_sec
        }
      }
    }
  }

  dynamic "adaptive_protection_config" {
    for_each = var.adaptive_protection_enabled ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable = true
      }
    }
  }

  advanced_options_config {
    json_parsing = var.json_parsing
    log_level    = var.log_level
  }
}
