resource "aws_s3_bucket" "query_results" {
  bucket        = "${var.name.bucket}-athena"
  force_destroy = !local.is_default_ws
}

resource "aws_s3_bucket_public_access_block" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "query_results" {
  bucket = aws_s3_bucket.query_results.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "query_results" {
  bucket = aws_s3_bucket.query_results.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "query_results" {
  bucket = aws_s3_bucket.query_results.id
  rule {
    id     = "expiration"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      days = 30
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

resource "aws_s3_bucket_policy" "query_results" {
  bucket = aws_s3_bucket.query_results.id
  policy = data.aws_iam_policy_document.query_results.json
}

data "aws_iam_policy_document" "query_results" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.query_results.arn,
      "${aws_s3_bucket.query_results.arn}/*"
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
