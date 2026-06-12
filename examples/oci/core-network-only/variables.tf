variable "region" {
  type        = string
  description = "OCI region."
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  type        = string
  description = "OCID of the compartment to deploy into."
}

variable "vcn_cidr" {
  type        = string
  description = "VCN CIDR block."
  default     = "10.80.0.0/16"
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
  default     = "network-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code (freeform tag)."
  default     = "CC-0000"
}
