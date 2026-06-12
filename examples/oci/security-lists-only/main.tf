# ===========================================================================
# Example: OCI security lists ONLY — demonstrates independent invocability
# against an EXISTING VCN supplied by OCID.
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

module "security_lists" {
  source = "../../../modules/oci/firewall/security-lists"

  prefix      = var.prefix
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id

  security_lists = {
    web = {
      ingress_rules = {
        https = { protocol = "6", source = "0.0.0.0/0", tcp_min = 443, description = "HTTPS from anywhere" }
        ssh   = { protocol = "6", source = var.admin_cidr, tcp_min = 22, description = "SSH from admin range" }
      }
      egress_rules = {
        all = { protocol = "all", destination = "0.0.0.0/0", description = "Allow all egress" }
      }
    }
  }
}
