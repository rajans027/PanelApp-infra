locals {
  is_default_ws       = terraform.workspace == "default"
  is_default_ws_count = local.is_default_ws ? 1 : 0

  maintenance_mode_banner = "<strong>MAINTENANCE MODE</strong>: anonymous access only (no login, no reviews). In case of problems, please contact <a href=\"mailto:${var.email.contact}\">${var.email.contact}</a>."
}
