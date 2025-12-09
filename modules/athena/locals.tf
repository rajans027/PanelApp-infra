locals {
  is_default_ws       = terraform.workspace == "default"
  is_default_ws_count = local.is_default_ws ? 1 : 0
  ws_dash_prefix      = local.is_default_ws ? "" : "${terraform.workspace}-"
  ws_dot_prefix       = local.is_default_ws ? "" : "${terraform.workspace}."
}
