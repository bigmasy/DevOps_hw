output "monitoring_namespace" {
  description = "Namespace, у якому розгорнуті Prometheus і Grafana"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_access_hint" {
  description = "Команда для доступу до Grafana UI через port-forward"
  value       = "kubectl port-forward svc/grafana 3000:80 -n ${var.namespace}"
}

output "prometheus_access_hint" {
  description = "Команда для доступу до Prometheus UI (Targets/Graph) через port-forward"
  value       = "kubectl port-forward svc/prometheus-server 9090:80 -n ${var.namespace}"
}
