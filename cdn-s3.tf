#############################################
# STATIC ASSETS BUCKET
#############################################

resource "aws_s3_bucket" "panelapp_statics" {
  bucket        = var.buckets.statics.name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "panelapp_statics" {
  bucket = aws_s3_bucket.panelapp_statics.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "panelapp_statics" {
  bucket = aws_s3_bucket.panelapp_statics.id

  rule {
    id     = "noncurrent"
    status = "Enabled"
    filter { prefix = "" }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "delete-marker"
    status = "Enabled"
    filter { prefix = "" }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "panelapp_statics" {
  bucket = aws_s3_bucket.panelapp_statics.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "panelapp_statics" {
  bucket = aws_s3_bucket.panelapp_statics.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#############################################
# MEDIA BUCKET
#############################################

resource "aws_s3_bucket" "panelapp_media" {
  bucket        = var.buckets.media.name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "panelapp_media" {
  bucket = aws_s3_bucket.panelapp_media.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "panelapp_media" {
  bucket = aws_s3_bucket.panelapp_media.id

  rule {
    id     = "noncurrent"
    status = "Enabled"
    filter { prefix = "" }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "delete-marker"
    status = "Enabled"
    filter { prefix = "" }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "panelapp_media" {
  bucket = aws_s3_bucket.panelapp_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "panelapp_media" {
  bucket = aws_s3_bucket.panelapp_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
