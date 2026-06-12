variable "region" {
  type        = string
  description = "OCI region."
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  type        = string
  description = "OCID of the compartment."
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
  description = "Owning team (freeform tag)."
  default     = "platform-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code (freeform tag)."
  default     = "CC-0000"
}
