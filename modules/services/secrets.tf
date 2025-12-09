### Datadog APi key secret creation

locals {
  datadog_api_key = {
    arn = local.is_default_ws ? module.datadog_api_key[0].arn : data.aws_secretsmanager_secret.datadog_api_key[0].arn
  }
}

module "datadog_api_key" {
  count  = local.is_default_ws_count
  source = "git::https://gitlab.com/genomicsengland/opensource/terraform-modules/terraform-aws-gel-secret?ref=921ee477522eba57e23f26395e0fddb7270e70f" # commit hash of version: v2.2.0
  providers = {
    aws.core_shared_secret = aws.secrets
  }

  kms_key_id = "arn:aws:kms:eu-west-2:512426816668:key/2df400d7-a9d5-4c11-ae6a-abcd69ca1466"

  account_env  = var.env_name
  account_name = "panelapp"
  application  = "datadog"
  secret_name  = "dd_api_key"

  description = "Datadog API key"

  write_arns = []
  read_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CIDeploypanelapp",
    aws_iam_role.ecs_task_panelapp.arn,
  ]
  read_arn_wildcards = (var.env_name == "dev" || var.env_name == "test") ? [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-panelapp-tasks"
  ] : []
}

data "aws_secretsmanager_secret" "datadog_api_key" {
  count    = 1 - local.is_default_ws_count
  name     = "/${var.env_name}/panelapp/datadog/dd_api_key"
  provider = aws.secrets
}
