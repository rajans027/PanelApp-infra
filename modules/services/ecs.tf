resource "aws_ecs_cluster" "panelapp_cluster" {
  name = var.name.ws_product
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
