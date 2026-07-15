terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "terraform-state-bucket-lesson7-qvnkd"
  table_name  = "terraform-locks-lesson7"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-django-repo"
  scan_on_push = true
}

# Реєстр і назва образу виводяться з реального ECR-репозиторію, а не задаються
# вручну — інакше TF_VAR_ecr_image_name міг би не збігатися з ecr_name вище,
# і Kaniko не зміг би запушити образ (ECR не створює репозиторій сам при push).
locals {
  ecr_registry   = split("/", module.ecr.repository_url)[0]
  ecr_image_name = split("/", module.ecr.repository_url)[1]
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = "lesson-7-eks-cluster"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

# Без цього тегу AWS cloud provider не може визначити, які підмережі належать
# кластеру, і Service type=LoadBalancer (Jenkins, Argo CD) залишиться <pending>
# без зовнішньої адреси. count замість for_each — на apply "з нуля" самі ID
# підмереж ще невідомі, відома лише кількість (статична, з var.*_subnets).
resource "aws_ec2_tag" "cluster_subnets_public" {
  count       = length(module.vpc.public_subnet_ids)
  resource_id = module.vpc.public_subnet_ids[count.index]
  key         = "kubernetes.io/cluster/${module.eks.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "cluster_subnets_private" {
  count       = length(module.vpc.private_subnet_ids)
  resource_id = module.vpc.private_subnet_ids[count.index]
  key         = "kubernetes.io/cluster/${module.eks.cluster_name}"
  value       = "shared"
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.eks.token
}

module "jenkins" {
  source       = "./modules/jenkins"
  cluster_name = module.eks.cluster_name

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  jenkins_admin_username = var.jenkins_admin_username
  jenkins_admin_password = var.jenkins_admin_password

  github_username = var.github_username
  github_pat      = var.github_pat

  infra_repo_url     = var.infra_repo_url
  infra_repo_branch  = var.infra_repo_branch
  django_repo_url    = var.django_repo_url
  django_repo_branch = var.django_repo_branch

  ecr_registry   = local.ecr_registry
  ecr_image_name = local.ecr_image_name
  ecr_image_tag  = var.ecr_image_tag

  jenkins_url = var.jenkins_url

  app_chart_path   = var.app_chart_path
  git_commit_email = var.git_commit_email
  git_commit_name  = var.git_commit_name
}

module "argo_cd" {
  source = "./modules/argo-cd"

  infra_repo_url    = var.infra_repo_url
  infra_repo_branch = var.infra_repo_branch
  app_chart_path    = var.app_chart_path
  app_namespace     = var.app_namespace

  django_secret_key        = var.django_secret_key
  django_postgres_password = var.django_postgres_password

  github_username = var.github_username
  github_pat      = var.github_pat
}

# Вимкнений за замовчуванням (var.enable_rds = false) — RDS/Aurora суттєво
# дорожчі за решту стеку, не кожен apply цього репозиторію має їх створювати.
module "rds" {
  source = "./modules/rds"
  count  = var.enable_rds ? 1 : 0

  identifier             = "lesson-db-module"
  use_aurora             = var.rds_use_aurora
  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  parameter_group_family = var.rds_parameter_group_family
  instance_class         = var.rds_instance_class
  multi_az               = var.rds_multi_az
  aurora_instance_count  = var.rds_aurora_instance_count

  db_name  = var.rds_db_name
  username = var.rds_username
  password = var.rds_password

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  ingress_cidr_blocks = ["10.0.0.0/16"]

  skip_final_snapshot = true
}