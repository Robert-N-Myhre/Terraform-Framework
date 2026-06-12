# ===========================================================================
# GCP Core Network Fabric — VPC, subnets, routes, Cloud NAT, flow logs
#
# Independently invocable: this module sources no other module in this
# framework.
#
# Provider API divergence note (see README): GCP VPCs are GLOBAL with
# REGIONAL subnets — there is no per-VPC region, no IGW resource (the
# default-internet-gateway is implicit), and flow logs configure per
# subnet rather than per network. Labels (GCP's tags) must be lowercase;
# "network tags" on instances are a separate firewall-targeting concept,
# not metadata.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  name_base = "${var.prefix}-gcp-${var.environment}"

  # Tagging convention (self-contained copy — see governance/tagging/README.md)
  # GCP: applied as labels; keys/values lowercased to satisfy the API.
  mandatory_tags = {
    environment   = lower(var.environment)
    owner         = lower(var.owner)
    cost_center   = lower(var.cost_center)
    managed_by    = "terraform"
    module_source = "modules-gcp-core-network" # label values disallow "/"
  }
  all_tags = merge({ for k, v in var.additional_tags : lower(k) => lower(v) }, local.mandatory_tags)
}

# ---------------------------------------------------------------------------
# VPC (global; custom subnet mode always — auto mode is an anti-pattern)
# ---------------------------------------------------------------------------
resource "google_compute_network" "this" {
  project = var.project_id
  name    = "${local.name_base}-vpc-${var.name_suffix}"

  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes_on_create
}

# ---------------------------------------------------------------------------
# Subnets (regional; flow logs per subnet)
# ---------------------------------------------------------------------------
resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  project = var.project_id
  name    = "${local.name_base}-subnet-${each.key}"
  network = google_compute_network.this.id

  ip_cidr_range            = each.value.ip_cidr_range
  region                   = each.value.region
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }

  dynamic "log_config" {
    for_each = each.value.flow_logs.enabled ? [each.value.flow_logs] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
    }
  }
}

# ---------------------------------------------------------------------------
# Static routes
# ---------------------------------------------------------------------------
resource "google_compute_route" "this" {
  for_each = var.static_routes

  project = var.project_id
  name    = "${local.name_base}-route-${each.key}-${var.name_suffix}"
  network = google_compute_network.this.name

  dest_range = each.value.dest_range
  priority   = each.value.priority
  tags       = length(each.value.tags) > 0 ? each.value.tags : null

  next_hop_gateway = each.value.next_hop_gateway
  next_hop_ip      = each.value.next_hop_ip
  next_hop_ilb     = each.value.next_hop_ilb
}

# ---------------------------------------------------------------------------
# Cloud NAT (router + NAT, regional)
# ---------------------------------------------------------------------------
resource "google_compute_router" "nat" {
  count = var.cloud_nat.enabled ? 1 : 0

  project = var.project_id
  name    = "${local.name_base}-router-nat-${var.name_suffix}"
  region  = var.cloud_nat.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  count = var.cloud_nat.enabled ? 1 : 0

  project = var.project_id
  name    = "${local.name_base}-nat-${var.name_suffix}"
  router  = google_compute_router.nat[0].name
  region  = var.cloud_nat.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = var.cloud_nat.source_subnetwork_ip_ranges_to_nat
  min_ports_per_vm                   = var.cloud_nat.min_ports_per_vm

  log_config {
    enable = true
    filter = var.cloud_nat.log_errors_only ? "ERRORS_ONLY" : "ALL"
  }
}
