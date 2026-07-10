variable "namespace" {
  description = "K8s namespace для Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Версія Helm-чарта Argo CD"
  type        = string
  default     = "5.46.4"
}

variable "app_name" {
  description = "Ім'я Argo CD Application для Django-застосунку"
  type        = string
  default     = "django-app"
}

variable "app_namespace" {
  description = "Namespace, куди Argo CD деплоїть Django-застосунок"
  type        = string
  default     = "django"
}

variable "app_chart_path" {
  description = "Шлях у infra-репозиторії до Helm-чарта застосунку"
  type        = string
  default     = "charts/django-app"
}

variable "infra_repo_url" {
  description = "URL infra-репозиторію, який відстежує Argo CD Application (те саме джерело, що клонує Jenkins seed-job)"
  type        = string
}

variable "infra_repo_branch" {
  description = "Гілка infra-репозиторію, яку відстежує Argo CD Application"
  type        = string
  default     = "main"
}

variable "github_username" {
  description = "GitHub username для доступу Argo CD до infra-репозиторію"
  type        = string
}

variable "github_pat" {
  description = "GitHub PAT для доступу Argo CD до infra-репозиторію"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django SECRET_KEY — кладеться у Kubernetes Secret django-app-secrets, не в git"
  type        = string
  sensitive   = true
}

variable "django_postgres_password" {
  description = "Postgres-пароль застосунку — кладеться у Kubernetes Secret django-app-secrets, не в git"
  type        = string
  sensitive   = true
}
