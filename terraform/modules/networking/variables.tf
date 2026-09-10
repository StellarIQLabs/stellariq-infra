variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "az_count" {
  description = "Number of AZs to span (2 or 3)."
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment name."
  type        = string
}
