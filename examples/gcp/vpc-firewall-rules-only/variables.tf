variable "project_id" {
  type        = string
  description = "GCP project ID containing the existing network."
}

variable "region" {
  type        = string
  description = "Default provider region."
  default     = "us-east1"
}

variable "network_name" {
  type        = string
  description = "Name of the EXISTING VPC network the rules attach to."
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
  description = "Owning team."
  default     = "network-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code."
  default     = "cc-0000"
}
