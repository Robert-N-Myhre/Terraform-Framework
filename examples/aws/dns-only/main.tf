# ===========================================================================
# Example: AWS private DNS ONLY — Route 53 private zone against an EXISTING
# VPC supplied by ID. No other framework module involved.
# ===========================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "private_dns" {
  source = "../../../modules/aws/dns/private-zones"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  private_zones = {
    internal = {
      domain_name = var.domain_name
      vpc_associations = [
        { vpc_id = var.vpc_id }
      ]
      records = {
        api = { name = "api", type = "A", ttl = 300, values = ["10.20.10.15"] }
        db  = { name = "db", type = "CNAME", values = ["db-primary.${var.domain_name}"] }
      }
    }
  }
}
