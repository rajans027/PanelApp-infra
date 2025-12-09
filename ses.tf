data "aws_ssm_parameter" "ses_user" {
  provider = aws.ssm
  name     = "${var.ses_parameter_prefix}/user"
}

data "aws_ssm_parameter" "ses_password" {
  provider = aws.ssm
  name     = "${var.ses_parameter_prefix}/password"
}
