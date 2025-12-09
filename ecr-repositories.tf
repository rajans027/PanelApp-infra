###############################################################
# ECR Repositories
###############################################################

resource "aws_ecr_repository" "application" {
  for_each = var.repo_names
  name     = each.value

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = {
    Project = var.project_name
    Env     = var.env_name
  }
}

###############################################################
# ECR Repository Policies
###############################################################

resource "aws_ecr_repository_policy" "application" {
  for_each   = aws_ecr_repository.application
  repository = each.value.name
  policy     = data.aws_iam_policy_document.ecr_policy[each.key].json
}

data "aws_iam_policy_document" "ecr_policy" {
  for_each = var.repo_names

  # Allow trusted accounts to pull images
  statement {
    sid    = "TrustedPullers"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:ListImages",
    ]

    principals {
      type = "AWS"
      identifiers = [
        for acct in var.pull_trusted_accounts :
        "arn:aws:iam::${acct}:root"
      ]
    }
  }

  # Allow CI/CD trusted roles full push/pull capabilities
  statement {
    sid    = "TrustedPushPull"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeRepositories",
      "ecr:GetLifecyclePolicy",
      "ecr:ListImages",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    principals {
      type        = "AWS"
      identifiers = var.push_pull_trusted_roles
    }
  }
}

###############################################################
# ECR Lifecycle Rules (Root Implementation)
###############################################################

# One lifecycle rule JSON per repository
data "aws_ecr_lifecycle_policy_document" "json" {
  for_each = var.repo_names

  rule {
    description = "Expire old numeric tags after 30 days"
    selection {
      tag_status     = "tagged"
      tag_prefixes   = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
      count_type     = "sinceImagePushed"
      count_unit     = "days"
      count_number   = 30
    }
    action {
      type = "expire"
    }
  }

  # Protect important prefixes
  rule {
    description = "Protect latest-* images"
    selection {
      tag_status   = "tagged"
      tag_prefixes = [
        "latest-build",
        "latest-dev-",
        "latest-test-",
        "latest-e2e-",
        "latest-uat-",
        "latest-prod-"
      ]
      count_type   = "imageCountMoreThan"
      count_number = 9999
    }
    action {
      type = "expire"
    }
  }

  # Expire untagged
  rule {
    description = "Expire untagged images after 1 day"
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
    action {
      type = "expire"
    }
  }
}

# Attach lifecycle policy
resource "aws_ecr_lifecycle_policy" "application" {
  for_each   = aws_ecr_repository.application
  repository = each.value.name
  policy     = data.aws_ecr_lifecycle_policy_document.json[each.key].json
}
