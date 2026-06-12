# ===========================================================================
# Example: COMPOSITION — GCP core-network + private DNS.
# The DNS module consumes the core-network module's network_self_link
# output; composition lives HERE, not inside either module.
# ===========================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "core_network" {
  source = "../../../modules/gcp/core-network"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  project_id = var.project_id

  subnets = {
    app = {
      ip_cidr_range = "10.61.10.0/24"
      region        = var.region
    }
  }
}

module "private_dns" {
  source = "../../../modules/gcp/dns/private-zones"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  project_id = var.project_id

  private_zones = {
    internal = {
      domain_name = var.domain_name
      # Composition point: consumer wires output -> input.
      network_self_links = [module.core_network.network_self_link]
      records = {
        api = { name = "api", type = "A", rrdatas = ["10.61.10.15"] }
      }
    }
  }
}
