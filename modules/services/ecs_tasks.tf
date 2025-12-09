locals {
  standalone_tasks = {
    migrate = {
      short_name = "${var.name.ws_product}-migrate"
      command    = ["manage migrate"]
      log_group  = "migrate"
    }
    collect_static = {
      short_name = "${var.name.ws_product}-collect_static"
      command    = ["python -c \"import boto3; boto3.resource('s3').Bucket('${var.buckets.statics.name}').objects.all().delete()\" && manage collectstatic --noinput"]
      log_group  = "collect_static"
    }
    data_cleanup = {
      short_name = "${var.name.ws_product}-data_cleanup"
      command    = ["datacleanup"]
      log_group  = "data_cleanup"
    }
    ensembl_id_update = {
      short_name = "${var.name.ws_product}-ensembl_id_update"
      command    = ["ensembl_id_update \"$INPUT_PATH\" \"$OUTPUT_PATH\""]
      log_group  = "ensembl_id_update"
    }
  }
  standalone_tasks_active = toset([for key in keys(local.standalone_tasks) : key if(var.env_name != "prod") || (key != "data_cleanup")])
}

resource "aws_ecs_task_definition" "panelapp_standalone" {
  for_each                 = local.standalone_tasks_active
  family                   = local.standalone_tasks[each.key].short_name
  task_role_arn            = aws_iam_role.ecs_task_panelapp.arn
  execution_role_arn       = aws_iam_role.ecs_task_panelapp.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task.default.cpu
  memory                   = var.task.default.memory
  container_definitions = jsonencode([
    {
      name       = local.standalone_tasks[each.key].short_name
      image      = var.docker_image
      entryPoint = ["sh", "-c"]
      command    = local.standalone_tasks[each.key].command
      cpu        = var.task.default.cpu
      memory     = var.task.default.memory
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.panelapp[local.standalone_tasks[each.key].log_group].name
          awslogs-stream-prefix = local.standalone_tasks[each.key].short_name
          awslogs-region        = data.aws_region.current.region
        }
      }
      essential              = true
      mountPoints            = []
      portMappings           = []
      volumesFrom            = []
      readonlyRootFilesystem = true
      environment = concat([
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
          name  = "AWS_S3_OBJECT_PARAMETERS"
          value = "{\"ServerSideEncryption\": \"AES256\"}"
        },
        {
          name  = "AWS_DEFAULT_ACL"
          value = "private"
        },
        {
          name  = "ALLOWED_HOSTS"
          value = "*"
        },
        {
          name  = "DEFAULT_FROM_EMAIL"
          value = var.email.sender_address
        },
        {
          name  = "PANEL_APP_EMAIL"
          value = var.email.contact_address
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
          name  = "GUNICORN_WORKERS"
          value = tostring(var.panelapp.workers)
        },
        {
          name  = "GUNICORN_TIMEOUT"
          value = tostring(var.panelapp.connection_timeout)
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
          name  = "PANELAPP_USE_AWS_S3_ENCRYPTION"
          value = "feature flag to turn on s3 encryption in new aws accounts"
        },
        {
          name  = "TMPDIR"
          value = "/dev/shm"
        },
        {
          name  = "DD_APPLICATION"
          value = "panelapp-standalone_tasks"
        },
        {
          name = "DD_TAGS"
          value = join(",", [
            for k, v in merge(var.datadog_tags_map, { Application : "panelapp-standalone_tasks" }) : "${k}:${v}"
          ])
        },
        {
          name = "DD_TRACE_SPAN_TAGS"
          value = join(",", [
            for k, v in merge(var.datadog_tags_map, { Application : "panelapp-standalone_tasks" }) : "${k}:${v}"
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
        }
      ]
    }
  ])

  tags = {
    Name        = local.standalone_tasks[each.key].short_name
    Application = "panelapp-standalone_tasks"
  }
}
