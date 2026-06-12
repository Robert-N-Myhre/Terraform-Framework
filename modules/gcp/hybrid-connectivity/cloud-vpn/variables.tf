# ---------------------------------------------------------------------------
# Governance variables (required by framework convention — see governance/)
# ---------------------------------------------------------------------------
variable "prefix" {
  type        = string
  description = "Short organization or project prefix. First token of every resource name: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, test, prod). Used in resource names and mandatory labels."
}

variable "owner" {
  type        = string
  description = "Team or individual that owns the deployed resources. Applied as the mandatory 'owner' label where supported (lowercased)."
}

variable "cost_center" {
  type        = string
  description = "Cost center code. Applied as the mandatory 'cost_center' label where supported (lowercased)."
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional additional labels merged beneath the mandatory label set (lowercased)."
  default     = {}
}

variable "name_suffix" {
  type        = string
  description = "Final token of every resource name, used to disambiguate multiple instances of this module."
  default     = "01"
}

# ---------------------------------------------------------------------------
# Module-specific variables
# ---------------------------------------------------------------------------
variable "project_id" {
  type        = string
  description = "GCP project ID hosting the VPN gateway."
}

variable "region" {
  type        = string
  description = "Region of the HA VPN gateway and Cloud Router."
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the VPC network. Supplied as a plain value — no framework dependency is implied."
}

variable "router_asn" {
  type        = number
  description = "Google-side BGP ASN for the Cloud Router (private range; must differ from peer ASNs)."
  default     = 64514
}

variable "peer_gateways" {
  type = map(object({
    interfaces = list(string) # 1 or 2 public IPs of the on-prem/peer device(s)
  }))
  description = "External (on-premises) peer VPN gateways keyed by logical name. Two interfaces enable the 99.99% HA topology."
}

variable "tunnels" {
  type = map(object({
    peer_gateway_key                = string
    peer_external_gateway_interface = number # 0 or 1
    vpn_gateway_interface           = number # 0 or 1 (GCP side)
    shared_secret                   = string # sensitive
    ike_version                     = optional(number, 2)

    # BGP session for this tunnel
    bgp_session_range         = string # GCP-side /30 link-local, e.g. "169.254.40.1/30"
    peer_bgp_ip               = string # on-prem side of the /30, e.g. "169.254.40.2"
    peer_asn                  = number
    advertised_route_priority = optional(number, 100)
  }))
  description = "HA VPN tunnels keyed by logical name, each with its BGP session. For 99.99% SLA create 2 or 4 tunnels across both gateway interfaces."
  sensitive   = true
}
