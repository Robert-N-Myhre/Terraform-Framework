# GCP DNS — DNS Server Policy

Creates a DNS server policy attached to one or more VPC networks: inbound
forwarding (on-premises → Cloud DNS resolution), query logging, and optional
network-wide alternative name servers.

**Independently invocable.** Network self-links are plain inputs.

> Only **one DNS policy per network** is allowed — the API rejects a second at
> apply time. DNS policies are not labelable; governance tagging is honored via
> naming convention only.

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
| owner | `string` | Convention parity | n/a | yes |
| cost_center | `string` | Convention parity | n/a | yes |
| additional_tags | `map(string)` | Convention parity | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| project_id | `string` | GCP project ID | n/a | yes |
| network_self_links | `list(string)` | Attached VPCs (one policy each!) | n/a | yes |
| enable_inbound_forwarding | `bool` | Allocate inbound forwarder IPs | `false` | no |
| enable_logging | `bool` | Query logging | `false` | no |
| alternative_name_servers | `list(object)` | Network-wide forwarders (use sparingly) | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_id | DNS policy ID |
| inbound_forwarding_enabled | Whether inbound forwarding is on (forwarder IPs visible in console/API only) |

## Usage

```hcl
module "dns_policy" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/dns/dns-policy"

  prefix      = "acme"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "cc-3300"

  project_id = "acme-prod-networking"
  network_self_links = [
    "https://www.googleapis.com/compute/v1/projects/acme-prod-networking/global/networks/acme-gcp-prod-vpc-01"
  ]

  enable_inbound_forwarding = true
  enable_logging            = true
}
```

## Cross-cloud divergence

Fills the role of AWS/Azure **inbound** resolver endpoints; outbound per-domain
forwarding lives in forwarding **zones** (`gcp/dns/private-zones`). Alternative
name servers redirect ALL queries — the blunt instrument; prefer forwarding zones
for per-domain control. Inbound forwarder IPs are allocated per network and are not
exposed as Terraform attributes.
