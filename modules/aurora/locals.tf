locals {
  is_default_ws       = terraform.workspace == "default"
  is_default_ws_count = local.is_default_ws ? 1 : 0

  log_retention = 365
}
