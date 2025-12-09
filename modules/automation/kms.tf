# kics-scan disable=575a2155-6af1-4026-b1af-d5bc8fe2a904 # key policies always have "*" as resource

resource "aws_kms_key" "automation" {
  description = "PanelApp automation key ${var.name.ws_env_product}"
  policy      = data.aws_iam_policy_document.automation_key.json
}

resource "aws_kms_alias" "automation" {
  name          = "alias/${var.name.ws_env_product}-automation"
  target_key_id = aws_kms_key.automation.key_id
}

data "aws_iam_policy_document" "automation_key" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:CancelKeyDeletion",
      "kms:Create*",
      "kms:Decrypt",
      "kms:Delete*",
      "kms:Describe*",
      "kms:Disable*",
      "kms:Enable*",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:Get*",
      "kms:List*",
      "kms:Put*",
      "kms:ReEncrypt*",
      "kms:Revoke*",
      "kms:ScheduleKeyDeletion",
      "kms:Update*",
    ]
    resources = ["*"]
  }
}
