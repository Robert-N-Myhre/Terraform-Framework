# ===========================================================================
# AWS Load Balancer — Network Load Balancer (L4)
#
# Independently invocable: this module sources no other module in this
# framework. VPC, subnet, and security group IDs are plain inputs.
#
# Provider API divergence note (see README): NLB is the L4 analogue of the
# Azure Standard Load Balancer, the GCP internal/external passthrough
# network LB, and the OCI Network Load Balancer. AWS uniquely supports
# listener-level TLS termination at L4 (TLS listeners); GCP passthrough
# and OCI NLB do not terminate TLS.
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
    module_source = "modules/aws/load-balancer/nlb"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

resource "aws_lb" "this" {
  name               = "${local.name_base}-nlb-${var.name_suffix}"
  load_balancer_type = "network"
  internal           = var.internal
  subnets            = var.subnet_ids

  # SGs attach at creation only — see versions.tf comment.
  security_groups = length(var.security_group_ids) > 0 ? var.security_group_ids : null

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

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
  preserve_client_ip   = each.value.preserve_client_ip
  proxy_protocol_v2    = each.value.proxy_protocol_v2

  health_check {
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
    path                = contains(["HTTP", "HTTPS"], each.value.health_check.protocol) ? each.value.health_check.path : null
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    interval            = each.value.health_check.interval
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
  certificate_arn   = each.value.protocol == "TLS" ? each.value.certificate_arn : null
  ssl_policy        = each.value.protocol == "TLS" ? each.value.ssl_policy : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  }

  tags = local.all_tags
}
