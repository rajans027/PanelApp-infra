output "security_group" {
  value = aws_security_group.fargate.id
}

output "cluster" {
  value = {
    arn  = aws_ecs_cluster.panelapp_cluster.arn
    name = aws_ecs_cluster.panelapp_cluster.name
  }
}

output "services" {
  value = {
    for x in keys(local.services) : x => {
      name          = aws_ecs_service.panelapp_services[x].name
      arn           = aws_ecs_service.panelapp_services[x].id
      desired_count = aws_ecs_service.panelapp_services[x].desired_count
    }
  }
}

output "standalone_tasks" {
  value = {
    for x in local.standalone_tasks_active : x => {
      arn  = aws_ecs_task_definition.panelapp_standalone[x].arn
      name = aws_ecs_task_definition.panelapp_standalone[x].family
    }
  }
}

output "ecs_task_iam_role" {
  value = aws_iam_role.ecs_task_panelapp.arn
}

output "elb_dns" {
  value = {
    name    = aws_lb.panelapp.dns_name
    zone_id = aws_lb.panelapp.zone_id
  }
}

output "ssm_parameters" {
  value = {
    panelapp_banner = {
      name = aws_ssm_parameter.panelapp_banner.name
      arn  = aws_ssm_parameter.panelapp_banner.arn
    }
  }
}

output "log_groups" {
  value = {
    ensembl_id_update = aws_cloudwatch_log_group.panelapp["ensembl_id_update"].name
  }
}

output "buckets" {
  value = {
    elb_logs = {
      name = aws_s3_bucket.logs.id
      arn  = aws_s3_bucket.logs.arn
    }
    waf_logs = {
      name = aws_s3_bucket.waf_logs.id
      arn  = aws_s3_bucket.waf_logs.arn
    }
  }
}

output "alb_waf" {
  value = {
    name = aws_wafv2_web_acl.panelapp.name
  }
}
