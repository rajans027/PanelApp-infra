locals {
  services = {
    web = {
      name          = "${var.project_name}-${var.env_name}-web"
      desired_count = var.panelapp_task_counts["web"]
      entry_point = [
        "ddtrace-run", "gunicorn", "--worker-tmp-dir=/dev/shm", "--config=file:/app/gunicorn_config.py", "panelapp.wsgi:application",
      ]
    }
    worker = {
      name          = "${var.project_name}-${var.env_name}-worker"
      desired_count = var.panelapp_task_counts["worker"]
      entry_point = [
        "ddtrace-run", "celery", "--app", "panelapp", "--quiet", "worker", "--task-events", "--concurrency", "2"
      ]
    }
    worker_beat = {
      name          = "${var.project_name}-${var.env_name}-worker_beat"
      desired_count = 1
      entry_point = [
        "ddtrace-run", "celery", "--app", "panelapp", "beat", "--pidfile=/dev/shm/celerybeat-pid", "--schedule=/dev/shm/celerybeat-schedule.db"
      ]
    }
  }

}

resource "aws_ecs_service" "panelapp_services" {
  for_each              = local.services
  name                  = local.services[each.key].name
  cluster               = aws_ecs_cluster.panelapp_cluster.id
  task_definition       = aws_ecs_task_definition.panelapp_services[each.key].arn
  desired_count         = local.services[each.key].desired_count
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  dynamic "load_balancer" {
    for_each = each.key == "web" ? ["yes"] : []
    iterator = lb
    content {
      target_group_arn = aws_lb_target_group.panelapp_app_web.arn
      container_name   = local.services[each.key].name
      container_port   = 8080
    }
  }

  network_configuration {
    security_groups = [aws_security_group.fargate.id]
    subnets         = [for x in data.aws_subnet.private : x.id]
  }

  tags = {
    Name        = local.services[each.key].name
    Application = local.services[each.key].name
  }
}

