locals {
  api_url_regex = "(/api|/health)"
}

resource "aws_wafv2_web_acl" "panelapp" {
  name  = "${var.name.ws_env_product}-alb"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "gel-internal-traffic"
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
      metric_name                = "${var.name.ws_env_product}-gel-internal-traffic"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "gel-external-traffic"
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
      metric_name                = "${var.name.ws_env_product}-gel-external-traffic"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "api-per-ip-limit"
    priority = 2
    action {
      dynamic "count" {
        for_each = var.waf_is_blocking ? [] : [1]
        content {}
      }
      dynamic "block" {
        for_each = var.waf_is_blocking ? [1] : []
        content {
          custom_response {
            response_code = 429
            response_header {
              name  = "Retry-After"
              value = "60"
            }
          }
        }
      }
    }
    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limits.api.per_ip
        evaluation_window_sec = 60
        aggregate_key_type    = "CUSTOM_KEYS"
        custom_key {
          header {
            name = "CF-Connecting-IP" # client's IP address when connecting via Cloudflare
            text_transformation {
              priority = 0
              type     = "COMPRESS_WHITE_SPACE"
            }
          }
        }
        scope_down_statement {
          regex_match_statement {
            regex_string = local.api_url_regex
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
      metric_name                = "${var.name.ws_env_product}-api-per-ip-limit"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "api-global-limit"
    priority = 3
    action {
      dynamic "count" {
        for_each = var.waf_is_blocking ? [] : [1]
        content {}
      }
      dynamic "block" {
        for_each = var.waf_is_blocking ? [1] : []
        content {
          custom_response {
            response_code = 429
            response_header {
              name  = "Retry-After"
              value = "60"
            }
          }
        }
      }
    }
    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limits.api.global
        evaluation_window_sec = 60
        aggregate_key_type    = "IP" # at this point, there is only one ip left, so this is actually global
        scope_down_statement {
          regex_match_statement {
            regex_string = local.api_url_regex
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
      metric_name                = "${var.name.ws_env_product}-api-global-limit"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "web-per-ip-limit"
    priority = 4
    action {
      dynamic "count" {
        for_each = var.waf_is_blocking ? [] : [1]
        content {}
      }
      dynamic "block" {
        for_each = var.waf_is_blocking ? [1] : []
        content {
          custom_response {
            response_code = 429
            response_header {
              name  = "Retry-After"
              value = "60"
            }
          }
        }
      }
    }
    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limits.web.per_ip
        evaluation_window_sec = 60
        aggregate_key_type    = "CUSTOM_KEYS"
        custom_key {
          header {
            name = "CF-Connecting-IP" # client's IP address when connecting via Cloudflare
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
                regex_string = local.api_url_regex
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
      metric_name                = "${var.name.ws_env_product}-web-per-ip-limit"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "web-global-limit"
    priority = 5
    action {
      dynamic "count" {
        for_each = var.waf_is_blocking ? [] : [1]
        content {}
      }
      dynamic "block" {
        for_each = var.waf_is_blocking ? [1] : []
        content {
          custom_response {
            response_code = 429
            response_header {
              name  = "Retry-After"
              value = "60"
            }
          }
        }
      }
    }
    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limits.web.global
        evaluation_window_sec = 60
        aggregate_key_type    = "IP" # at this point, there is only one ip left, so this is actually global
        scope_down_statement {
          not_statement {
            statement {
              regex_match_statement {
                regex_string = local.api_url_regex
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
      metric_name                = "${var.name.ws_env_product}-web-global-limit"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.name.ws_env_product}-waf"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "panelapp" {
  resource_arn = aws_lb.panelapp.arn
  web_acl_arn  = aws_wafv2_web_acl.panelapp.arn
}

resource "aws_wafv2_ip_set" "ngfw_ipv4" {
  name               = "${var.name.ws_product}-ngfw-ipset-v4"
  description        = "${var.name.ws_product}-ngfw-ipset-v4"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = [for x in data.aws_ec2_managed_prefix_list.ngfw.entries : x.cidr]
}

resource "aws_wafv2_ip_set" "fortigate_outbound" {
  name               = "${var.name.ws_product}-fortigate-outbound-ipset-v4"
  description        = "${var.name.ws_product}-fortigate-outbound-ipset-v4"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses = [
    "18.132.143.2/32",   # AWS
    "212.187.174.11/32", # Corsham
    "212.111.37.222/32", # Slough
  ]
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logs" {
  resource_arn            = aws_wafv2_web_acl.panelapp.arn
  log_destination_configs = [aws_s3_bucket.waf_logs.arn]
}

resource "aws_s3_bucket" "waf_logs" {
  # name prefix required by WAF
  bucket        = "aws-waf-logs-${var.name.bucket}"
  force_destroy = !local.is_default_ws
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "waf_logs" {
  # checkov:skip=CKV2_AWS_65: ACL required by CloudWatch
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

data "aws_iam_policy_document" "waf_logs" {
  statement {
    sid     = "WafLogsWrite"
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "delivery.logs.amazonaws.com",
      ]
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
    resources = [aws_s3_bucket.waf_logs.arn]
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
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.waf_logs.arn,
      "${aws_s3_bucket.waf_logs.arn}/*"
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

resource "aws_s3_bucket_policy" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  policy = data.aws_iam_policy_document.waf_logs.json
}
