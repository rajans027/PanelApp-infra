###############################################
# AURORA NAMING WITH ENVIRONMENT PREFIX
###############################################

# Consistent prefix for every object
locals {
  aurora_prefix = "${var.project_name}-${var.env_name}-aurora"
}

###############################################
# PASSWORD HANDLING
###############################################

resource "aws_ssm_parameter" "aurora_master_password" {
  name        = "/${var.project_name}/${var.env_name}/database/master_password"
  description = "Master password for Aurora PostgreSQL"
  type        = "SecureString"
  key_id      = var.kms_key_arn
  value       = "change_me"

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "aurora_master_password" {
  name = aws_ssm_parameter.aurora_master_password.name
}

###############################################
# DB SUBNET GROUP
###############################################

resource "aws_db_subnet_group" "aurora" {
  name       = "${local.aurora_prefix}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.aurora_prefix}-subnet-group"
  }
}

###############################################
# SECURITY GROUP
###############################################

resource "aws_security_group" "aurora" {
  name        = "${local.aurora_prefix}-sg"
  description = "Aurora security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.aurora_prefix}-sg"
  }
}

# Allow Fargate → Aurora
resource "aws_security_group_rule" "aurora_ingress_fargate" {
  description              = "Allow Fargate ECS tasks to connect to Aurora"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora.id
  source_security_group_id = var.fargate_security_group_id
}

###############################################
# PARAMETER GROUPS
###############################################

resource "aws_rds_cluster_parameter_group" "read_write" {
  name        = "${local.aurora_prefix}-read-write"
  family      = "aurora-postgresql14"
  description = "RW parameter group"

  parameter {
    name         = "default_transaction_read_only"
    value        = "0"
    apply_method = "immediate"
  }
}

resource "aws_rds_cluster_parameter_group" "read_only" {
  name        = "${local.aurora_prefix}-read-only"
  family      = "aurora-postgresql14"
  description = "RO parameter group"

  parameter {
    name         = "default_transaction_read_only"
    value        = "1"
    apply_method = "immediate"
  }
}

###############################################
# RDS CLUSTER (WRITER)
###############################################

resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = local.aurora_prefix
  engine                          = "aurora-postgresql"
  engine_version                  = var.aurora.engine_version
  database_name                   = "panelapp"
  master_username                 = "panelapp"
  master_password                 = data.aws_ssm_parameter.aurora_master_password.value
  backup_retention_period         = 1
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_arn
  skip_final_snapshot             = var.skip_final_snapshot
  snapshot_identifier             = var.snapshot_identifier
  apply_immediately               = true
  preferred_maintenance_window    = var.preferred_maintenance_window
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.read_write.name
  vpc_security_group_ids          = [aws_security_group.aurora.id]

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name        = local.aurora_prefix
    Application = "Postgres"
    Environment = var.env_name
  }
}

###############################################
# RDS CLUSTER INSTANCES (WRITER + READERS)
###############################################

resource "aws_rds_cluster_instance" "aurora_instances" {
  count = var.aurora.cluster_size

  identifier                   = "${local.aurora_prefix}-db${count.index + 1}"
  cluster_identifier           = aws_rds_cluster.aurora.id
  instance_class               = var.aurora.instance_class
  engine                       = "aurora-postgresql"
  engine_version               = var.aurora.engine_version
  db_subnet_group_name         = aws_db_subnet_group.aurora.name
  publicly_accessible          = false
  auto_minor_version_upgrade   = var.aurora.auto_minor_version_upgrade
  apply_immediately            = true
  performance_insights_enabled = true
  promotion_tier               = count.index == 0 ? 0 : 15

  tags = {
    Name        = "${local.aurora_prefix}-db${count.index + 1}"
    Application = "Postgres"
    Environment = var.env_name
  }
}

###############################################
# LOG GROUP
###############################################

resource "aws_cloudwatch_log_group" "aurora" {
  name              = "/aws/rds/cluster/${local.aurora_prefix}/postgresql"
  retention_in_days = 30
}
