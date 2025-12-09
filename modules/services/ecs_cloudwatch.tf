locals {
  log_groups = [
    "web",
    "web-datadog_agent",
    "web-firelens",
    "worker",
    "worker-datadog_agent",
    "worker-firelens",
    "worker_beat",
    "worker_beat-datadog_agent",
    "worker_beat-firelens",
    "migrate",
    "collect_static",
    "data_cleanup",
    "ensembl_id_update"
  ]
}

resource "aws_cloudwatch_log_group" "panelapp" {
  for_each = toset(local.log_groups)

  name              = "/${var.project_name}/${each.key}"
  retention_in_days = "30"
  kms_key_id        = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Application = "${var.project_name}-${var.env_name}-${each.key}"
  }
}
