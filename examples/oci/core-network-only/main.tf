# ===========================================================================
# Example: OCI core network ONLY — VCN, subnets, gateways.
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

module "core_network" {
  source = "../../../modules/oci/core-network"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  compartment_id  = var.compartment_id
  vcn_cidr_blocks = [var.vcn_cidr]
  dns_label       = "acmedev"

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true

  subnets = {
    public = {
      cidr_block                 = cidrsubnet(var.vcn_cidr, 8, 0)
      prohibit_public_ip_on_vnic = false
      dns_label                  = "public"
      route_rules = {
        default = { destination = "0.0.0.0/0", network_entity_key = "igw" }
      }
    }
    app = {
      cidr_block = cidrsubnet(var.vcn_cidr, 8, 10)
      dns_label  = "app"
      route_rules = {
        default = { destination = "0.0.0.0/0", network_entity_key = "natgw" }
      }
    }
  }
}
