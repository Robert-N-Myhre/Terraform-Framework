# Example — vWAN with Third-Party NVA Firewall (VM-Series Pattern)

Composes four independently invocable modules into a **firewall services hub**:
a vWAN hub whose spoke and branch traffic is steered through a Palo Alto
VM-Series-style firewall fleet living in a connected services VNet, behind an
internal Standard LB (HA-ports sandwich).

```
                 ┌────────────── vWAN Hub (10.99.0.0/23) ─────────────┐
 Branches ─VPN/ER┤  Default RT: 10/8,172.16/12,192.168/16 → fw-conn   │
                 │  "spokes" RT: 0/0 + RFC1918 → fw-conn              │
                 └───────┬───────────────┬───────────────┬────────────┘
                   fw-conn│         spoke1-conn      spoke2-conn
        (static route:    │        (assoc "spokes",  (assoc "spokes",
         inspected → ILB) │         propagate none)   propagate none)
              ┌───────────▼──────────┐
              │ FW VNet 10.90.0.0/16 │
              │ untrust│trust│mgmt   │
              │ ILB 10.90.1.100 ──► VM-Series ×N (out of scope)
              └──────────────────────┘
```

## Why no routing intent

Routing intent only accepts **in-hub** next-hops (Azure Firewall, integrated hub
NVAs, SaaS Cloud NGFW). A VM-Series fleet in a connected VNet doesn't qualify, so
this example uses the documented NVA-in-spoke mechanics instead:

1. `hub_routes` on the custom `spokes` table (0/0 + RFC1918) and on the
   **default** table (RFC1918, for branches) point at the firewall *connection*.
2. A `static_vnet_route` on the firewall connection carries the next-hop **IP**:
   the trust-side ILB frontend (`10.90.1.100`).
3. Spoke connections associate with `spokes` and **propagate to none**.

## What is deployed

| Module | Instance | Purpose |
|--------|----------|---------|
| `azure/core-network` | `firewall_vnet` | untrust/trust/mgmt subnets for the NVA fleet |
| `azure/core-network` | `spoke1_vnet`, `spoke2_vnet` | workload spokes |
| `azure/load-balancer/load-balancer` | `firewall_ilb` | trust-side internal LB, HA-ports rule, TCP/443 probe |
| `azure/transit/vwan` | `vwan` | WAN + hub + route tables + connections + steering routes |

## What is deliberately NOT deployed

- **VM-Series VMs/VMSS** — compute, licensing, and PAN-OS bootstrap are outside
  this networking framework. The integration seams are exported as outputs:
  `vmseries_backend_pool_id` (trust NICs join this pool),
  `firewall_vnet_subnet_ids` (NIC placement), `firewall_ilb_frontend_ip`.
- **NSGs** — compose `azure/firewall/nsgs` against the firewall VNet subnets the
  same way the `core-network-with-nsgs` example shows (untrust needs an
  allow-from-Internet posture only if you publish inbound services).
- **Hub gateways** — attach branches by invoking the hybrid modules in vhub
  mode, wiring this example's outputs:

  ```hcl
  module "vwan_vpn" {
    source          = "../../../modules/azure/hybrid-connectivity/vpn"
    attachment_type = "vhub"
    virtual_hub_id  = module.vwan.hub_id["main"]
    virtual_wan_id  = module.vwan.wan_id
    # ... sites + connections
  }
  ```

- **BGP option** — instead of relying purely on static routes, peer the
  VM-Series with the hub router via the vwan module's `bgp_connections`
  (`peer_asn` must differ from the hub's fixed 65515).

## Required inputs

| Variable | Description |
|----------|-------------|
| `subscription_id` | Target subscription. |

## How to run

```bash
terraform init
terraform apply -var "subscription_id=00000000-...."
```

Hub provisioning takes 20-30 minutes.

## Operational caveats

- **Branches always associate with the default route table** — that's why the
  RFC1918 steering route is duplicated there; a custom table cannot capture
  branch traffic.
- **Every** spoke connection must associate with `spokes` + propagate-to-none;
  one unisolated spoke bypasses inspection.
- Symmetric flows through the ILB sandwich rely on the HA-ports rule and
  consistent routing on both legs; inter-hub (cross-region) hairpinning through
  an NVA-in-spoke has documented vWAN limitations — deploy one firewall VNet per
  hub.
- Management locks are disabled here for lab teardown; leave the defaults
  (`true`) in real environments.

## State

`backend.tf` carries the commented Azure Blob Storage pattern. See
[docs/state-management.md](../../../docs/state-management.md).
