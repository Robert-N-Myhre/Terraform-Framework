variable "region" {
  type        = string
  description = "OCI region."
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  type        = string
  description = "OCID of the compartment."
}

variable "vcn_id" {
  type        = string
  description = "OCID of the EXISTING VCN."
}

variable "admin_cidr" {
  type        = string
  description = "CIDR allowed to SSH."
  default     = "10.0.0.0/8"
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
