output "jenkins_release_name" {
  value = helm_release.jenkins.name
}

output "jenkins_namespace" {
  value = helm_release.jenkins.namespace
}

output "jenkins_kaniko_role_arn" {
  description = "IAM role ARN, прив'язана до jenkins-sa через IRSA для пушу в ECR"
  value       = aws_iam_role.jenkins_kaniko_role.arn
}
