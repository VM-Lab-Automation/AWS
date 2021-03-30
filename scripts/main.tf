terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.location
  shared_credentials_file = var.shared_credentials_file
  profile                 = "default"
}

module "database" {
  source = "./database"
  allocated_size = var.database.allocated_size
  engine_type = var.database.engine_type
  instance_class = var.database.instance_class
  username = var.database.username
  password_seed = var.database.password_seed
  db_name = var.database.db_name
  db_security_group_id = module.vpc.db_security_group_id
  subnet_ids = module.vpc.subnet_ids
}

module "vpc" {
  source = "./vpc"
}