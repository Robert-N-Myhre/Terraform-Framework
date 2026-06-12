# ===========================================================================
# Example: GCP private DNS ONLY — private managed zone against an EXISTING
# network supplied by self-link.
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

module "private_dns" {
  source = "../../../modules/gcp/dns/private-zones"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  project_id = var.project_id

  private_zones = {
    internal = {
      domain_name        = var.domain_name # must end with a dot
      network_self_links = [var.network_self_link]
      records = {
        api = { name = "api", type = "A", rrdatas = ["10.60.10.15"] }
      }
    }
  }
}
