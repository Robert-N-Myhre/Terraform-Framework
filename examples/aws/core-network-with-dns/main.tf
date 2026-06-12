# ===========================================================================
# Example: COMPOSITION — core-network + private DNS.
# Both modules are independently invocable; composition happens HERE in the
# example root by wiring one module's outputs into the other's inputs.
# Neither module references the other internally.
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

module "core_network" {
  source = "../../../modules/aws/core-network"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  region         = var.region
  vpc_cidr_block = var.vpc_cidr_block

  subnets = {
    private-a = { cidr_block = cidrsubnet(var.vpc_cidr_block, 8, 10), availability_zone = "${var.region}a", tier = "private" }
    private-b = { cidr_block = cidrsubnet(var.vpc_cidr_block, 8, 11), availability_zone = "${var.region}b", tier = "private" }
  }

  enable_internet_gateway = false
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
      # Composition point: consumer wires output -> input. The DNS module
      # neither knows nor cares that the VPC came from this framework.
      vpc_associations = [
        { vpc_id = module.core_network.network_id }
      ]
      records = {
        api = { name = "api", type = "A", ttl = 300, values = [cidrhost(cidrsubnet(var.vpc_cidr_block, 8, 10), 15)] }
      }
    }
  }
}
