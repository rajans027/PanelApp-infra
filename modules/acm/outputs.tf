output "regional_cert" {
  description = "Regional Certificate ARN"
  value       = var.create_regional_cert ? aws_acm_certificate.regional_cert[0].arn : null
}

output "cloudfront_cert" {
  description = "Cloudfront Certificate ARN"
  value       = var.create_cloudfront_cert ? aws_acm_certificate.cloudfront_cert[0].arn : null
}
