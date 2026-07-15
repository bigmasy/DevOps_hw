# modules/rds

Універсальний Terraform-модуль для бази даних в AWS: одним прапорцем
(`use_aurora`) перемикається між звичайною **RDS instance** і **Aurora
Cluster**, з однаковим інтерфейсом змінних для обох випадків.

## Що створює

Незалежно від `use_aurora`:
- `aws_db_subnet_group` — підмережі, у яких може жити БД
- `aws_security_group` — доступ на порт БД, обмежений `ingress_cidr_blocks`
- Parameter Group з базовими параметрами (`max_connections`, `log_statement`,
  `work_mem` за замовчуванням — налаштовується через `db_parameters`)

Далі — залежно від `use_aurora`:

| `use_aurora = false` (default) | `use_aurora = true` |
|---|---|
| `aws_db_parameter_group` | `aws_rds_cluster_parameter_group` |
| `aws_db_instance` (одна instance) | `aws_rds_cluster` + `aws_rds_cluster_instance` × `aurora_instance_count` (перша — writer, решта — readers) |

## Приклад використання

### Звичайна RDS (PostgreSQL)

```hcl
module "rds" {
  source = "./modules/rds"

  identifier             = "myapp-db"
  use_aurora             = false
  engine                 = "postgres"
  engine_version         = "15.17"
  parameter_group_family = "postgres15"
  instance_class         = "db.t3.micro"
  multi_az               = false

  db_name  = "myapp"
  username = "myapp_admin"
  password = var.db_password        # TF_VAR_db_password з .env, не хардкодити

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  ingress_cidr_blocks = ["10.0.0.0/16"]  # доступ лише з середини VPC
}
```

### Aurora Cluster (PostgreSQL-сумісний, writer + reader)

```hcl
module "rds" {
  source = "./modules/rds"

  identifier             = "myapp-aurora"
  use_aurora             = true
  engine                 = "postgres"          # той самий "postgres" — модуль сам
  engine_version         = "15.17"     # підставить aurora-postgresql
  parameter_group_family = "aurora-postgresql15"
  instance_class         = "db.r6g.large"
  aurora_instance_count  = 2                    # 1 writer + 1 reader

  db_name  = "myapp"
  username = "myapp_admin"
  password = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  ingress_cidr_blocks = ["10.0.0.0/16"]
}
```

### MySQL замість PostgreSQL

`engine = "mysql"` перемикає і звичайну RDS (`mysql`), і Aurora
(`aurora-mysql`) — але **обовʼязково перевизначте `db_parameters`**, бо
дефолтні `work_mem`/`log_statement` існують лише в PostgreSQL:

```hcl
module "rds" {
  source = "./modules/rds"

  identifier             = "myapp-mysql"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  parameter_group_family = "mysql8.0"

  db_parameters = [
    { name = "max_connections", value = "150" },
    { name = "general_log", value = "1" },
    { name = "sort_buffer_size", value = "262144" },
  ]

  db_name  = "myapp"
  username = "myapp_admin"
  password = var.db_password
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}
```

## Як змінити тип БД / engine / клас інстансу

- **RDS ↔ Aurora**: один прапорець `use_aurora`. Все інше (subnet group,
  security group, parameter group) модуль перебудовує сам — жодних інших
  змін не потрібно.
- **PostgreSQL ↔ MySQL**: `engine = "postgres"` або `"mysql"` — завжди без
  префіксу `aurora-`, модуль сам підставляє правильний рядок для Aurora.
  При зміні engine обовʼязково оновіть і `parameter_group_family` (він
  привʼязаний до конкретного engine+version), і, якщо потрібно, `db_parameters`.
- **Клас інстансу**: `instance_class` — застосовується і до звичайної RDS,
  і до кожного `aws_rds_cluster_instance` в Aurora.
- **Кількість Aurora-нод**: `aurora_instance_count` (1 = лише writer).
- **Multi-AZ**: `multi_az` стосується лише звичайної RDS. Aurora є
  розподіленою на рівні сховища за замовчуванням; висока доступність там
  керується кількістю instances (`aurora_instance_count`), не цим прапорцем.

