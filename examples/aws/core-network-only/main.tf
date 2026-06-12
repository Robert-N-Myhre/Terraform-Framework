# ===========================================================================
# Example: AWS core network ONLY — VPC, subnets, NAT, flow logs.
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
    public-a  = { cidr_block = cidrsubnet(var.vpc_cidr_block, 8, 0), availability_zone = "${var.region}a", tier = "public" }
    public-b  = { cidr_block = cidrsubnet(var.vpc_cidr_block, 8, 1), availability_zone = "${var.region}b", tier = "public" }
    private-a = { cidr_block = cidrsubnet(var.vpc_cidr_block, 8, 10), availability_zone = "${var.region}a", tier = "private" }
    private-b = { cidr_block = cidrsubnet(var.vpc_cidr_block, 8, 11), availability_zone = "${var.region}b", tier = "private" }
  }

  enable_nat_gateway   = true
  nat_gateway_strategy = "single"
  enable_flow_logs     = true
}
