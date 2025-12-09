resource "aws_ecr_repository" "application" {
  for_each             = toset(var.repo_names)
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
}

resource "aws_ecr_repository_policy" "application" {
  for_each   = toset(var.repo_names)
  repository = aws_ecr_repository.application[each.value].name
  policy     = data.aws_iam_policy_document.ecr_infra_registry.json
}

data "aws_iam_policy_document" "ecr_infra_registry" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:ListImages",
    ]

    principals {
      type = "AWS"
      identifiers = toset(flatten(
        [for v in var.pull_trusted_accounts : ["arn:aws:iam::${v}:root"]]
      ))
    }
  }
  statement {
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

module "lifecycle_policy" {
  source             = "git::https://gitlab.com/genomicsengland/opensource/terraform-modules/ecr-cleanup?ref=4da600a110841a3dd96fbc28af0b6362656bee8" # commit hash of version: 2023.06.23
  for_each           = toset(var.repo_names)
  repository         = aws_ecr_repository.application[each.value].name
  protected_prefixes = ["latest-build", "latest-dev-", "latest-test-", "latest-e2e-", "latest-uat-", "latest-prod-"]
  prefix_ttls = [
    { prefix = "0", days = 30 },
    { prefix = "1", days = 30 },
    { prefix = "2", days = 30 },
    { prefix = "3", days = 30 },
    { prefix = "4", days = 30 },
    { prefix = "5", days = 30 },
    { prefix = "6", days = 30 },
    { prefix = "7", days = 30 },
    { prefix = "8", days = 30 },
    { prefix = "9", days = 30 },
  ]
  minimum_ttl  = 14
  untagged_ttl = 1
}