resource "aws_ecs_task_definition" "panelapp_services" {
  for_each                 = local.services
  family                   = "${var.project_name}-${each.key}"
  task_role_arn            = aws_iam_role.ecs_task_panelapp.arn
  execution_role_arn       = aws_iam_role.ecs_task_panelapp.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task[each.key].cpu
  memory                   = var.task[each.key].memory

  container_definitions = jsonencode([
    {
      name       = local.services[each.key].name
      image      = var.docker_image
      entryPoint = local.services[each.key].entry_point
      cpu        = var.task[each.key].cpu
      memory     = var.task[each.key].memory
      logConfiguration = {
        logDriver = "awsfirelens"
      }
      essential   = true
      mountPoints = []
      portMappings = each.key == "web" ? [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ] : [],
      volumesFrom            = []
      readonlyRootFilesystem = true
      environment = concat([
        {
          name  = "TASK_QUEUE_NAME"
          value = "${var.project_name}-${var.env_name}"
        },
        {
          name  = "DATABASE_HOST"
          value = var.database.writer_endpoint
        },
        {
          name  = "DATABASE_PORT"
          value = tostring(var.database.port)
        },
        {
          name  = "DATABASE_NAME"
          value = var.database.name
        },
        {
          name  = "DATABASE_USER"
          value = var.database.user
        },
        {
          name  = "DJANGO_LOG_LEVEL"
          value = var.django.log_level
        },
        {
          name  = "DJANGO_SETTINGS_MODULE"
          value = var.django.settings_module
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.region
        },
        {
          name  = "AWS_S3_STATICFILES_BUCKET_NAME"
          value = var.buckets.statics.name
        },
        {
          name  = "AWS_S3_MEDIAFILES_BUCKET_NAME"
          value = var.buckets.media.name
        },
        {
          name  = "AWS_S3_STATICFILES_CUSTOM_DOMAIN"
          value = var.static_cdn_alias
        },
        {
          name  = "AWS_S3_MEDIAFILES_CUSTOM_DOMAIN"
          value = var.media_cdn_alias
        },
        {
          name  = "AWS_STATICFILES_USE_RELATIVE_URL"
          value = "TRUE"
        },
        {
          name  = "ALLOWED_HOSTS"
          value = "*"
        },
        {
          name  = "DEFAULT_FROM_EMAIL"
          value = var.email.email_sender
        },
        {
          name  = "PANEL_APP_EMAIL"
          value = var.email.email_contact
        },
        {
          name  = "EMAIL_HOST"
          value = var.email.smtp_server
        },
        {
          name  = "EMAIL_PORT"
          value = tostring(var.email.smtp_port)
        },
        {
          name  = "PANEL_APP_BASE_URL"
          value = "https://${var.cdn_alias}"
        },
        {
          name  = "DJANGO_ADMIN_URL"
          value = aws_ssm_parameter.django_admin_url.value
        },
        {
          name  = "SESSION_COOKIE_AGE"
          value = tostring(var.session.cookie_age)
        },
        {
          name  = "GUNICORN_WORKERS"
          value = tostring(var.panelapp.workers)
        },
        {
          name  = "GUNICORN_TIMEOUT"
          value = tostring(var.panelapp.connection_timeout)
        },
        {
          name  = "GUNICORN_ACCESSLOG"
          value = var.panelapp.access_log
        },
        {
          name  = "GUNICORN_ACCESS_LOG_FORMAT"
          value = "%({cf-connecting-ip}i)s %(l)s %(u)s %(t)s \"%(r)s\" %(s)s %(b)s \"%(f)s\" \"%(a)s\""
        },
        {
          name  = "GUNICORN_SERVER_HEADER"
          value = "unknown"
        },
        {
          name  = "EMAIL_HOST_USER"
          value = data.aws_ssm_parameter.user.value
        },
        {
          name  = "EMAIL_HOST_PASSWORD"
          value = data.aws_ssm_parameter.password.value
        },
        {
          name  = "AWS_USE_COGNITO"
          value = "false"
        },
        {
          name  = "AWS_COGNITO_DOMAIN_PREFIX"
          value = ""
        },
        {
          name  = "AWS_COGNITO_USER_POOL_CLIENT_ID"
          value = ""
        },
        {
          name  = "ACTIVE_SCHEDULED_TASKS"
          value = join(";", var.scheduled_tasks.tasks)
        },
        {
          name  = "SIGNED_OFF_ARCHIVE_BASE_URL"
          value = var.gmspanels_url
        },
        {
          name  = "MOI_CHECK_DAY_OF_WEEK"
          value = var.scheduled_tasks.config.moi_check_day_of_week
        },
        {
          name  = "PANELAPP_USE_AWS_S3_ENCRYPTION"
          value = "feature flag to turn on s3 encryption in new aws accounts"
        },
        {
          name  = "JWT_ACCESS_TOKEN_LIFETIME"
          value = "300"
        },
        {
          name  = "JWT_REFRESH_TOKEN_LIFETIME"
          value = "1800"
        },
        {
          name  = "GRAPHQL_GRAPHIQL"
          value = var.enable_graphiql ? "enabled" : "disabled"
        },
        {
          name  = "GRAPHQL_INTROSPECTION"
          value = var.enable_graphiql ? "enabled" : "disabled"
        },
        {
          name  = "GRAPHQL_QUERY_DEPTH_LIMIT"
          value = "20"
        },
        {
          name  = "TMPDIR"
          value = "/dev/shm"
        },
        {
          name  = "DD_APPLICATION"
          value = local.services[each.key].name
        },
        {
          name = "DD_TAGS"
          value = join(",", [
            for k, v in merge(var.datadog_tags_map, { Application : local.services[each.key].name }) : "${k}:${v}"
          ])
        },
        {
          name = "DD_TRACE_SPAN_TAGS"
          value = join(",", [
            for k, v in merge(var.datadog_tags_map, { Application : local.services[each.key].name }) : "${k}:${v}"
          ])
        },
        ],
        [
          for key, value in local.datadog_config : {
            name  = key
            value = value
          }
        ]
      )
      secrets = [
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = var.database.master_password_arn
        },
        {
          name      = "OMIM_API_KEY"
          valueFrom = local.omim_api_key.arn
        },
        {
          name      = "DD_API_KEY"
          valueFrom = local.datadog_api_key.arn
        },
        {
          name      = "PANELAPP_BANNER" # not a secret but valueFrom does not work with normal env vars
          valueFrom = aws_ssm_parameter.panelapp_banner.arn
        },
      ],
      dockerLabels = {
        "com.datadoghq.tags.env"     = var.datadog_tags_map.env
        "com.datadoghq.tags.service" = local.services[each.key].name
        "com.datadoghq.tags.version" = var.datadog_tags_map.version
      }
    },
    {
      name         = "log_router"
      image        = local.fluentbit_image
      cpu          = 0
      portMappings = []
      essential    = true
      entrypoint = [
        "/bin/sh",
        "-c",
        "echo $GEL_FLUENTBIT_CONFIG | base64 -d > /gel_fluentbit.conf && export ECS_TASK_ID=$(curl -s $ECS_CONTAINER_METADATA_URI_V4/task | grep -o '\"TaskARN\":\"[a-z0-9\\/:-]*' | cut -d \"/\" -f 3) && /entrypoint.sh"
      ]
      secrets = [
        {
          name      = "FORTIGATE_CA_CERT"
          valueFrom = data.aws_secretsmanager_secret_version.fortigate_ca_cert.arn
        },
        {
          name      = "DD_API_KEY"
          valueFrom = local.datadog_api_key.arn
        },
      ]
      environment = concat([
        {
          name  = "LOG_STREAM_GROUP"
          value = aws_cloudwatch_log_group.panelapp[each.key].name
        },
        {
          name  = "GEL_FLUENTBIT_CONFIG",
          value = filebase64("${path.module}/files/fluentbit.conf")
        },
        {
          name  = "DD_APPLICATION"
          value = local.services[each.key].name
        },
        {
          name = "DD_TAGS"
          value = join(",", [
            for k, v in merge(var.datadog_tags_map, { Application : local.services[each.key].name }) : "${k}:${v}"
          ])
        },
        {
          name = "DD_TRACE_SPAN_TAGS"
          value = join(",", [
            for k, v in merge(var.datadog_tags_map, { Application : local.services[each.key].name }) : "${k}:${v}"
          ])
        },
        ],
        [
          for key, value in local.datadog_config : {
            name  = key
            value = value
          }
        ]
      )
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.panelapp["${each.key}-firelens"].name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "firelens"
        }
      }
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          config-file-type        = "file"
          config-file-value       = "/gel_fluentbit.conf"
          enable-ecs-log-metadata = "true"
        }
      }
    },
    {
      name      = "datadog-agent"
      image     = local.datadog_agent_image
      essential = true
      portMappings = [
        {
          containerPort = 8126,
          hostPort      = 8126,
          protocol      = "tcp"
        }
      ]
      entryPoint = [
        "/bin/sh",
        "-c",
        "export ECS_TASK_ID=$(curl -s $ECS_CONTAINER_METADATA_URI_V4/task | grep -o '\"TaskARN\":\"[a-z0-9\\/:-]*' | cut -d \"/\" -f 3) && export DD_HOSTNAME=$ECS_TASK_ID ;/bin/entrypoint.sh"
      ]
      secrets = [
        {
          name      = "FORTIGATE_CA_CERT"
          valueFrom = data.aws_secretsmanager_secret_version.fortigate_ca_cert.arn
        },
        {
          name      = "DD_API_KEY"
          valueFrom = local.datadog_api_key.arn
        },
      ],
      environment = concat([
        {
          name  = "DD_APPLICATION"
          value = local.services[each.key].name
        },
        {
          name = "DD_TAGS"
          value = join(",", [
            for k, v in merge(var.datadog_tags_map, { Application : local.services[each.key].name }) : "${k}:${v}"
          ])
        },
        {
          name = "DD_TRACE_SPAN_TAGS"
          value = join(",", [
            for k, v in merge(var.datadog_tags_map, { Application : local.services[each.key].name }) : "${k}:${v}"
          ])
        },
        ],
        [
          for key, value in local.datadog_config : {
            name  = key
            value = value
          }
        ],
      )

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.panelapp["${each.key}-datadog_agent"].name,
          awslogs-region        = data.aws_region.current.region,
          awslogs-stream-prefix = "datadog-agent"
        }
      }
    }
  ])

  tags = {
    Name        = local.services[each.key].name
    Application = local.services[each.key].name
  }
}
