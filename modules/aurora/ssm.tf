resource "aws_ssm_parameter" "rds_snapshot" {
  name        = "/${var.name.ws_product}/rds/snapshot"
  description = "Name of the most recently loaded or saved snapshot (excluding automatic backups). Data may have changed since the snapshot was loaded or saved."
  type        = "String"
  value       = "no snapshot loaded"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
