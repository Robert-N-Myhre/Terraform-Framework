# OCI Load Balancer — Load Balancer

Creates a flexible-shape OCI Load Balancer (public or private) with backend sets,
health checkers, optional static backend registration, session persistence, TLS
certificates, and HTTP/TCP listeners.

**Independently invocable.** Subnet and NSG OCIDs are plain inputs. Dynamic backend
registration (instance pools) is the consumer's responsibility.

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
| subnet_ids | `list(string)` | LB subnets (1 regional typical) | n/a | yes |
| is_private | `bool` | Private LB | `true` | no |
| shape_min_mbps / shape_max_mbps | `number` | Flexible shape bounds | `10` / `100` | no |
| nsg_ids | `list(string)` | Attached NSGs | `[]` | no |
| backend_sets | `map(object)` | Sets + health checkers + static backends | n/a | yes |
| listeners | `map(object)` | Listeners → default backend set | n/a | yes |
| certificates | `map(object)` | TLS certs (sensitive) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | LB OCID |
| lb_address | First LB IP |
| listener_ids | Logical name → listener name |
| backend_ids | Logical name → backend set name |

## Usage

```hcl
module "lb" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/load-balancer/load-balancer"

  prefix      = "acme"
  environment = "prod"
  owner       = "web-team"
  cost_center = "CC-4100"

  compartment_id = "ocid1.compartment.oc1..aaaa..."
  subnet_ids     = ["ocid1.subnet.oc1..aaaa..."]
  is_private     = false

  backend_sets = {
    web = {
      health_checker = { protocol = "HTTP", port = 8080, url_path = "/healthz" }
      backends = {
        web1 = { ip_address = "10.80.10.11", port = 8080 }
        web2 = { ip_address = "10.80.10.12", port = 8080 }
      }
    }
  }

  listeners = {
    http = { port = 80, protocol = "HTTP", default_backend_set_key = "web" }
  }
}
```

## Cross-cloud divergence

One LB resource with **named child resources** (backend sets, listeners, certs) —
closest to Azure's model. Backends register by **IP:port into the set** (vs AWS
target-group registration). Fixed shapes are deprecated; this module uses flexible
shapes only. For pure L4 passthrough, use `oci/load-balancer/network-load-balancer`.
