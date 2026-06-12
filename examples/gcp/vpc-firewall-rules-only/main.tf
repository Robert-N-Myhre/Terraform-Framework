# ===========================================================================
# Example: GCP VPC firewall rules ONLY — demonstrates independent
# invocability against an EXISTING network supplied by name.
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

module "firewall_rules" {
  source = "../../../modules/gcp/firewall/vpc-firewall-rules"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  project_id   = var.project_id
  network_name = var.network_name

  rules = {
    allow-https-in = {
      direction     = "INGRESS"
      action        = "allow"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["web"]
      allow_deny    = [{ protocol = "tcp", ports = ["443"] }]
      log_enabled   = true
    }
    allow-health-checks = {
      direction     = "INGRESS"
      action        = "allow"
      priority      = 900
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      allow_deny    = [{ protocol = "tcp" }]
    }
    web-to-app = {
      direction   = "INGRESS"
      action      = "allow"
      source_tags = ["web"]
      target_tags = ["app"]
      allow_deny  = [{ protocol = "tcp", ports = ["8080"] }]
    }
  }
}
