variable "namespace" {
  description = "K8s namespace для Prometheus і Grafana"
  type        = string
  default     = "monitoring"
}

variable "grafana_admin_username" {
  description = "Логін адміністратора Grafana"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Пароль адміністратора Grafana"
  type        = string
  sensitive   = true
}

variable "prometheus_chart_version" {
  description = "Версія Helm-чарта prometheus-community/prometheus"
  type        = string
  default     = "29.17.0"
}

variable "grafana_chart_version" {
  description = "Версія Helm-чарта grafana/grafana"
  type        = string
  default     = "10.5.15"
}

variable "metrics_server_chart_version" {
  description = "Версія Helm-чарта metrics-server/metrics-server — потрібен, щоб HPA (charts/django-app/templates/hpa.yaml) бачив реальний CPU utilization замість <unknown>"
  type        = string
  default     = "3.13.1"
}
