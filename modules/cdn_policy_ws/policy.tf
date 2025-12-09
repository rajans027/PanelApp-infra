resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = var.bucket.name
  policy = data.aws_iam_policy_document.cloudfront.json
}

data "aws_iam_policy_document" "cloudfront" {
  statement {
    sid       = "AllowCloudFrontAccess"
    actions   = ["s3:GetObject"]
    resources = ["${var.bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.distribution_arn]
    }
  }

  statement {
    sid       = "AllowUpload"
    actions   = ["s3:PutObject"]
    resources = ["${var.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.service_role]
    }
  }

  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      var.bucket.arn,
      "${var.bucket.arn}/*"
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
