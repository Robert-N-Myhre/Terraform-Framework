# State Management Guide

State backend configuration is **always the consumer's responsibility** — no
leaf module in this framework configures or assumes a backend
(see [ADR 005](adr/005-state-management-pattern.md)). This guide covers the
recommended patterns.

## Recommended backends per cloud

### AWS — S3 + DynamoDB

```hcl
terraform {
  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "networking/prod/core-network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "acme-terraform-locks"
    encrypt        = true
  }
}
```

Bootstrap (once, manually or via a tiny dedicated config): an S3 bucket with
**versioning** and **SSE** enabled and public access blocked, plus a DynamoDB
table with partition key `LockID` (string).

### Azure — Blob Storage

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "acmetfstate"
    container_name       = "tfstate"
    key                  = "networking/prod/core-network/terraform.tfstate"
  }
}
```

Locking is native (blob leases) — no extra component. Enable blob versioning
and soft delete on the storage account.

### GCP — GCS

```hcl
terraform {
  backend "gcs" {
    bucket = "acme-terraform-state"
    prefix = "networking/prod/core-network"
  }
}
```

Locking is native. Enable object versioning on the bucket.

### OCI — Object Storage (S3-compatible)

```hcl
terraform {
  backend "s3" {
    bucket = "acme-terraform-state"
    key    = "networking/prod/core-network/terraform.tfstate"
    region = "us-ashburn-1"
    endpoints = {
      s3 = "https://<namespace>.compat.objectstorage.us-ashburn-1.oraclecloud.com"
    }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
```

Credentials come from an S3-compatibility **Customer Secret Key** (created in
OCI IAM). Note: the S3-compat endpoint provides no DynamoDB, so there is **no
state locking** — serialize applies through CI for shared OCI states.

## State isolation strategy

Match state topology to the framework's independence model:

- **One state per module invocation (recommended).** Each independently
  invoked module gets its own root config and its own state key
  (`networking/<env>/<module>/terraform.tfstate`). Blast radius of a corrupt
  or locked state is one capability; plans stay fast; teams can own different
  states.
- **One state per composition.** When modules are deliberately composed (like
  the `core-network-with-*` examples), the composition root is the state
  boundary — outputs flow in-memory, not via `terraform_remote_state`.
- **Avoid** one mega-state for all networking: it serializes all changes,
  inflates plan time, and couples unrelated failure domains.

Cross-state references use data sources against real cloud APIs (look up the
VPC by tag/name) or `terraform_remote_state` — prefer data sources; they don't
couple you to another team's state schema.

## Workspace strategy

Use **directory-per-environment** (or var-files) rather than CLI workspaces for
environment separation: different environments usually need different backend
configs, credentials, and review gates, which workspaces share awkwardly.
Reserve CLI workspaces for true short-lived clones of one configuration
(ephemeral test stacks, PR previews).

## Migrating from local to remote state

Started with local state (the examples' default) and need to graduate?

1. Uncomment/fill the backend block in `backend.tf`.
2. Run `terraform init -migrate-state` and confirm — Terraform copies the local
   state to the backend.
3. Verify: `terraform plan` shows no changes.
4. Delete `terraform.tfstate*` locally and add them to `.gitignore` (never
   commit state — it contains sensitive values like VPN pre-shared keys).

To move state *between* remote backends, the same `-migrate-state` flow
applies. To split a mega-state along module lines, use
`terraform state mv -state-out` per resource address, or re-import into fresh
states for a cleaner cut.

## Sensitive values in state

VPN pre-shared keys, BGP auth keys, and certificate keys handled by the
hybrid-connectivity and load-balancer modules **are stored in state in
plaintext** (standard Terraform behavior). Therefore: encrypt state at rest
(all recommended backends above do), restrict read access to the state
backend as strictly as to the secrets themselves, and never commit state files.
