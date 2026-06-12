# OCI Core Network

Creates a VCN with regional subnets (private by default), per-subnet route tables,
optional internet/NAT/service gateways, and per-subnet VCN flow logs via the OCI
Logging service.

**Independently invocable.** Only a compartment OCID is required.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| oci (oracle/oci) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| oci | ~> 5.0 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (freeform tag) | n/a | yes |
| cost_center | `string` | Cost center (freeform tag) | n/a | yes |
| additional_tags | `map(string)` | Extra freeform tags | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| compartment_id | `string` | Compartment OCID | n/a | yes |
| vcn_cidr_blocks | `list(string)` | VCN CIDRs | n/a | yes |
| dns_label | `string` | VCN DNS label (immutable) | `null` | no |
| subnets | `map(object)` | Subnets with per-subnet route rules (gateway keywords: igw/natgw/sgw) | n/a | yes |
| create_internet_gateway | `bool` | IGW | `false` | no |
| create_nat_gateway | `bool` | NAT GW | `false` | no |
| create_service_gateway | `bool` | Service GW (private OCI-service access) | `false` | no |
| enable_flow_logs | `bool` | Per-subnet flow logs | `false` | no |
| flow_log_retention_days | `number` | Log retention (30-180) | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | VCN OCID |
| network_cidr | VCN CIDR blocks (list) |
| subnet_ids / subnet_cidrs | Per-subnet identifiers |
| route_table_ids | Logical name → route table OCID |
| internet_gateway_id / nat_ids / service_gateway_id | Gateway OCIDs |
| default_security_list_id | VCN default security list OCID |
| flow_log_id | Logical subnet name → flow-log OCID |

## Usage

```hcl
module "core_network" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/core-network"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  compartment_id  = "ocid1.compartment.oc1..aaaa..."
  vcn_cidr_blocks = ["10.80.0.0/16"]
  dns_label       = "acmeprod"

  create_internet_gateway = true
  create_nat_gateway      = true

  subnets = {
    public = {
      cidr_block                 = "10.80.0.0/24"
      prohibit_public_ip_on_vnic = false
      route_rules = {
        default = { destination = "0.0.0.0/0", network_entity_key = "igw" }
      }
    }
    app = {
      cidr_block = "10.80.10.0/24"
      route_rules = {
        default = { destination = "0.0.0.0/0", network_entity_key = "natgw" }
      }
    }
  }

  enable_flow_logs = true
}
```

## Cross-cloud divergence

- Route tables bind to subnets **at subnet creation** (`route_table_id`), not via
  separate association resources (AWS/Azure).
- The **Service Gateway** (private OCI-service access) is the analogue of AWS
  Gateway VPC endpoints; Azure/GCP use Private Link / Private Google Access.
- Subnets are **regional** by default; AD-scoped subnets are legacy.
- `dns_label` is immutable after creation — changing it forces VCN replacement.
