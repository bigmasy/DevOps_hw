variable "identifier" {
  description = "Базове імʼя для всіх ресурсів модуля (RDS instance / Aurora cluster, subnet group, security group, parameter group)"
  type        = string
}

variable "use_aurora" {
  description = "true — створити Aurora Cluster (+ writer instance); false — створити звичайну RDS instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Тип БД: \"postgres\" або \"mysql\". Для Aurora модуль сам підставляє відповідний aurora-* engine (aurora-postgresql / aurora-mysql) — вказувати aurora-* вручну не треба."
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "engine має бути \"postgres\" або \"mysql\"."
  }
}

variable "engine_version" {
  description = "Версія engine (напр. \"15.17\" для postgres, \"8.0.35\" для mysql). Має існувати і в RDS, і в Aurora, якщо плануєте перемикати use_aurora без зміни версії."
  type        = string
}

variable "parameter_group_family" {
  description = "Family для Parameter Group, залежить від engine+engine_version (напр. \"postgres15\" для звичайної RDS, \"aurora-postgresql15\" для Aurora). Дізнатись точне значення: aws rds describe-db-engine-versions --engine <engine> --query 'DBEngineVersions[].DBParameterGroupFamily'"
  type        = string
}

variable "instance_class" {
  description = "Клас інстансу (напр. \"db.t3.micro\" для RDS, \"db.r6g.large\" для Aurora)"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Multi-AZ для звичайної RDS instance. Не стосується Aurora — там за високу доступність відповідає кількість instances в кластері (aurora_instance_count)."
  type        = bool
  default     = false
}

variable "aurora_instance_count" {
  description = "Кількість instances в Aurora-кластері (перший — завжди writer, решта — readers). Враховується лише при use_aurora = true."
  type        = number
  default     = 1
}

variable "allocated_storage" {
  description = "Розмір диска в GiB. Стосується лише звичайної RDS — Aurora масштабує сховище автоматично і цей параметр ігнорує."
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Тип диска для звичайної RDS (gp3 / gp2 / io1). Не стосується Aurora."
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Назва бази даних, яка створюється одразу при старті"
  type        = string
}

variable "username" {
  description = "Master username бази даних"
  type        = string
}

variable "password" {
  description = "Master password бази даних. Без дефолту навмисно — передавайте через TF_VAR_ з .env, не хардкодьте в .tfvars"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Порт БД. Якщо не задано (null) — визначається автоматично за engine: 5432 для postgres, 3306 для mysql."
  type        = number
  default     = null
}

variable "vpc_id" {
  description = "VPC, у якому створюються security group і db subnet group"
  type        = string
}

variable "subnet_ids" {
  description = "Підмережі для DB Subnet Group — потрібно мінімум 2, у різних availability zones"
  type        = list(string)
}

variable "ingress_cidr_blocks" {
  description = "CIDR-блоки, яким дозволено підключатись до БД на її порту. За замовчуванням порожній список — доступу ззовні нема, поки явно не додати."
  type        = list(string)
  default     = []
}

variable "db_parameters" {
  description = "Параметри Parameter Group (DB Parameter Group для RDS / Cluster Parameter Group для Aurora). Дефолт — базові PostgreSQL-параметри; для MySQL передайте власний список, бо work_mem/log_statement у MySQL не існують (аналоги: sort_buffer_size, general_log). apply_method за замовчуванням \"immediate\" — для статичних параметрів (напр. max_connections) AWS вимагає \"pending-reboot\"."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = [
    { name = "max_connections", value = "100", apply_method = "pending-reboot" },
    { name = "log_statement", value = "all" },
    { name = "work_mem", value = "4096" },
  ]
}

variable "backup_retention_period" {
  description = "Скільки днів зберігати автоматичні бекапи. Дефолт 0 (бекапи вимкнені) — деякі AWS Free Tier акаунти відхиляють CreateDBInstance при ненульовому retention (FreeTierRestrictionError)."
  type        = number
  default     = 0
}

variable "skip_final_snapshot" {
  description = "true — не робити фінальний snapshot при видаленні (зручно для dev/test і для terraform destroy без зайвих запитань). false — рекомендовано для прод."
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Чи давати БД публічну IP-адресу"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Додаткові теги для всіх ресурсів модуля"
  type        = map(string)
  default     = {}
}
