# ---------------------------------------------------------------------------
# Remote state backend — RECOMMENDED for any shared environment.
# Uncomment and fill in. See docs/state-management.md.
# ---------------------------------------------------------------------------
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"      # pre-existing
#     storage_account_name = "acmetfstate"             # pre-existing, versioned
#     container_name       = "tfstate"
#     key                  = "examples/azure/nsgs-only/terraform.tfstate"
#   }
# }
