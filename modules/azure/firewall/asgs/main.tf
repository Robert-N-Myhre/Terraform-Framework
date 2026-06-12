# ===========================================================================
# Azure Firewall Domain — Application Security Groups
#
# Independently invocable: this module sources no other module in this
# framework. ASGs are pure grouping objects; NIC membership is declared on
# the NIC (azurerm_network_interface_application_security_group_association)
# where the workload is managed, and NSG rules reference the ASG IDs output
# here — both happen outside this module by design.
#
# Provider API divergence note (see README): ASGs are Azure's analogue of
# AWS SG-to-SG references and GCP network tags: a workload-identity handle
# for firewall rules. AWS/GCP/OCI have no standalone resource for this.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-azure-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/azure/firewall/asgs"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}

resource "azurerm_application_security_group" "this" {
  for_each = var.application_security_groups

  name                = "${local.name_base}-asg-${each.value}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.all_tags
}
