variable "subscription_id" {
  type        = string
  description = "Azure subscription ID to deploy into."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the EXISTING resource group."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus2"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Optional existing subnet IDs to associate the NSG with."
  default     = []
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
