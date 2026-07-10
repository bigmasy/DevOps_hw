output "cluster_name" { value = aws_eks_cluster.main.name }
output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = aws_iam_role.node.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.oidc.url
}