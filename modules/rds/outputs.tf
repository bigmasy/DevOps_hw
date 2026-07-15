output "endpoint" {
  description = "Endpoint для підключення: writer endpoint для Aurora, address для звичайної RDS"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "reader_endpoint" {
  description = "Reader endpoint для Aurora (розподіляє читання між readers). null для звичайної RDS."
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "port" {
  description = "Порт БД (заданий явно або визначений автоматично за engine)"
  value       = local.port
}

output "identifier" {
  description = "Identifier створеного ресурсу: cluster_identifier для Aurora, identifier для звичайної RDS"
  value       = var.use_aurora ? aws_rds_cluster.this[0].cluster_identifier : aws_db_instance.this[0].identifier
}

output "arn" {
  description = "ARN створеного ресурсу (кластера або instance)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].arn : aws_db_instance.this[0].arn
}

output "security_group_id" {
  description = "ID security group, що охороняє БД — використовуйте для дозволу доступу з інших security groups (напр. EKS nodes)"
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "Імʼя DB Subnet Group"
  value       = aws_db_subnet_group.this.name
}
