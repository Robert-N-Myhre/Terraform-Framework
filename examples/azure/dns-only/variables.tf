variable "subscription_id" {
  type        = string
  description = "Azure subscription ID to deploy into."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the EXISTING resource group."
}

variable "vnet_id" {
  type        = string
  description = "ID of the EXISTING VNet to link the zone to."
}

variable "domain_name" {
  type        = string
  description = "Private DNS domain to create."
  default     = "dev.internal.example.com"
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
  default     = "platform-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code (mandatory tag)."
  default     = "CC-0000"
}
