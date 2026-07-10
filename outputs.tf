output "s3_backend_bucket" {
  description = "The name of the S3 bucket for Terraform state"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "eks_kubeconfig_command" {
  description = "The CLI command to update kubeconfig for kubectl access"
  value       = "aws eks update-kubeconfig --region us-west-2 --name ${module.eks.cluster_name}"
}

output "jenkins_release" {
  description = "The name of the Jenkins Helm release"
  value       = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  description = "The Kubernetes namespace where Jenkins is deployed"
  value       = module.jenkins.jenkins_namespace
}

output "argo_cd_namespace" {
  description = "The Kubernetes namespace where Argo CD is deployed"
  value       = module.argo_cd.argo_cd_namespace
}

output "argo_cd_server_hint" {
  description = "Command to fetch the Argo CD UI external address"
  value       = module.argo_cd.argo_cd_server_hint
}

output "argo_cd_admin_password_hint" {
  description = "Command to fetch the initial Argo CD admin password"
  value       = module.argo_cd.admin_password_hint
}