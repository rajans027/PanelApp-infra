resource "aws_iam_role" "automation" {
  name                 = "${var.name.ws_product}-automation-runbook-execution"
  assume_role_policy   = data.aws_iam_policy_document.automation_assume.json
  permissions_boundary = var.boundary_policy_arn
}

resource "aws_iam_role_policy" "automation" {
  name   = "${var.name.ws_product}-automation"
  role   = aws_iam_role.automation.id
  policy = data.aws_iam_policy_document.automation.json
}

data "aws_iam_policy_document" "automation_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:automation-execution/*"]
    }
  }
}

data "aws_iam_policy_document" "automation" {
  statement {
    sid = "DeleteInactiveTaskDefsRead"
    actions = [
      "ecs:listTaskDefinitions",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "DeleteInactiveTaskDefsDelete"
    actions = [
      "ecs:DeleteTaskDefinitions",
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task-definition/panelapp-*",
      "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task-definition/*-panelapp-*",
    ]
  }
  statement {
    sid = "RunStandaloneTasks"
    actions = [
      "ecs:runTask",
    ]
    resources = [for x in var.standalone_tasks : x.arn]
  }
  statement {
    sid = "WaitForTask"
    actions = [
      "ecs:DescribeTasks",
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task/${var.ecs_cluster}/*"
    ]
  }
  statement {
    sid    = "PassRoleToRunTasks"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [var.ecs_task_iam_role_arn]
  }
  statement {
    sid = "ParameterManagement"
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
    resources = [
      var.ssm_parameters.panelapp_banner.arn,
      var.ssm_parameters.aurora_snapshot.arn
    ]
  }
  statement {
    sid = "RestartService"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]
    resources = [
      var.ecs_services.web.arn,
      var.ecs_services.worker.arn,
      var.ecs_services.worker_beat.arn
    ]
  }
  statement {
    sid = "ModifyCluster"
    actions = [
      "rds:ModifyDBCluster"
    ]
    resources = [
      var.aurora.cluster.arn,
      var.aurora.parameter_groups.read-write.arn,
      var.aurora.parameter_groups.read-only.arn
    ]
  }
  statement {
    sid = "UploadData"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.upload.arn}/*",
      "${aws_s3_bucket.artifacts.arn}/*"
    ]
  }
  statement {
    sid = "EncryptData"
    actions = [
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.automation.arn,
      aws_kms_alias.automation.arn,
    ]
  }
  statement {
    sid = "CreateDatabaseSnapshots"
    actions = [
      "rds:AddTagsToResource",
      "rds:CreateDBClusterSnapshot",
      "rds:DescribeDBClusterSnapshots",
      "rds:ModifyDBClusterSnapshotAttribute",
    ]
    resources = [
      var.aurora.cluster.arn,
      "arn:aws:rds:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster-snapshot:${var.aurora.cluster.name}-*",
      "arn:aws:rds:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster-snapshot:copy-*",
    ]
  }
  statement {
    sid = "CopyDatabaseSnapshots"
    actions = [
      "rds:CopyDBClusterSnapshot",
    ]
    resources = concat(
      [var.aurora.cluster.arn],
      [
        for account in var.aurora.accounts_to_copy_from :
        "arn:aws:rds:${data.aws_region.current.region}:${account}:cluster-snapshot:*"
      ]
    )
  }
  statement {
    sid = "EncryptDatabaseSnapshots"
    actions = [
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:CreateGrant",
    ]
    resources = [var.aurora.encryption_key_arn]
  }
  statement {
    sid = "DecryptDatabaseSnapshots"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = var.aurora.decryption_key_arns
  }
  statement {
    sid = "QueryAthena"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
    ]
    resources = [var.athena.workgroup.arn]
  }
  statement {
    sid = "AthenaVerifyBucket"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:PutObject",
    ]
    resources = [
      var.athena.result_bucket.arn,
      "${var.athena.result_bucket.arn}/*",
    ]
  }
  statement {
    sid = "GlueForAthena"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
    ]
    resources = flatten([
      var.athena.database.arn,
      var.athena.catalog.arn,
      [for k, v in var.athena.tables : v.arn]
    ])
  }
}
