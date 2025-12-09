locals {
  elb_security_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

#############################################
# Application Load Balancer
#############################################

resource "aws_lb" "panelapp" {
  name                       = "${var.project_name}-${var.env_name}-alb"
  internal                   = true
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  security_groups = [aws_security_group.alb.id]
  subnets         = [for s in data.aws_subnet.private : s.id]

  access_logs {
    bucket  = aws_s3_bucket.logs.id
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.env_name}-alb"
  }

  depends_on = [
    aws_s3_bucket_policy.logs
  ]
}

#############################################
# Target group for Web ECS service
#############################################

resource "aws_lb_target_group" "panelapp_app_web" {
  name        = "${var.project_name}-${var.env_name}-tg-web"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/version/"
  }
}

#############################################
# HTTPS Listener
#############################################

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
}

#############################################
# Listener Rules
#############################################

# robots.txt response
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
      host        = var.media_domain
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
      host        = var.static_domain
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

#############################################
# ALB Security Group
#############################################

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.env_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.env_name}-alb-sg"
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
  description       = "Allow GEL + On-prem inbound HTTPS"
}

resource "aws_security_group_rule" "panelapp_egress_ecs" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.fargate.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow ALB → ECS traffic"
}

#############################################
# S3 Access Logs Bucket
#############################################

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project_name}-${var.env_name}-alb-logs"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
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
    id     = "expire-old"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

#############################################
# S3 Bucket Policy
#############################################

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "logs" {
  statement {
    sid     = "AllowELB"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::652711504416:root" # ELB service account
      ]
    }

    resources = [
      "${aws_s3_bucket.logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }

  statement {
    sid     = "DenyUnencrypted"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
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

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json
}
