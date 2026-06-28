terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Модуль S3 та DynamoDB для бекенду
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "terraform-state-bucket-lesson7-qvnkd"
  table_name  = "terraform-locks-lesson7"
}

# Модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"
}

# Модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-django-repo"
  scan_on_push = true
}

# Модуль Kubernetes кластера (EKS)
module "eks" {
  source             = "./modules/eks"
  cluster_name       = "lesson-7-eks-cluster"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}