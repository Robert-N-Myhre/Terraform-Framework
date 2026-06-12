variable "project_id" {
  type        = string
  description = "GCP project ID to deploy into."
}

variable "region" {
  type        = string
  description = "Region for subnets and Cloud NAT."
  default     = "us-east1"
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
  default     = "network-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code (mandatory label)."
  default     = "cc-0000"
}
