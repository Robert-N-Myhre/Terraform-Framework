# ---------------------------------------------------------------------------
# Remote state backend — RECOMMENDED for any shared environment.
# OCI Object Storage exposes an S3-compatible API; use the s3 backend with
# the OCI compatibility endpoint. See docs/state-management.md.
# ---------------------------------------------------------------------------
# terraform {
#   backend "s3" {
#     bucket   = "acme-terraform-state"
#     key      = "examples/oci/dns-only/terraform.tfstate"
#     region   = "us-ashburn-1"
#     endpoints = {
#       s3 = "https://<namespace>.compat.objectstorage.us-ashburn-1.oraclecloud.com"
#     }
#     skip_region_validation      = true
#     skip_credentials_validation = true
#     skip_requesting_account_id  = true
#     skip_metadata_api_check     = true
#     skip_s3_checksum            = true
#     use_path_style              = true
#   }
# }
