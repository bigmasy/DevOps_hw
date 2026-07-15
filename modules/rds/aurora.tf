resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name   = "${local.name}-cluster-pg"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(var.tags, { Name = "${local.name}-cluster-pg" })
}

resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = local.name
  engine             = local.aurora_engine
  engine_version     = var.engine_version

  database_name   = var.db_name
  master_username = var.username
  master_password = var.password
  port            = local.port

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  backup_retention_period   = var.backup_retention_period
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name}-final-snapshot"

  tags = merge(var.tags, { Name = local.name })
}

# count.index=0 — writer (перший instance в Aurora-кластері завжди writer,
# решта автоматично стають readers; окремого "writer=true" атрибута нема).
resource "aws_rds_cluster_instance" "this" {
  count = var.use_aurora ? var.aurora_instance_count : 0

  identifier         = "${local.name}-${count.index}"
  cluster_identifier = aws_rds_cluster.this[0].id
  engine             = local.aurora_engine
  engine_version     = var.engine_version
  instance_class     = var.instance_class

  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = var.publicly_accessible

  tags = merge(var.tags, { Name = "${local.name}-${count.index}" })
}
