# kics-scan disable=575a2155-6af1-4026-b1af-d5bc8fe2a904 # key policies always have "*" as resource

locals {
  rds_kms_key = local.is_default_ws ? aws_kms_key.rds_shared[0].arn : data.aws_kms_alias.rds_shared[0].target_key_arn
}

resource "aws_kms_key" "rds_shared" {
  count       = local.is_default_ws_count
  description = "RDS snapshot encryption key for ${var.name.ws_env_product}"
  policy      = data.aws_iam_policy_document.rds_kms_policy.json
  tags = {
    Name = "panelapp-${var.env_name}-rds"
  }
}

data "aws_kms_alias" "rds_shared" {
  count = 1 - local.is_default_ws_count
  name  = "alias/panelapp-${var.env_name}-rds"
}

resource "aws_kms_alias" "rds_shared" {
  count         = local.is_default_ws_count
  name          = "alias/panelapp-${var.env_name}-rds"
  target_key_id = aws_kms_key.rds_shared[0].key_id
}

data "aws_iam_policy_document" "rds_kms_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.trusted_accounts) > 0 ? ["yes"] : []
    content {
      principals {
        type        = "AWS"
        identifiers = [for account in var.trusted_accounts : "arn:aws:iam::${account}:root"]
      }

      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:GenerateDataKey",
        "kms:GetKeyRotationStatus",
        "kms:ListResourceTags",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ]
      resources = ["*"]
    }
  }
}
