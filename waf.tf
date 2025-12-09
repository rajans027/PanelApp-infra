
############################################
# WAF Web ACL
############################################

resource "aws_wafv2_web_acl" "panelapp" {
  name  = "${var.project_name}-${var.env_name}-alb"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  ############################################
  # RULE 0 — Internal Traffic (Allow)
  ############################################
  rule {
    name     = "internal-traffic"
    priority = 0

    action {
      allow {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.ngfw_ipv4.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.env_name}-internal-traffic"
      sampled_requests_enabled   = false
    }
  }

  ############################################
  # RULE 1 — External Traffic (Allow only Fortigate IPs)
  ############################################
  rule {
    name     = "external-traffic"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.fortigate_outbound.arn
        ip_set_forwarded_ip_config {
          fallback_behavior = "NO_MATCH"
          header_name       = "CF-Connecting-IP"
          position          = "ANY"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.env_name}-external-traffic"
      sampled_requests_enabled   = false
    }
  }

  ############################################
  # RULE 2 — API Per-IP Rate Limit
  ############################################
  rule {
    name     = "api-per-ip-limit"
    priority = 2

    action {
      count = var.waf_is_blocking ? null : {}
      block = var.waf_is_blocking ? {
        custom_response {
          response_code = 429
          response_header {
            name  = "Retry-After"
            value = "60"
          }
        }
      } : null
    }

    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limits.api.per_ip
        evaluation_window_sec = 60
        aggregate_key_type    = "CUSTOM_KEYS"

        custom_key {
          header {
            name = "CF-Connecting-IP"
            text_transformation {
              priority = 0
              type     = "COMPRESS_WHITE_SPACE"
            }
          }
        }

        scope_down_statement {
          regex_match_statement {
            regex_string = var.api_url_regex

            field_to_match {
              uri_path {}
            }

            text_transformation {
              priority = 0
              type     = "NORMALIZE_PATH"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.env_name}-api-per-ip-limit"
      sampled_requests_enabled   = false
    }
  }

  ############################################
  # RULE 3 — API Global Rate Limit
  ############################################
  rule {
    name     = "api-global-limit"
    priority = 3

    action {
      count = var.waf_is_blocking ? null : {}
      block = var.waf_is_blocking ? {
        custom_response {
          response_code = 429
          response_header {
            name  = "Retry-After"
            value = "60"
          }
        }
      } : null
    }

    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limits.api.global
        evaluation_window_sec = 60
        aggregate_key_type    = "IP"

        scope_down_statement {
          regex_match_statement {
            regex_string = var.api_url_regex

            field_to_match {
              uri_path {}
            }

            text_transformation {
              priority = 0
              type     = "NORMALIZE_PATH"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.env_name}-api-global-limit"
      sampled_requests_enabled   = false
    }
  }

  ############################################
  # RULE 4 — Website Per-IP Rate Limit (Non-API)
  ############################################
  rule {
    name     = "web-per-ip-limit"
    priority = 4

    action {
      count = var.waf_is_blocking ? null : {}
      block = var.waf_is_blocking ? {
        custom_response {
          response_code = 429
          response_header {
            name  = "Retry-After"
            value = "60"
          }
        }
      } : null
    }

    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limits.web.per_ip
        evaluation_window_sec = 60
        aggregate_key_type    = "CUSTOM_KEYS"

        custom_key {
          header {
            name = "CF-Connecting-IP"
            text_transformation {
              priority = 0
              type     = "COMPRESS_WHITE_SPACE"
            }
          }
        }

        scope_down_statement {
          not_statement {
            statement {
              regex_match_statement {
                regex_string = var.api_url_regex

                field_to_match {
                  uri_path {}
                }

                text_transformation {
                  priority = 0
                  type     = "NORMALIZE_PATH"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.env_name}-web-per-ip-limit"
      sampled_requests_enabled   = false
    }
  }

  ############################################
  # RULE 5 — Web Global Limit (Non-API)
  ############################################
  rule {
    name     = "web-global-limit"
    priority = 5

    action {
      count = var.waf_is_blocking ? null : {}
      block = var.waf_is_blocking ? {
        custom_response {
          response_code = 429
          response_header {
            name  = "Retry-After"
            value = "60"
          }
        }
      } : null
    }

    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limits.web.global
        evaluation_window_sec = 60
        aggregate_key_type    = "IP"

        scope_down_statement {
          not_statement {
            statement {
              regex_match_statement {
                regex_string = var.api_url_regex

                field_to_match {
                  uri_path {}
                }

                text_transformation {
                  priority = 0
                  type     = "NORMALIZE_PATH"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.env_name}-web-global-limit"
      sampled_requests_enabled   = false
    }
  }

  ############################################
  # Web ACL Visibility
  ############################################
  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.project_name}-${var.env_name}-waf"
    sampled_requests_enabled   = false
  }
}

############################################
# WAF Association with ALB
############################################

resource "aws_wafv2_web_acl_association" "panelapp" {
  resource_arn = aws_lb.panelapp.arn
  web_acl_arn  = aws_wafv2_web_acl.panelapp.arn
}

############################################
# IP Sets
############################################

resource "aws_wafv2_ip_set" "ngfw_ipv4" {
  name               = "${var.project_name}-${var.env_name}-ngfw-ipset-v4"
  description        = "NGFW allowed IPv4 ranges"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = [for x in data.aws_ec2_managed_prefix_list.ngfw.entries : x.cidr]
}

resource "aws_wafv2_ip_set" "fortigate_outbound" {
  name               = "${var.project_name}-${var.env_name}-fortigate-ipset-v4"
  description        = "Fortigate outbound IPv4 ranges"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses = [
    "18.132.143.2/32",
    "212.187.174.11/32",
    "212.111.37.222/32"
  ]
}

############################################
# WAF Logging Bucket
############################################

resource "aws_s3_bucket" "waf_logs" {
  bucket        = "aws-waf-logs-${var.bucket_name}"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "expiration"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
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

############################################
# Bucket Policy
############################################

data "aws_iam_policy_document" "waf_logs" {
  statement {
    sid     = "WafLogsWrite"
    actions = ["s3:PutObject"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    resources = [
      "${aws_s3_bucket.waf_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/WAFLogs/*"
    ]
  }

  statement {
    sid     = "WafLogsRead"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    resources = [
      aws_s3_bucket.waf_logs.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:us-east-2:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.waf_logs.arn,
      "${aws_s3_bucket.waf_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  policy = data.aws_iam_policy_document.waf_logs.json
}
