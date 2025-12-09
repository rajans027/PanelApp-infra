locals {
  ses_parameter_prefix = var.env_name == "prod" ? "/ses/panelapp-genomicsengland" : "/ses/panelapp-${var.env_name}-genomicsengland"
}

data "aws_ssm_parameter" "user" {
  provider = aws.ssm
  name     = "${local.ses_parameter_prefix}-co-uk/user" # hyphen-hyphen
}

data "aws_ssm_parameter" "password" {
  provider = aws.ssm
  name     = "${local.ses_parameter_prefix}.co.uk/password" # dot-dot
}
