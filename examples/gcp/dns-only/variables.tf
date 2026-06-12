variable "project_id" {
  type        = string
  description = "GCP project ID to deploy into."
}

variable "region" {
  type        = string
  description = "Default provider region."
  default     = "us-east1"
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the EXISTING VPC that can resolve the zone."
}

variable "domain_name" {
  type        = string
  description = "Private DNS domain (MUST end with a trailing dot)."
  default     = "dev.internal.example.com."
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
  description = "Owning team (mandatory label)."
  default     = "platform-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code (mandatory label)."
  default     = "cc-0000"
}
