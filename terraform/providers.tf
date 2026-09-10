terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state: S3 + DynamoDB lock. Bootstrap bucket/table once via
  # scripts/bootstrap-state.sh or `terraform init -backend-config=...`.
  # Default local backend is used until backend.hcl is supplied so that
  # `terraform init` works out of the box for contributors.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "stellariq"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Kubernetes / Helm providers are wired after the cluster module outputs
# the endpoint. They intentionally stay unconfigured until then so that
# `terraform plan -target=module.networking` etc. works pre-cluster.
provider "kubernetes" {
  host                   = try(module.cluster[0].cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.cluster[0].cluster_ca_data), null)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "${local.cluster_name}"]
  }
}

provider "helm" {
  kubernetes {
    host                   = try(module.cluster[0].cluster_endpoint, null)
    cluster_ca_certificate = try(base64decode(module.cluster[0].cluster_ca_data), null)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", "${local.cluster_name}"]
    }
  }
}
