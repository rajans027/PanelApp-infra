output "buckets" {
  description = "input/output S3 buckets"
  value = {
    upload = {
      name = aws_s3_bucket.upload.id
      arn  = aws_s3_bucket.upload.arn
    }
    artifacts = {
      name = aws_s3_bucket.artifacts.id
      arn  = aws_s3_bucket.artifacts.arn
    }
  }
}

output "ssm_documents" {
  value = {
    change_banner       = aws_ssm_document.banner
    maintenance_mode    = aws_ssm_document.maintenance_mode
    standalone_tasks    = aws_ssm_document.run_standalone_tasks
    ensembl_id_update   = aws_ssm_document.ensembl_id_update
    restart_services    = aws_ssm_document.restart_services
    rds_create_snapshot = aws_ssm_document.rds_create_snapshot
    athena_ddl          = aws_ssm_document.athena_ddl
  }
}

output "kms_keys" {
  value = {
    automation = {
      key_arn   = aws_kms_key.automation.arn
      alias_arn = aws_kms_alias.automation.arn
    }
  }
}
