variable "region" {
  type        = string
  description = "AWS region of the existing VPC."
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "ID of the EXISTING VPC to associate the private zone with."
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
