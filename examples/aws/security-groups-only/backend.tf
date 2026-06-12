# ---------------------------------------------------------------------------
# Remote state backend — RECOMMENDED for any shared environment.
# Uncomment and fill in. See docs/state-management.md for the full pattern,
# including bucket/table bootstrap and state isolation guidance.
# ---------------------------------------------------------------------------
# terraform {
#   backend "s3" {
#     bucket         = "acme-terraform-state"          # pre-existing, versioned, encrypted
#     key            = "examples/aws/security-groups-only/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "acme-terraform-locks"          # pre-existing, PK: LockID (string)
#     encrypt        = true
#   }
# }
