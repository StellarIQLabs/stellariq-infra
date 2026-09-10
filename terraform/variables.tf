variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment: staging | production | demo | dev."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production", "demo"], var.environment)
    error_message = "environment must be one of: dev, staging, production, demo."
  }
}

variable "project" {
  description = "Project slug used in resource naming."
  type        = string
  default     = "stellariq"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
  default     = 50
}

variable "redis_node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "cluster_instance_types" {
  description = "EKS managed node group instance types."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "cluster_min_size" {
  description = "EKS node group minimum size."
  type        = number
  default     = 2
}

variable "cluster_max_size" {
  description = "EKS node group maximum size."
  type        = number
  default     = 6
}

variable "cluster_desired_size" {
  description = "EKS node group desired size."
  type        = number
  default     = 3
}

variable "soroban_rpc_testnet" {
  description = "Soroban testnet RPC endpoint."
  type        = string
  default     = "https://soroban-testnet.stellar.org"
}

variable "soroban_rpc_mainnet" {
  description = "Soroban mainnet RPC endpoint."
  type        = string
  default     = "https://soroban.stellar.org"
}

variable "soroban_testnet_passphrase" {
  description = "Stellar testnet network passphrase."
  type        = string
  default     = "Test SDF Network ; September 2015"
}

variable "soroban_mainnet_passphrase" {
  description = "Stellar public network passphrase."
  type        = string
  default     = "Public Global Stellar Network ; September 2015"
}
