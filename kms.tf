###############################################
# RDS KMS KEY (always created per environment)
###############################################

resource "aws_kms_key" "rds" {
  description = "RDS encryption key for ${var.project_name}-${var.env_name}"
  policy      = data.aws_iam_policy_document.rds_kms_policy.json

  tags = {
    Name        = "${var.project_name}-${var.env_name}-rds-kms"
    Environment = var.env_name
    Application = "PanelApp"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.env_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

###############################################
# KMS KEY POLICY
###############################################

data "aws_iam_policy_document" "rds_kms_policy" {
  #
  # Root user for THIS account
  #
  statement {
    sid = "RootAccountFullAccess"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  #
  # Cross-account allowed accounts (var.trusted_accounts)
  #
  dynamic "statement" {
    for_each = length(var.trusted_accounts) > 0 ? [1] : []
    content {
      sid = "TrustedAccountsKMSAccess"

      principals {
        type = "AWS"
        identifiers = [
          for acc in var.trusted_accounts : "arn:aws:iam::${acc}:root"
        ]
      }

      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
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
