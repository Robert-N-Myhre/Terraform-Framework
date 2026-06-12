# ===========================================================================
# AWS Load Balancer — Application Load Balancer (L7)
#
# Independently invocable: this module sources no other module in this
# framework. VPC, subnet, and security group IDs are plain inputs.
# Target registration is deliberately left to the consumer.
#
# Provider API divergence note (see README): ALB couples listeners, rules,
# and target groups as separate resources. Azure Application Gateway packs
# the equivalent concepts into one resource with inner blocks; GCP external
# HTTP(S) LB decomposes further (forwarding rule -> target proxy -> URL map
# -> backend service); OCI LB uses listener + backend set inside one LB
# resource. Health-check semantics and defaults differ per cloud.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-aws-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/aws/load-balancer/alb"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  listener_rules = merge([
    for l_key, l in var.listeners : {
      for r_key, r in l.rules :
      "${l_key}/${r_key}" => merge(r, { listener_key = l_key })
    }
  ]...)
}

resource "aws_lb" "this" {
  name               = "${local.name_base}-alb-${var.name_suffix}"
  load_balancer_type = "application"
  internal           = var.internal
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.drop_invalid_header_fields
  idle_timeout               = var.idle_timeout

  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [1] : []
    content {
      enabled = true
      bucket  = var.access_logs.bucket
      prefix  = var.access_logs.prefix
    }
  }

  tags = local.all_tags
}

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = "${local.name_base}-tg-${each.key}-${var.name_suffix}"
  vpc_id               = var.vpc_id
  port                 = each.value.port
  protocol             = each.value.protocol
  target_type          = each.value.target_type
  deregistration_delay = each.value.deregistration_delay

  health_check {
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    timeout             = each.value.health_check.timeout
    interval            = each.value.health_check.interval
    matcher             = each.value.health_check.matcher
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
    }
  }

  tags = local.all_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = each.value.protocol == "HTTPS" ? each.value.certificate_arn : null
  ssl_policy        = each.value.protocol == "HTTPS" ? each.value.ssl_policy : null

  default_action {
    type = each.value.default_action.type

    target_group_arn = (
      each.value.default_action.type == "forward"
      ? aws_lb_target_group.this[each.value.default_action.target_group_key].arn
      : null
    )

    dynamic "redirect" {
      for_each = each.value.default_action.type == "redirect" ? [each.value.default_action.redirect] : []
      content {
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        status_code = redirect.value.status_code
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.default_action.type == "fixed-response" ? [each.value.default_action.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }
  }

  tags = local.all_tags
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.listener_rules

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  }

  dynamic "condition" {
    for_each = length(each.value.path_patterns) > 0 ? [1] : []
    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  dynamic "condition" {
    for_each = length(each.value.host_headers) > 0 ? [1] : []
    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  tags = local.all_tags
}
