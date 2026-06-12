# ===========================================================================
# Example: GCP core network ONLY — custom VPC, subnets, Cloud NAT.
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
      ip_cidr_range = "10.60.10.0/24"
      region        = var.region
      flow_logs     = { enabled = true }
    }
    data = {
      ip_cidr_range = "10.60.20.0/24"
      region        = var.region
    }
  }

  cloud_nat = {
    enabled = true
    region  = var.region
  }
}
