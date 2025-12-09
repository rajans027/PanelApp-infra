resource "aws_athena_workgroup" "alb" {
  name          = var.name.ws_product
  description   = "Workgroup for ${var.name.ws_env_product}"
  force_destroy = true
  configuration {
    publish_cloudwatch_metrics_enabled = false
    bytes_scanned_cutoff_per_query     = 1024 * 1024 * 1024 # 1GB

    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_results.id}/"
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
