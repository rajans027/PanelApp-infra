locals {
  is_default_ws       = terraform.workspace == "default"
  is_default_ws_count = local.is_default_ws ? 1 : 0

  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/GELBoundary"
}
