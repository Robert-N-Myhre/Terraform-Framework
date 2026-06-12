# GCP Transit — Network Connectivity Center

Creates an NCC hub with VPC-network spokes (full-mesh inter-VPC reachability) and
hybrid spokes (HA VPN tunnels / Interconnect VLAN attachments, optional
branch-to-branch transfer over Google's backbone).

**Independently invocable.** Spoke VPC self-links and tunnel/attachment URIs are
plain inputs.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 5.0 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (label) | n/a | yes |
| cost_center | `string` | Cost center (label) | n/a | yes |
| additional_tags | `map(string)` | Extra labels | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| project_id | `string` | GCP project ID | n/a | yes |
| hub_description | `string` | Hub description | `"Managed by Terraform"` | no |
| vpc_spokes | `map(object)` | VPC spokes + exclude_export_ranges | `{}` | no |
| hybrid_spokes | `map(object)` | VPN/Interconnect spokes per region | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| hub_id | NCC hub ID |
| attachment_ids | All spokes: logical name → spoke ID |
| vpc_spoke_ids | VPC spokes only |
| hybrid_spoke_ids | Hybrid spokes only |

## Usage

```hcl
module "ncc" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/transit/network-connectivity-center"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "cc-1042"

  project_id = "acme-prod-networking"

  vpc_spokes = {
    app    = { vpc_self_link = "https://www.googleapis.com/compute/v1/projects/acme-app/global/networks/app-vpc" }
    shared = { vpc_self_link = "https://www.googleapis.com/compute/v1/projects/acme-shared/global/networks/shared-vpc" }
  }
}
```

## Cross-cloud divergence

NCC has **no per-spoke route tables** — all VPC spokes get full-mesh subnet
reachability; `exclude_export_ranges` is the only segmentation lever. AWS TGW /
Azure vWAN / OCI DRG segmentation designs do not port here. VPC spokes are
`location = "global"`; hybrid spokes are regional.
