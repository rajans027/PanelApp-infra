locals {
  standalone_tasks = {
    migrate = {
      short_name = "${var.project_name}-${var.env_name}-migrate"
      command    = ["manage migrate"]
      log_group  = "migrate"
    }
    collect_static = {
      short_name = "${var.project_name}-${var.env_name}-collect_static"
      command = [
        "python -c \"import boto3; boto3.resource('s3').Bucket('${var.buckets.statics.name}').objects.all().delete()\" && manage collectstatic --noinput"
      ]
      log_group = "collect_static"
    }
    data_cleanup = {
      short_name = "${var.project_name}-${var.env_name}-data_cleanup"
      command    = ["datacleanup"]
      log_group  = "data_cleanup"
    }
    ensembl_id_update = {
      short_name = "${var.project_name}-${var.env_name}-ensembl_id_update"
      command    = ["ensembl_id_update \"$INPUT_PATH\" \"$OUTPUT_PATH\""]
      log_group  = "ensembl_id_update"
    }
  }

  standalone_tasks_active = toset([for k in keys(local.standalone_tasks) : k if var.env_name != "prod" || k != "data_cleanup"])
}

resource "aws_ecs_task_definition" "panelapp_standalone" {
  for_each = local.standalone_tasks_active

  family = local.standalone_tasks[each.key].short_name
  task_role_arn      = aws_iam_role.ecs_task_panelapp.arn
  execution_role_arn = aws_iam_role.ecs_task_panelapp.arn

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task["default"].cpu
  memory                   = var.task["default"].memory

  container_definitions = jsonencode([
    {
      name       = local.standalone_tasks[each.key].short_name
      image      = var.docker_image
      entryPoint = ["sh", "-c"]
      command    = local.standalone_tasks[each.key].command

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.panelapp[local.standalone_tasks[each.key].log_group].name
          awslogs-region        = var.region
          awslogs-stream-prefix = each.key
        }
      }

      environment = [
        { name = "DATABASE_HOST",  value = var.database.writer_endpoint },
        { name = "DATABASE_PORT",  value = tostring(var.database.port) },
        { name = "DATABASE_NAME",  value = var.database.name },
        { name = "DATABASE_USER",  value = var.database.user },
        { name = "DJANGO_SETTINGS_MODULE", value = var.django.settings_module },
        { name = "DJANGO_LOG_LEVEL", value = var.django.log_level },
        { name = "AWS_S3_STATICFILES_BUCKET_NAME", value = var.buckets.statics.name },
        { name = "AWS_S3_MEDIAFILES_BUCKET_NAME",  value = var.buckets.media.name }
      ]

      secrets = [
        { name = "DATABASE_PASSWORD", valueFrom = var.database.master_password_arn }
      ]
    }
  ])
}
