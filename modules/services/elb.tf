locals {
  elb_security_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

resource "aws_lb" "panelapp" {
  # checkov:skip=CKV_AWS_150: false positive (missing ELB deletion protection)
  name                       = "${var.name.ws_product}-elb"
  internal                   = true
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  enable_deletion_protection = local.is_default_ws

  security_groups = [aws_security_group.alb.id]
  subnets         = [for x in data.aws_subnet.private : x.id]

  access_logs {
    bucket  = aws_s3_bucket.logs.id
    enabled = true
  }

  tags = {
    Name = "${var.name.ws_product}-elb"
  }

  depends_on = [aws_s3_bucket_policy.logs]
}

resource "aws_lb_target_group" "panelapp_app_web" {
  # FIXME: Phase 2 (downtime)
  name        = local.is_default_ws ? "panelapp-app-web" : "${var.name.ws_product}-web"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/version/"
  }
}

resource "aws_lb_listener" "panelapp_app_web" {
  load_balancer_arn = aws_lb.panelapp.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = local.elb_security_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.panelapp_app_web.arn
  }

  routing_http_response_server_enabled                         = false
  routing_http_response_strict_transport_security_header_value = "max-age=31536000; includeSubDomains; preload"
  routing_http_response_x_content_type_options_header_value    = "nosniff"
  routing_http_response_x_frame_options_header_value           = "DENY"
}

resource "aws_lb_listener_rule" "robots_txt" {
  listener_arn = aws_lb_listener.panelapp_app_web.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/robots.txt"]
    }
  }

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "User-agent: *\n${var.env_name == "prod" ? "Disallow: /accounts/\nDisallow: /api/\n" : "Disallow: /\n"}"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "media_redirect" {
  listener_arn = aws_lb_listener.panelapp_app_web.arn
  priority     = 20

  condition {
    path_pattern {
      values = ["/media/*"]
    }
  }

  action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol    = "HTTPS"
      port        = "443"
      host        = var.media_cdn_alias
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

resource "aws_lb_listener_rule" "statics_redirect" {
  listener_arn = aws_lb_listener.panelapp_app_web.arn
  priority     = 21

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }

  action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol    = "HTTPS"
      port        = "443"
      host        = var.static_cdn_alias
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

# ELB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.name.ws_product}-alb"
  description = "default group for panelapp load balancer"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name.ws_product}-alb"
  }
}

data "aws_ec2_managed_prefix_list" "on_premise" {
  filter {
    name   = "prefix-list-name"
    values = ["on_premise"]
  }
}

data "aws_ec2_managed_prefix_list" "gel_aws" {
  filter {
    name   = "prefix-list-name"
    values = ["gel_aws"]
  }
}

resource "aws_security_group_rule" "panelapp_ingress_gel" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.gel_aws.id,
    data.aws_ec2_managed_prefix_list.on_premise.id
  ]

  security_group_id = aws_security_group.alb.id
  description       = "Centrally managed prefix lists to ELB"
}

resource "aws_security_group_rule" "panelapp_egress_ecs" {
  type      = "egress"
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"

  source_security_group_id = aws_security_group.fargate.id

  security_group_id = aws_security_group.alb.id
  description       = "ELB to PanelApp (Fargate)"
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.name.bucket}-logs"
  force_destroy = !local.is_default_ws
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  # checkov:skip=CKV2_AWS_65: ACL required by CloudWatch
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
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

data "aws_iam_policy_document" "logs" {
  statement {
    sid     = "AllowELBLogs"
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::652711504416:root", # ELB for eu-west-2
      ]
    }
    resources = [
      "${aws_s3_bucket.logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }

  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
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

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json
}
