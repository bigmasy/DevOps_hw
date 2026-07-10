variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN OIDC-провайдера EKS-кластера (для IRSA)"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL OIDC-провайдера EKS-кластера (для IRSA)"
  type        = string
}

variable "jenkins_admin_username" {
  description = "Логін адміністратора Jenkins"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Пароль адміністратора Jenkins"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub username, що використовується Jenkins для credentials"
  type        = string
}

variable "github_pat" {
  description = "GitHub Personal Access Token для доступу Jenkins до репозиторію"
  type        = string
  sensitive   = true
}

variable "infra_repo_url" {
  description = "URL infra-репозиторію (цей репозиторій), який клонує сам job('seed-job')"
  type        = string
}

variable "infra_repo_branch" {
  description = "Гілка infra-репозиторію, яку відстежує seed-job"
  type        = string
  default     = "main"
}

variable "django_repo_url" {
  description = "URL репозиторію django-app-ci з Jenkinsfile — саме його клонує pipeline goit-django-docker"
  type        = string
}

variable "django_repo_branch" {
  description = "Гілка django-app-ci репозиторію, яку відстежує pipeline goit-django-docker"
  type        = string
  default     = "main"
}

variable "jenkins_url" {
  description = "Публічний URL Jenkins (LoadBalancer). Порожній рядок — пропустити налаштування location.url; заповнюється після першого apply, коли відомий hostname LB"
  type        = string
  default     = ""
}

variable "ecr_registry" {
  description = "Адреса ECR-реєстру (destination для Kaniko)"
  type        = string
}

variable "ecr_image_name" {
  description = "Назва Docker-образу в ECR"
  type        = string
}

variable "ecr_image_tag" {
  description = "Тег Docker-образу, який пушить pipeline"
  type        = string
  default     = "latest"
}

variable "app_chart_path" {
  description = "Шлях у infra-репозиторії до Helm-чарта застосунку (там pipeline оновлює image.tag)"
  type        = string
  default     = "charts/django-app"
}

variable "git_commit_email" {
  description = "Email автора автоматичних комітів Jenkins (оновлення тегу в Git)"
  type        = string
  default     = "jenkins@localhost"
}

variable "git_commit_name" {
  description = "Ім'я автора автоматичних комітів Jenkins (оновлення тегу в Git)"
  type        = string
  default     = "jenkins-ci"
}
