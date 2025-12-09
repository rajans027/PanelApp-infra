resource "aws_security_group" "postgres_client" {
  # checkov:skip=CKV2_AWS_5:false positive
  name        = "${var.name.ws_product}-mgt"
  description = "PanelApp Management Security Group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name.ws_product}-mgt"
  }
}

resource "aws_security_group_rule" "postgres_client_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.postgres_client.id
  description       = "http egress for software repos"
}

resource "aws_security_group_rule" "postgres_client_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.postgres_client.id
  description       = "https egress for aws apis"
}
