locals {
  omim_api_key = {
    arn = local.is_default_ws ? aws_ssm_parameter.omim_api_key[0].arn : data.aws_ssm_parameter.omim_api_key[0].arn
  }
}

resource "aws_ssm_parameter" "omim_api_key" {
  count       = local.is_default_ws_count
  name        = "/panelapp/fargate/omim_api_key"
  description = "omim API key"
  type        = "SecureString"
  key_id      = var.kms_key_arn
  value       = "changeme"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

data "aws_ssm_parameter" "omim_api_key" {
  count = 1 - local.is_default_ws_count
  name  = "/panelapp/fargate/omim_api_key"
}

resource "random_id" "django_admin_url" {
  byte_length = 16
}

resource "aws_ssm_parameter" "django_admin_url" {
  name        = "/${var.name.ws_product}/django/admin_url"
  description = "Django secret admin url"
  type        = "SecureString"
  key_id      = var.kms_key_arn
  value       = "${random_id.django_admin_url.b64_url}/"
}

resource "aws_ssm_parameter" "panelapp_banner" {
  name        = "/${var.name.ws_product}/application/banner"
  description = "Banners for display in PanelApp. Automatically generated; DO NOT CHANGE!"
  type        = "String"
  # Cannot have an empty value for a parameter
  # PanelApp strips this value so it evaluates to empty before use
  value = " "

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
