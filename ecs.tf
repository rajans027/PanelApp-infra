resource "aws_ecs_cluster" "panelapp_cluster" {
  name = "${var.project_name}-${var.env_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
