resource "aws_security_group" "aurora" {
  # FIXME: Changing description requires removal of RDS because of the attached EMI
  description = "Managed by Terraform"
  # FIXME: Phase 2 (downtime)
  name   = local.is_default_ws ? "panelapp-database" : "${var.name.ws_product}-aurora"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.name.ws_product}-aurora"
  }
}
