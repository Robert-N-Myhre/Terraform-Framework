# ---------------------------------------------------------------------------
# Remote state backend — RECOMMENDED for any shared environment.
# Uncomment and fill in. See docs/state-management.md.
# ---------------------------------------------------------------------------
# terraform {
#   backend "s3" {
#     bucket         = "acme-terraform-state"
#     key            = "examples/aws/dns-only/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "acme-terraform-locks"
#     encrypt        = true
#   }
# }
