# GCP DNS — Private Managed Zones

Creates private Cloud DNS managed zones — plain (with record sets), forwarding
(queries delegated to target name servers), or peering (namespace delegated to
another VPC) — with VPC visibility lists and labels.

**Independently invocable.** VPC self-links are plain inputs.

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
| owner | `string` | Owning team (label, lowercased) | n/a | yes |
| cost_center | `string` | Cost center (label, lowercased) | n/a | yes |
| additional_tags | `map(string)` | Extra labels | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| project_id | `string` | GCP project ID | n/a | yes |
| private_zones | `map(object)` | Zones (domain needs trailing dot): visibility networks, optional forwarding targets or peering network, records | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| zone_ids | Logical name → zone ID |
| zone_names | Logical name → domain (trailing dot) |
| zone_resource_names | Logical name → GCP resource name |
| record_ids | `<zone>/<record>` → record set ID |

## Usage

```hcl
module "private_dns" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/dns/private-zones"

  prefix      = "acme"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "cc-3300"

  project_id = "acme-prod-networking"

  private_zones = {
    internal = {
      domain_name        = "prod.internal.example.com."
      network_self_links = ["https://www.googleapis.com/compute/v1/projects/acme-prod-networking/global/networks/acme-gcp-prod-vpc-01"]
      records = {
        api = { name = "api", type = "A", rrdatas = ["10.60.10.15"] }
      }
    }
    onprem-forward = {
      domain_name        = "corp.example.com."
      network_self_links = ["https://www.googleapis.com/compute/v1/projects/acme-prod-networking/global/networks/acme-gcp-prod-vpc-01"]
      forwarding_targets = [{ ipv4_address = "10.250.0.10" }]
    }
  }
}
```

## Cross-cloud divergence

GCP folds forwarding into the **zone type** (forwarding zones) where AWS/Azure use
separate resolver-rule resources — see `gcp/dns/dns-policy` for inbound forwarding.
Domain names require a **trailing dot**. Resolving VPCs attach as a list on the
zone, not as standalone link resources.
