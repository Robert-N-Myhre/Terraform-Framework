# ===========================================================================
# Example: COMPOSITION — OCI core-network + NSGs.
# The NSG module consumes the core-network module's network_id output;
# composition lives HERE, not inside either module.
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

  create_nat_gateway = true

  subnets = {
    app = {
      cidr_block = cidrsubnet(var.vcn_cidr, 8, 10)
      route_rules = {
        default = { destination = "0.0.0.0/0", network_entity_key = "natgw" }
      }
    }
  }
}

module "nsgs" {
  source = "../../../modules/oci/firewall/nsgs"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  compartment_id = var.compartment_id
  # Composition point: consumer wires output -> input.
  vcn_id = module.core_network.network_id

  network_security_groups = {
    web = {
      rules = {
        https-in = { direction = "INGRESS", protocol = "6", cidr = "0.0.0.0/0", tcp_min = 443 }
        to-app   = { direction = "EGRESS", protocol = "6", nsg_key = "app", tcp_min = 8080 }
      }
    }
    app = {
      rules = {
        from-web  = { direction = "INGRESS", protocol = "6", nsg_key = "web", tcp_min = 8080 }
        https-out = { direction = "EGRESS", protocol = "6", cidr = "0.0.0.0/0", tcp_min = 443 }
      }
    }
  }
}
