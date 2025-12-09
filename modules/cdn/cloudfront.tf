locals {
  origin_id = "${var.name.ws_product}-cdn"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "cors_s3origin" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_response_headers_policy" "security" {
  for_each = toset(["basic", "static", "media"])
  name     = "${var.name.ws_product}-security-${each.value}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = each.key == "static" ? "SAMEORIGIN" : "DENY"
      override     = true
    }

    xss_protection {
      override   = true
      protection = true
      mode_block = true
    }
  }

  dynamic "cors_config" {
    for_each = toset(each.key == "static" ? [1] : [])
    content {
      access_control_allow_credentials = false
      access_control_allow_methods {
        items = [
          "GET",
          "HEAD",
          "OPTIONS",
        ]
      }
      access_control_allow_origins {
        items = concat(
          ["https://${var.dns.app.internal}.${var.dns.zone.internal}"],
          local.is_default_ws ? ["https://${var.dns.app.external}.${var.dns.zone.external}"] : []
        )
      }
      access_control_allow_headers {
        items = ["*"]
      }
      access_control_expose_headers {
        items = ["*"]
      }
      origin_override = true
    }
  }

  custom_headers_config {
    items {
      header   = "Cross-Origin-Embedder-Policy"
      value    = "require-corp"
      override = true
    }

    items {
      header   = "Cross-Origin-Opener-Policy"
      value    = "same-origin"
      override = true
    }

    items {
      header   = "Cross-Origin-Resource-Policy"
      value    = each.key == "basic" ? "same-origin" : "cross-origin"
      override = true
    }

    items {
      # Not an exhaustive list; see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy
      # for details. There is no simple way to disable all.
      header = "Permissions-Policy"
      value = join(", ", [
        "accelerometer=()",
        "camera=()",
        "fullscreen=()",
        "geolocation=()",
        "gyroscope=()",
        "magnetometer=()",
        "microphone=()",
        "payment=()",
        "sync-xhr=()",
        "usb=()"
      ])
      override = true
    }
  }

  remove_headers_config {
    items {
      header = "Server"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "panelapp" {
  name                              = local.origin_id
  description                       = "CDN Origin Access Control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "panelapp_media_distribution" {
  aliases = ["${var.dns.media.external}.${var.dns.zone.external}"]

  origin {
    domain_name = aws_s3_bucket.panelapp_media.bucket_regional_domain_name
    origin_path = ""
    origin_id   = "${local.origin_id}-media"

    origin_access_control_id = aws_cloudfront_origin_access_control.panelapp.id
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_acl.arn

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "media"
  }

  enabled = true

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "${local.origin_id}-media"
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security["media"].id
  }

  ordered_cache_behavior {
    path_pattern               = "/media/__canary__.txt"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "${local.origin_id}-media"
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security["basic"].id
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.certificate_arns.media
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    error_caching_min_ttl = 60
    response_page_path    = "/media/404.html"
  }
}

resource "aws_cloudfront_distribution" "panelapp_static_distribution" {
  aliases = ["${var.dns.static.external}.${var.dns.zone.external}"]

  origin {
    domain_name = aws_s3_bucket.panelapp_statics.bucket_regional_domain_name
    origin_path = ""
    origin_id   = "${local.origin_id}-static"

    origin_access_control_id = aws_cloudfront_origin_access_control.panelapp.id
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_acl.arn

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "statics"
  }

  enabled = true

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "${local.origin_id}-static"
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3origin.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security["static"].id
  }

  ordered_cache_behavior {
    path_pattern               = "/static/__canary__.txt"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "${local.origin_id}-static"
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security["basic"].id
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.certificate_arns.statics
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    error_caching_min_ttl = 60
    response_page_path    = "/static/404.html"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "static_panelapp_cdn"
  }
}

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = "${var.name.bucket}-cloudfront-logs"
  force_destroy = !local.is_default_ws

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  # checkov:skip=CKV2_AWS_65: ACL required by CloudWatch
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "log-delivery-write"
  depends_on = [
    aws_s3_bucket_ownership_controls.cloudfront_logs,
    aws_s3_bucket_public_access_block.cloudfront_logs,
  ]
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    id     = "expiration"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      days = 365
    }
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
  rule {
    id     = "delete-marker"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      expired_object_delete_marker = true
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  policy = data.aws_iam_policy_document.cloudfront_logs.json
}

data "aws_iam_policy_document" "cloudfront_logs" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.cloudfront_logs.arn,
      "${aws_s3_bucket.cloudfront_logs.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}
