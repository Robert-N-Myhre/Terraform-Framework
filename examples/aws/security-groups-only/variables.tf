variable "region" {
  type        = string
  description = "AWS region of the existing VPC."
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "ID of the EXISTING VPC to create the security groups in."
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
