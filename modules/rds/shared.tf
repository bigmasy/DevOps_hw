locals {
  name = var.identifier

  # Проста назва engine ("postgres"/"mysql") -> реальний Aurora engine.
  # Дозволяє викликачу завжди писати engine = "postgres", незалежно від
  # use_aurora, замість того щоб памʼятати назви aurora-postgresql/aurora-mysql.
  aurora_engine_map = {
    postgres = "aurora-postgresql"
    mysql    = "aurora-mysql"
  }
  aurora_engine = local.aurora_engine_map[var.engine]

  default_ports = {
    postgres = 5432
    mysql    = 3306
  }
  port = coalesce(var.port, local.default_ports[var.engine])
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${local.name}-subnet-group" })
}

resource "aws_security_group" "this" {
  name        = "${local.name}-sg"
  description = "Access to ${local.name} database"
  vpc_id      = var.vpc_id

  ingress {
    description = "DB access on ${local.port}"
    from_port   = local.port
    to_port     = local.port
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-sg" })
}
