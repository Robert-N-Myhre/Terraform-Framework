# ---------------------------------------------------------------------------
# Provider version pinning
#
# Tested against: oracle/oci v5.23.0
# Known breaking-change boundary: v5.0.0. The VCN resolver
#   (oci_dns_resolver) is created implicitly by OCI with the VCN; Terraform
#   MANAGES (adopts) it rather than creating it — the resolver OCID is
#   discovered via the VCN's dns attributes. Endpoint and rule schemas are
#   stable across 5.x.
# Rationale: "~> 5.0" accepts all 5.x releases while excluding the next major.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}
