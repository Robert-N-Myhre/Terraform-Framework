variable "subscription_id" {
  type        = string
  description = "Azure subscription ID to deploy into."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus2"
}

variable "hub_cidr" {
  type        = string
  description = "Address prefix for the vWAN hub (/23 or larger; must not overlap any VNet or branch)."
  default     = "10.99.0.0/23"
}

variable "firewall_vnet_cidr" {
  type        = string
  description = "Address space for the firewall services VNet (untrust/trust/mgmt subnets are derived from it)."
  default     = "10.90.0.0/16"
}

variable "spoke1_cidr" {
  type        = string
  description = "Address space for spoke VNet 1."
  default     = "10.91.0.0/16"
}

variable "spoke2_cidr" {
  type        = string
  description = "Address space for spoke VNet 2."
  default     = "10.92.0.0/16"
}

variable "prefix" {
  type        = string
  description = "Org/project prefix for resource naming."
  default     = "acme"
}

variable "environment" {
  type        = string
  description = "Environment identifier."
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Owning team (mandatory tag)."
  default     = "network-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code (mandatory tag)."
  default     = "CC-0000"
}
