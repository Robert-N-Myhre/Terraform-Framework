# Azure Firewall — Application Security Groups

Creates application security groups — workload-identity handles referenced by NSG
rules. NIC membership and NSG rule wiring happen outside this module: associate NICs
where the workloads are managed, and pass the ASG IDs output here into
`azure/firewall/nsgs` rules.

**Independently invocable.** No framework dependency exists.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.80 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (mandatory tag) | n/a | yes |
| cost_center | `string` | Cost center (mandatory tag) | n/a | yes |
| additional_tags | `map(string)` | Extra tags | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| resource_group_name | `string` | Existing resource group | n/a | yes |
| location | `string` | Azure region (must match NIC region for association) | n/a | yes |
| application_security_groups | `set(string)` | Logical ASG names to create | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | Logical name → ASG ID |
| asg_names | Logical name → ASG name |

## Usage

```hcl
module "asgs" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/firewall/asgs"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"

  application_security_groups = ["web", "app", "db"]
}

# Consumer root module then wires ASG IDs into NSG rules and NIC associations.
```

## Cross-cloud divergence

ASGs fill the role that SG-to-SG references play in AWS and network tags play in
GCP: rule targets decoupled from IP addresses. Neither AWS, GCP, nor OCI has a
standalone resource for this concept.
