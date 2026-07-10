output "argo_cd_namespace" {
  description = "Namespace, у якому розгорнутий Argo CD"
  value       = var.namespace
}

output "argo_cd_server_hint" {
  description = "Команда для отримання зовнішньої адреси Argo CD UI (LoadBalancer)"
  value       = "kubectl -n ${var.namespace} get svc -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'"
}

output "admin_password_hint" {
  description = "Команда для отримання початкового пароля admin"
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
