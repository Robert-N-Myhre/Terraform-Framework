# ===========================================================================
# OCI Core Network Fabric — VCN, subnets, route tables, gateways, flow logs
#
# Independently invocable: this module sources no other module in this
# framework. Only a compartment OCID is required.
#
# Provider API divergence note (see README): OCI route tables attach to
# subnets AT SUBNET CREATION (route_table_id argument) rather than via a
# separate association resource (AWS/Azure). OCI uniquely has a Service
# Gateway for private OCI-service access (analogue of AWS Gateway VPC
# endpoints). Subnets are regional by default; AD-scoped subnets are
# legacy.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-oci-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  # OCI: applied as freeform_tags.
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/oci/core-network"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  subnet_route_rules = {
    for s_key, s in var.subnets :
    s_key => s.route_rules
  }
}

# ---------------------------------------------------------------------------
# VCN
# ---------------------------------------------------------------------------
resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-vcn-${var.name_suffix}"
  cidr_blocks    = var.vcn_cidr_blocks
  dns_label      = var.dns_label

  freeform_tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Gateways
# ---------------------------------------------------------------------------
resource "oci_core_internet_gateway" "this" {
  count = var.create_internet_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_base}-igw-${var.name_suffix}"
  enabled        = true

  freeform_tags = local.all_tags
}

resource "oci_core_nat_gateway" "this" {
  count = var.create_nat_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_base}-natgw-${var.name_suffix}"

  freeform_tags = local.all_tags
}

data "oci_core_services" "all" {
  count = var.create_service_gateway ? 1 : 0

  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "this" {
  count = var.create_service_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_base}-sgw-${var.name_suffix}"

  services {
    service_id = data.oci_core_services.all[0].services[0].id
  }

  freeform_tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Route tables (one per subnet) + subnets
# Route rules resolve module-managed gateways by keyword or external OCIDs.
# ---------------------------------------------------------------------------
resource "oci_core_route_table" "this" {
  for_each = var.subnets

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_base}-rt-${each.key}-${var.name_suffix}"

  dynamic "route_rules" {
    for_each = each.value.route_rules
    content {
      destination      = route_rules.value.destination
      destination_type = route_rules.value.destination_type

      network_entity_id = (
        route_rules.value.network_entity_key == "igw" ? oci_core_internet_gateway.this[0].id :
        route_rules.value.network_entity_key == "natgw" ? oci_core_nat_gateway.this[0].id :
        route_rules.value.network_entity_key == "sgw" ? oci_core_service_gateway.this[0].id :
        route_rules.value.network_entity_id
      )
    }
  }

  freeform_tags = local.all_tags
}

resource "oci_core_subnet" "this" {
  for_each = var.subnets

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_base}-subnet-${each.key}"

  cidr_block                 = each.value.cidr_block
  prohibit_public_ip_on_vnic = each.value.prohibit_public_ip_on_vnic
  dns_label                  = each.value.dns_label
  availability_domain        = each.value.availability_domain
  route_table_id             = oci_core_route_table.this[each.key].id

  freeform_tags = local.all_tags
}

# ---------------------------------------------------------------------------
# Flow logs (VCN-wide via Logging service)
# ---------------------------------------------------------------------------
resource "oci_logging_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_base}-lg-flowlogs-${var.name_suffix}"

  freeform_tags = local.all_tags
}

resource "oci_logging_log" "flow_logs" {
  for_each = var.enable_flow_logs ? var.subnets : {}

  display_name = "${local.name_base}-flowlog-${each.key}-${var.name_suffix}"
  log_group_id = oci_logging_log_group.flow_logs[0].id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "all"
      resource    = oci_core_subnet.this[each.key].id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }

    compartment_id = var.compartment_id
  }

  is_enabled         = true
  retention_duration = var.flow_log_retention_days

  freeform_tags = local.all_tags
}
