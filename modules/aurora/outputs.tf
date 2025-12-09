output "aurora_cluster" {
  value = {
    arn  = aws_rds_cluster.aurora_cluster.arn
    name = aws_rds_cluster.aurora_cluster.cluster_identifier
  }
}

output "aurora_cluster_parameter_groups" {
  value = {
    read-only = {
      name = aws_rds_cluster_parameter_group.read-only.name
      arn  = aws_rds_cluster_parameter_group.read-only.arn
    }
    read-write = {
      name = aws_rds_cluster_parameter_group.read-write.name
      arn  = aws_rds_cluster_parameter_group.read-write.arn
    }
  }
}

output "security_group" {
  value = aws_security_group.aurora.id
}

output "writer_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.aurora_cluster.reader_endpoint
}

output "port" {
  value = aws_rds_cluster.aurora_cluster.port
}

output "database_name" {
  value = aws_rds_cluster.aurora_cluster.database_name
}

output "database_user" {
  value = aws_rds_cluster.aurora_cluster.master_username
}

output "rds_shared_key" {
  value = local.rds_kms_key
}

output "rds_snapshot_ssm_parameter" {
  value = {
    name = aws_ssm_parameter.rds_snapshot.name
    arn  = aws_ssm_parameter.rds_snapshot.arn
  }
}