## Змінні

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `identifier` | `string` | — | Базове імʼя для всіх ресурсів модуля |
| `use_aurora` | `bool` | `false` | `true` — Aurora Cluster, `false` — звичайна RDS instance |
| `engine` | `string` | `"postgres"` | `"postgres"` або `"mysql"` (валідується) |
| `engine_version` | `string` | — | Версія engine (напр. `"15.17"`) |
| `parameter_group_family` | `string` | — | Family для Parameter Group, залежить від engine+version і від use_aurora |
| `instance_class` | `string` | `"db.t3.micro"` | Клас інстансу (RDS instance або кожної Aurora-instance) |
| `multi_az` | `bool` | `false` | Multi-AZ для звичайної RDS. Не стосується Aurora |
| `aurora_instance_count` | `number` | `1` | Кількість instances в Aurora-кластері. Ігнорується при `use_aurora = false` |
| `allocated_storage` | `number` | `20` | Розмір диска в GiB. Лише для звичайної RDS |
| `storage_type` | `string` | `"gp3"` | Тип диска. Лише для звичайної RDS |
| `db_name` | `string` | — | Назва бази даних при створенні |
| `username` | `string` | — | Master username |
| `password` | `string` | — | Master password. Без дефолту, `sensitive = true` — передавайте через `TF_VAR_` з `.env` |
| `port` | `number` | `null` | Порт БД. `null` → автоматично: 5432 (postgres) / 3306 (mysql) |
| `vpc_id` | `string` | — | VPC для security group і subnet group |
| `subnet_ids` | `list(string)` | — | Підмережі для DB Subnet Group (мінімум 2, різні AZ) |
| `ingress_cidr_blocks` | `list(string)` | `[]` | CIDR-блоки з доступом до БД. Порожньо = доступу нема, поки не додати явно |
| `db_parameters` | `list(object({name, value, apply_method}))` | базові PostgreSQL-параметри | Параметри Parameter Group. `apply_method` за замовчуванням `"immediate"`; для статичних параметрів (напр. `max_connections`) AWS вимагає `"pending-reboot"` |
| `backup_retention_period` | `number` | `0` | Днів зберігання бекапів. `0` — вимкнено (деякі Free Tier акаунти відхиляють ненульовий retention) |
| `skip_final_snapshot` | `bool` | `true` | `true` зручно для dev/test; `false` — рекомендовано для прод |
| `publicly_accessible` | `bool` | `false` | Публічна IP-адреса |
| `tags` | `map(string)` | `{}` | Додаткові теги |

## Outputs

| Output | Опис |
|---|---|
| `endpoint` | Endpoint для підключення (writer endpoint для Aurora, address для RDS) |
| `reader_endpoint` | Reader endpoint (лише Aurora, інакше `null`) |
| `port` | Порт БД |
| `identifier` | Identifier створеного ресурсу |
| `arn` | ARN створеного ресурсу |
| `security_group_id` | Для дозволу доступу з інших security groups (напр. EKS nodes) |
| `db_subnet_group_name` | Імʼя DB Subnet Group |

## Підключення в цьому репозиторії

Модуль вже підключений у корені (`main.tf`) через `module "rds"`, але
**вимкнений за замовчуванням** (`enable_rds = false`) — RDS/Aurora суттєво
дорожчі за решту стеку (Jenkins/Argo CD/EKS), і не кожен `terraform apply`
цього репозиторію має їх створювати.

Щоб увімкнути:
```bash
# у .env
TF_VAR_enable_rds=true
TF_VAR_rds_use_aurora=false   # або true для Aurora
TF_VAR_rds_password=<реальний пароль>
```
```bash
set -a && source .env && set +a
terraform apply
```

Решта `rds_*` змінних кореня (`rds_engine`, `rds_instance_class` тощо) мають
дефолти в корені (`variables.tf`) — перевизначайте за потреби так само через
`.env`.
