output "buckets" {
  value = {
    statics = {
      name = aws_s3_bucket.panelapp_statics.id
      arn  = aws_s3_bucket.panelapp_statics.arn
    }
    media = {
      name = aws_s3_bucket.panelapp_media.id
      arn  = aws_s3_bucket.panelapp_media.arn
    }
    logs = {
      name = aws_s3_bucket.cloudfront_logs.id
      arn  = aws_s3_bucket.cloudfront_logs.arn
    }
  }
}

output "distribution" {
  value = {
    static = aws_cloudfront_distribution.panelapp_static_distribution.arn
    media  = aws_cloudfront_distribution.panelapp_media_distribution.arn
  }
}
