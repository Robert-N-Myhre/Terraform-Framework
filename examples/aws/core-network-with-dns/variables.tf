variable "region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.21.0.0/16"
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
  default     = "network-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code (mandatory tag)."
  default     = "CC-0000"
}
