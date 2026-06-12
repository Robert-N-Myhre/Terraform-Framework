# ===========================================================================
# Example: AWS security groups ONLY — demonstrates independent invocability.
# The target VPC is an EXISTING VPC supplied by ID; nothing else from this
# framework is required.
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

module "security_groups" {
  source = "../../../modules/aws/firewall/security-groups"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  vpc_id = var.vpc_id

  security_groups = {
    web = {
      description = "Public web tier"
      ingress_rules = {
        https = { ip_protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = "0.0.0.0/0" }
        http  = { ip_protocol = "tcp", from_port = 80, to_port = 80, cidr_ipv4 = "0.0.0.0/0" }
      }
      egress_rules = {
        to-app = { ip_protocol = "tcp", from_port = 8080, to_port = 8080, referenced_security_group_key = "app" }
      }
    }
    app = {
      description = "Application tier"
      ingress_rules = {
        from-web = { ip_protocol = "tcp", from_port = 8080, to_port = 8080, referenced_security_group_key = "web" }
      }
      egress_rules = {
        https-out = { ip_protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = "0.0.0.0/0" }
      }
    }
  }
}
