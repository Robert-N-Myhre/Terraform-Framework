# GCP Load Balancer — Global External HTTP(S) LB

Creates the full global external L7 chain: global static IP → HTTP/HTTPS forwarding
rules → target proxies → URL map (host/path routing) → backend services (with CDN
and Cloud Armor attachment) → health checks, plus an optional Google-managed SSL
certificate.

**Independently invocable.** Backend groups (MIGs/NEGs) and Cloud Armor policy IDs
are plain inputs.

> Google-managed certificates only activate **after** DNS resolves to the LB IP —
> expect `PROVISIONING` until then.

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
| backend_services | `map(object)` | Backend services with groups, health checks, CDN, Cloud Armor | n/a | yes |
| default_backend_service_key | `string` | URL-map default | n/a | yes |
| host_rules | `map(object)` | Host/path routing | `{}` | no |
| enable_https | `bool` | HTTPS frontend | `false` | no |
| managed_certificate_domains | `list(string)` | Managed cert domains | `[]` | no |
| ssl_certificate_ids | `list(string)` | Existing cert self-links | `[]` | no |
| enable_http | `bool` | HTTP frontend | `true` | no |
| static_ip_name | `string` | Global IP name override | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | URL map ID |
| lb_address | Global anycast IP (point DNS here) |
| listener_ids | `https` / `http` → forwarding rule IDs |
| backend_ids | Logical name → backend service ID |
| managed_certificate_id | Managed cert ID or null |

## Usage

```hcl
module "external_lb" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/load-balancer/external"

  prefix      = "acme"
  environment = "prod"
  owner       = "web-team"
  cost_center = "cc-4100"

  project_id = "acme-prod-networking"

  backend_services = {
    web = {
      groups = {
        east = { group = "https://www.googleapis.com/compute/v1/projects/acme-prod-networking/zones/us-east1-b/instanceGroups/web-mig" }
      }
      health_check       = { port = 8080, request_path = "/healthz" }
      security_policy_id = "projects/acme-prod-networking/global/securityPolicies/acme-gcp-prod-armor-01"
    }
  }

  default_backend_service_key = "web"

  enable_https                = true
  managed_certificate_domains = ["www.example.com"]
}
```

## Cross-cloud divergence

A **chain of six resource types** vs AWS ALB's three and Azure App Gateway's one.
Globally anycast — one IP serves all regions (no other cloud's standard L7 LB does
this). Health checks originate from `35.191.0.0/16` / `130.211.0.0/22`; allow them
in firewall rules.
