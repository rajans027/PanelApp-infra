terraform {
  required_version = "~> 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9"
    }
    # datadog = {
    #   source  = "datadog/datadog"
    #   version = "~> 3.50"
    # }
  }

  #   #backend "s3" {}
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  region = var.region
}

# provider "template" {}

# # provider "aws" {
# #   region = var.region
# #   assume_role {
# #     role_arn = "arn:aws:iam::${var.account_id}:role/CIDeploypanelapp"
# #   }
# #   default_tags {
# #     tags = module.aws_tags.tags
# #   }
# # }

# # provider "aws" {
# #   alias  = "dns"
# #   region = var.region
# #   assume_role {
# #     role_arn = "arn:aws:iam::${local.core_shared_account}:role/CIDeployRoute53"
# #   }
# #   default_tags {
# #     tags = module.aws_tags.tags
# #   }
# # }

# provider "aws" {
#   alias  = "us_east_1"
#   region = "us-east-1"
#   assume_role {
#     role_arn = "arn:aws:iam::${var.account_id}:role/CIDeploypanelapp"
#   }
#   default_tags {
#     tags = module.aws_tags.tags
#   }
# }

# provider "aws" {
#   alias  = "ssm"
#   region = var.region
#   assume_role {
#     role_arn = "arn:aws:iam::${local.core_shared_account}:role/CIDeployReadSSMParameters"
#   }
#   default_tags {
#     tags = module.aws_tags.tags
#   }
# }

# provider "aws" {
#   region = var.region
#   alias  = "core_shared"
#   assume_role {
#     role_arn = "arn:aws:iam::${local.core_shared_account}:role/ReadDatadogKeys"
#   }
#   default_tags {
#     tags = module.aws_tags.tags
#   }
# }

# provider "aws" {
#   region = var.region
#   alias  = "secrets"
#   assume_role {
#     role_arn = "arn:aws:iam::${local.core_shared_account}:role/CIDeployGELSecret"
#   }
#   default_tags {
#     tags = module.aws_tags.tags
#   }
# }

# # provider "datadog" {
# #   api_url = "https://api.datadoghq.eu/"
# #   api_key = data.aws_secretsmanager_secret_version.datadog_api_key.secret_string
# #   app_key = data.aws_secretsmanager_secret_version.datadog_app_key.secret_string
# # }

# # data "aws_secretsmanager_secret_version" "datadog_api_key" {
# #   # false positive: non-hardcoded account id: ET-969
# #   # kics-scan ignore-line
# #   secret_id = "arn:aws:secretsmanager:eu-west-2:${local.core_shared_account}:secret:/prod/root/datadog/api_key-1tsRdO"
# #   provider  = aws.core_shared
# # }

# # data "aws_secretsmanager_secret_version" "datadog_app_key" {
# #   # false positive: non-hardcoded account id: ET-969
# #   # kics-scan ignore-line
# #   secret_id = "arn:aws:secretsmanager:eu-west-2:${local.core_shared_account}:secret:/prod/root/datadog/app_key-PtwBEP"
# #   provider  = aws.core_shared
# # }
