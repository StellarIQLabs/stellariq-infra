locals {
  name_prefix  = "${var.project}-${var.environment}"
  cluster_name = "${var.project}-${var.environment}"
}

module "networking" {
  source      = "./modules/networking"
  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

module "postgres" {
  source            = "./modules/postgres"
  name_prefix       = local.name_prefix
  environment       = var.environment
  subnet_ids        = module.networking.database_subnet_ids
  security_group_id = module.networking.database_security_group_id
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
}

module "redis" {
  source            = "./modules/redis"
  name_prefix       = local.name_prefix
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.networking.redis_security_group_id
  node_type         = var.redis_node_type
}

module "queues" {
  source      = "./modules/queues"
  name_prefix = local.name_prefix
  environment = var.environment
}

module "backups" {
  source        = "./modules/backups"
  name_prefix   = local.name_prefix
  db_identifier = "${local.name_prefix}-postgres"
}

module "secrets" {
  source      = "./modules/secrets"
  name_prefix = local.name_prefix
  environment = var.environment
}

module "registry" {
  source      = "./modules/registry"
  name_prefix = local.name_prefix
}

module "cluster" {
  source             = "./modules/cluster"
  count              = var.environment == "dev" ? 0 : 1
  name_prefix        = local.name_prefix
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  instance_types     = var.cluster_instance_types
  min_size           = var.cluster_min_size
  max_size           = var.cluster_max_size
  desired_size       = var.cluster_desired_size
}

