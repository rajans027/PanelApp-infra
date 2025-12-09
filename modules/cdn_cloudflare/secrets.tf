locals {
  cloudflare_api_key = {
    arn = local.is_default_ws ? module.cloudflare_api_key[0].arn : data.aws_secretsmanager_secret.cloudflare_api_key[0].arn
  }
  core_shared_account = "512426816668"
}

data "aws_kms_key" "core_shared_kms" {
  key_id = "arn:aws:kms:eu-west-2:${local.core_shared_account}:alias/gel_secrets_manager_core"
}

module "cloudflare_api_key" {
  count  = local.is_default_ws_count
  source = "git::https://gitlab.com/genomicsengland/opensource/terraform-modules/terraform-aws-gel-secret?ref=921ee477522eba57e23f26395e0fddb7270e70f" # commit hash of version: v2.2.0
  providers = {
    aws.core_shared_secret = aws.secrets
  }
  kms_key_id = data.aws_kms_key.core_shared_kms.arn

  account_env  = var.env_name
  account_name = "panelapp_${var.env_name}"
  application  = "cloudflare"
  secret_name  = "cache_api_key"

  description = "Cloudflare API key (cache invalidation)"

  # FIXME: temporarily allow write access until non-temporary token is generated
  write_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  read_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CIDeploypanelapp",
    # Temporarily for testing
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
    #    aws_iam_role.ecsd_task_panelapp.arn,
  ]
  read_arn_wildcards = (var.env_name == "dev" || var.env_name == "test") ? [
    #    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-panelapp-tasks"
  ] : []
}

data "aws_secretsmanager_secret" "cloudflare_api_key" {
  count    = 1 - local.is_default_ws_count
  name     = "/${var.env_name}/panelapp_${var.env_name}/cloudflare/cache_api_key"
  provider = aws.secrets
}
