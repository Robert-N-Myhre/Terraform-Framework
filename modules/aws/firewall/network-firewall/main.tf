# ===========================================================================
# AWS Firewall — AWS Network Firewall
#
# Independently invocable: this module sources no other module in this
# framework. VPC and subnet IDs are supplied as plain values.
#
# Provider API divergence note (see README): AWS Network Firewall is a
# managed, endpoint-based inline firewall (Suricata-compatible stateful
# engine). Azure Firewall is a routed hub appliance; GCP has no exact
# equivalent (Cloud NGFW / hierarchical policies differ structurally);
# OCI Network Firewall is Palo Alto-based with its own policy document
# model. Rule syntax is NOT portable across these — only intent is.
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
    module_source = "modules/aws/firewall/network-firewall"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

# ---------------------------------------------------------------------------
# Stateless rule groups
# ---------------------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "stateless" {
  for_each = var.stateless_rule_groups

  name     = "${local.name_base}-nfwrg-${each.key}-${var.name_suffix}"
  type     = "STATELESS"
  capacity = each.value.capacity

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        dynamic "stateless_rule" {
          for_each = each.value.rules

          content {
            priority = stateless_rule.value.priority

            rule_definition {
              actions = stateless_rule.value.actions

              match_attributes {
                dynamic "source" {
                  for_each = stateless_rule.value.source_cidrs
                  content {
                    address_definition = source.value
                  }
                }

                dynamic "destination" {
                  for_each = stateless_rule.value.destination_cidrs
                  content {
                    address_definition = destination.value
                  }
                }

                protocols = stateless_rule.value.protocols

                dynamic "source_port" {
                  for_each = stateless_rule.value.source_port_from != null ? [1] : []
                  content {
                    from_port = stateless_rule.value.source_port_from
                    to_port   = coalesce(stateless_rule.value.source_port_to, stateless_rule.value.source_port_from)
                  }
                }

                dynamic "destination_port" {
                  for_each = stateless_rule.value.destination_port_from != null ? [1] : []
                  content {
                    from_port = stateless_rule.value.destination_port_from
                    to_port   = coalesce(stateless_rule.value.destination_port_to, stateless_rule.value.destination_port_from)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Stateful rule groups (Suricata-compatible, STRICT_ORDER)
# ---------------------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "stateful" {
  for_each = var.stateful_rule_groups

  name     = "${local.name_base}-nfwrg-${each.key}-${var.name_suffix}"
  type     = "STATEFUL"
  capacity = each.value.capacity

  rule_group {
    rule_group_options {
      stateful_rule_options {
        rule_order = "STRICT_ORDER"
      }
    }

    rules_source {
      rules_string = each.value.rules_string
    }
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Firewall policy
# ---------------------------------------------------------------------------
resource "aws_networkfirewall_firewall_policy" "this" {
  name = "${local.name_base}-nfwpolicy-${var.name_suffix}"

  firewall_policy {
    stateless_default_actions          = var.stateless_default_actions
    stateless_fragment_default_actions = var.stateless_fragment_default_actions
    stateful_default_actions           = var.stateful_default_actions

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    dynamic "stateless_rule_group_reference" {
      for_each = var.stateless_rule_groups
      content {
        priority     = stateless_rule_group_reference.value.priority
        resource_arn = aws_networkfirewall_rule_group.stateless[stateless_rule_group_reference.key].arn
      }
    }

    dynamic "stateful_rule_group_reference" {
      for_each = var.stateful_rule_groups
      content {
        priority     = stateful_rule_group_reference.value.priority
        resource_arn = aws_networkfirewall_rule_group.stateful[stateful_rule_group_reference.key].arn
      }
    }
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Firewall
# Deletion protection enabled by default (governance/resource-locks).
# ---------------------------------------------------------------------------
resource "aws_networkfirewall_firewall" "this" {
  name                = "${local.name_base}-nfw-${var.name_suffix}"
  vpc_id              = var.vpc_id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn

  delete_protection                 = var.delete_protection
  subnet_change_protection          = var.subnet_change_protection
  firewall_policy_change_protection = var.policy_change_protection

  dynamic "subnet_mapping" {
    for_each = toset(var.firewall_subnet_ids)
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Logging (optional)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "alert" {
  count = var.enable_logging ? 1 : 0

  name              = "/network-firewall/${local.name_base}-nfw-${var.name_suffix}/alert"
  retention_in_days = var.log_retention_days

  tags = local.all_tags
}

resource "aws_cloudwatch_log_group" "flow" {
  count = var.enable_logging ? 1 : 0

  name              = "/network-firewall/${local.name_base}-nfw-${var.name_suffix}/flow"
  retention_in_days = var.log_retention_days

  tags = local.all_tags
}

resource "aws_networkfirewall_logging_configuration" "this" {
  count = var.enable_logging ? 1 : 0

  firewall_arn = aws_networkfirewall_firewall.this.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.alert[0].name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.flow[0].name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}
