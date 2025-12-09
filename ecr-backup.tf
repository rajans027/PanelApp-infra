###############################################################
# ECR ARCHIVE (Backup)
###############################################################

locals {
  backup_restore_test_prefix = "restore-test-"
}

# -------------------------------
# Archive bucket
# -------------------------------
resource "aws_s3_bucket" "ecr_archive" {
  bucket = "${data.aws_caller_identity.current.account_id}-ecr-archive"
  tags   = var.extra_tags
}

resource "aws_s3_bucket_versioning" "ecr_archive" {
  bucket = aws_s3_bucket.ecr_archive.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "ecr_archive" {
  bucket = aws_s3_bucket.ecr_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ecr_archive" {
  bucket = aws_s3_bucket.ecr_archive.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ecr_archive" {
  bucket = aws_s3_bucket.ecr_archive.id

  rule {
    id     = "Archive"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    transition {
      days          = 1
      storage_class = "GLACIER"
    }

    transition {
      days          = 91
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ecr_archive" {
  bucket = aws_s3_bucket.ecr_archive.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "ecr_archive" {
  bucket = aws_s3_bucket.ecr_archive.id
  policy = data.aws_iam_policy_document.ecr_archive.json
}

data "aws_iam_policy_document" "ecr_archive" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.ecr_archive.arn,
      "${aws_s3_bucket.ecr_archive.arn}/*"
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

###############################################################
# ECR ARCHIVER (scheduled backup)
###############################################################

module "ecr_archiver" {
  source = "git::https://gitlab.com/genomicsengland/opensource/terraform-modules/ecr-archiver//modules/archiver?ref=1285347ce44a6e97050b0cee9b6e458106fae201"

  name                = "ecr-archiver"
  archive_bucket_id   = aws_s3_bucket.ecr_archive.id
  boundary_policy_arn = var.permissions_boundary
  image_filter        = "^[0-9].*$"
  kms_key_id          = var.kms_key_arn
  schedule            = "cron(30 2 * * ? *)"

  repositories = var.repo_names
}

###############################################################
# RESTORE TEST REPOSITORIES
###############################################################

resource "aws_ecr_repository" "restore_test" {
  for_each = var.repo_names

  name = "${local.backup_restore_test_prefix}${each.value}"

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
}

###############################################################
# ECR RESTORER (for restore-test-* repos)
###############################################################

module "ecr_restorer" {
  source = "git::https://gitlab.com/genomicsengland/opensource/terraform-modules/ecr-archiver//modules/restorer?ref=1285347ce44a6e97050b0cee9b6e458106fae201"

  name                = "ecr-restorer"
  archive_bucket      = aws_s3_bucket.ecr_archive.id
  repositories        = var.repo_names
  restore_test_prefix = local.backup_restore_test_prefix
  boundary_policy_arn = var.permissions_boundary
  kms_key_id          = var.kms_key_arn
}

###############################################################
# LIFECYCLE POLICY FOR RESTORE TEST REPOS
###############################################################

module "lifecycle_policy_ecr_restore" {
  source   = "git::https://gitlab.com/genomicsengland/opensource/terraform-modules/ecr-cleanup?ref=4da600a110841a3dd96fbc28af0b6362656bee84"
  for_each = var.repo_names

  repository         = aws_ecr_repository.restore_test[each.key].name
  protected_prefixes = []
  prefix_ttls        = []
  minimum_ttl        = 1
  untagged_ttl       = 1
}
