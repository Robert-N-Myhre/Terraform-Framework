# ===========================================================================
# Example: OCI private DNS ONLY — private view + zone. Attaching the view to
# a VCN resolver is a separate, independent step (oci/dns/resolver).
# ===========================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  region = var.region
}

module "private_dns" {
  source = "../../../modules/oci/dns/private-views"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  compartment_id = var.compartment_id

  views = {
    internal = {
      zones = {
        prod = {
          domain_name = var.domain_name
          records = {
            api = { name = "api", type = "A", rdata = ["10.80.10.15"] }
          }
        }
      }
    }
  }
}
