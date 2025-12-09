data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_ec2_managed_prefix_list" "ngfw" {
  filter {
    name   = "prefix-list-name"
    values = ["ngfw"]
  }
}

data "aws_secretsmanager_secret_version" "fortigate_ca_cert" {
  secret_id = "arn:aws:secretsmanager:eu-west-2:512426816668:secret:/prod/root/ngfw/ngfw_cert-V8m5L8"
}
