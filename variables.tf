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

variable "ecr_image_tag" {
  description = "Тег Docker-образу, який пушить pipeline"
  type        = string
  default     = "latest"
}

variable "app_chart_path" {
  description = "Шлях у infra-репозиторії до Helm-чарта застосунку — Jenkins оновлює тут image.tag, Argo CD звідси деплоїть"
  type        = string
  default     = "charts/django-app"
}

variable "app_namespace" {
  description = "Namespace, куди Argo CD деплоїть Django-застосунок і куди Terraform кладе Secret з реальними кредами"
  type        = string
  default     = "django"
}

variable "django_secret_key" {
  description = "Django SECRET_KEY (settings.py читає без префіксу DJANGO_) — кладеться у Kubernetes Secret, не в git"
  type        = string
  sensitive   = true
}

variable "django_postgres_password" {
  description = "Postgres-пароль застосунку (settings.py читає POSTGRES_PASSWORD без префіксу) — кладеться у Kubernetes Secret, не в git"
  type        = string
  sensitive   = true
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

# --- modules/rds (модуль вимкнений за замовчуванням: RDS/Aurora коштує
# суттєво більше за решту стеку, і не всі applies цього репозиторію мають
# його піднімати — тільки коли явно enable_rds = true) ---

variable "enable_rds" {
  description = "Підняти module.rds (RDS instance або Aurora cluster, залежно від rds_use_aurora). За замовчуванням false, щоб не створювати платну БД на кожному apply."
  type        = bool
  default     = false
}

variable "rds_use_aurora" {
  description = "true — Aurora Cluster, false — звичайна RDS instance"
  type        = bool
  default     = false
}

variable "rds_engine" {
  description = "\"postgres\" або \"mysql\""
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Версія engine (напр. \"15.17\" для postgres) — має існувати і в RDS, і в Aurora (aws rds describe-db-engine-versions --engine postgres|aurora-postgresql --query 'DBEngineVersions[].EngineVersion'), інакше перемикання rds_use_aurora зламається"
  type        = string
  default     = "15.17"
}

variable "rds_parameter_group_family" {
  description = "Family для Parameter Group — залежить від rds_engine + rds_engine_version і від rds_use_aurora (напр. \"postgres15\" для RDS, \"aurora-postgresql15\" для Aurora)"
  type        = string
  default     = "postgres15"
}

variable "rds_instance_class" {
  description = "Клас інстансу RDS/Aurora"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_multi_az" {
  description = "Multi-AZ для звичайної RDS instance (ігнорується для Aurora)"
  type        = bool
  default     = false
}

variable "rds_aurora_instance_count" {
  description = "Кількість instances в Aurora-кластері (враховується лише при rds_use_aurora = true)"
  type        = number
  default     = 1
}

variable "rds_db_name" {
  description = "Назва бази даних"
  type        = string
  default     = "appdb"
}

variable "rds_username" {
  description = "Master username БД"
  type        = string
  default     = "appuser"
}

variable "rds_password" {
  description = "Master password БД — без дефолту, обовʼязково через TF_VAR_rds_password з .env"
  type        = string
  sensitive   = true
  default     = ""
}
