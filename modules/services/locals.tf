locals {
  is_default_ws       = terraform.workspace == "default"
  is_default_ws_count = local.is_default_ws ? 1 : 0
  ws_dash_prefix      = local.is_default_ws ? "" : "${terraform.workspace}-"
  ws_dot_prefix       = local.is_default_ws ? "" : "${terraform.workspace}."

  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/GELBoundary"

  datadog_config = {
    ECS_FARGATE                = "true"
    DD_SITE                    = "datadoghq.eu"
    DD_LOGS_INJECTION          = "true"
    DD_APM_ENABLED             = "true"
    DD_APM_NON_LOCAL_TRAFFIC   = "true"
    DD_PROCESS_AGENT_ENABLED   = "true"
    DD_TRACE_ANALYTICS_ENABLED = "true"
    DD_RUNTIME_METRICS_ENABLED = "true"
    DD_PROFILING_ENABLED       = "true"
    DD_ENV                     = var.datadog_tags_map.env
    DD_VERSION                 = var.datadog_tags_map.version
    DD_SERVICE                 = var.datadog_tags_map.service
  }

  log_retention = 365

  datadog_agent_image = var.side_cars.datadog_agent
  fluentbit_image     = var.side_cars.fluentbit
}
