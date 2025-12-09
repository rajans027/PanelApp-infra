locals {
  cluster_identifier = local.is_default_ws ? "aurora-${var.env_name}" : "aurora-${var.name.ws_env_product}"
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier              = local.cluster_identifier
  engine                          = "aurora-postgresql"
  engine_version                  = var.engine_version
  final_snapshot_identifier       = "aurora-${var.name.ws_env_product}"
  skip_final_snapshot             = var.skip_final_snapshot
  storage_encrypted               = true
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.read-write.name
  kms_key_id                      = local.rds_kms_key
  vpc_security_group_ids          = [aws_security_group.aurora.id]
  apply_immediately               = true
  preferred_maintenance_window    = var.preferred_maintenance_window

  database_name           = var.database
  master_username         = var.username
  backup_retention_period = 1

  master_password     = var.master_password
  snapshot_identifier = var.rds_snapshot # might be ""

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(
    {
      Name        = var.name.ws_env_product
      Application = "Postgres"
    },
    var.extra_tags,
  )

  depends_on = [aws_cloudwatch_log_group.rds]

  lifecycle {
    ignore_changes = [
      db_cluster_parameter_group_name
    ]
  }
}

resource "aws_rds_cluster_instance" "aurora_cluster_instance" {
  count = var.cluster_size

  engine                       = "aurora-postgresql"
  engine_version               = var.engine_version
  identifier                   = local.is_default_ws ? "${var.env_name}-db${count.index + 1}" : "${var.name.ws_env_product}-db${count.index + 1}"
  cluster_identifier           = aws_rds_cluster.aurora_cluster.id
  instance_class               = var.instance_class
  db_subnet_group_name         = aws_db_subnet_group.aurora.name
  publicly_accessible          = false
  promotion_tier               = "0"
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  ca_cert_identifier           = "rds-ca-rsa2048-g1"
  apply_immediately            = true
  preferred_maintenance_window = var.preferred_maintenance_window
  performance_insights_enabled = true

  tags = merge(
    {
      Name        = "${var.name.ws_env_product}-db${count.index + 1}"
      Application = "Postgres"
    },
    var.extra_tags,
  )
}

resource "aws_rds_cluster_parameter_group" "read-write" {
  name        = "${var.name.ws_product}-read-write"
  family      = var.cluster_parameter_group_family
  description = "Read-write mode"
  parameter {
    name         = "default_transaction_read_only"
    value        = "0"
    apply_method = "immediate"
  }
}

resource "aws_rds_cluster_parameter_group" "read-only" {
  name        = "${var.name.ws_product}-read-only"
  family      = var.cluster_parameter_group_family
  description = "Read-only mode"
  parameter {
    name         = "default_transaction_read_only"
    value        = "1"
    apply_method = "immediate"
  }
}

resource "aws_db_subnet_group" "aurora" {
  name       = local.is_default_ws ? "aurora-subnet-group-${var.env_name}" : "aurora-${var.name.ws_env_product}"
  subnet_ids = [for x in data.aws_subnet.private : x.id]
  tags = {
    Name = "aurora-${var.name.ws_env_product}"
  }
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/cluster/${local.cluster_identifier}/postgresql"
  retention_in_days = local.log_retention
}
