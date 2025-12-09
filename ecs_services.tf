locals {
  services = {
    web = {
      name          = "${var.project_name}-${var.env_name}-web"
      desired_count = var.panelapp_task_counts["web"]
      entry_point = [
        "gunicorn", "--worker-tmp-dir=/dev/shm",
        "--config=file:/app/gunicorn_config.py",
        "panelapp.wsgi:application"
      ]
    }

    worker = {
      name          = "${var.project_name}-${var.env_name}-worker"
      desired_count = var.panelapp_task_counts["worker"]
      entry_point = [
        "celery", "--app", "panelapp", "--quiet",
        "worker", "--task-events", "--concurrency", "2"
      ]
    }

    worker_beat = {
      name          = "${var.project_name}-${var.env_name}-worker_beat"
      desired_count = 1
      entry_point = [
        "celery", "--app", "panelapp", "beat",
        "--pidfile=/dev/shm/celerybeat-pid",
        "--schedule=/dev/shm/celerybeat-schedule.db"
      ]
    }
  }
}

resource "aws_ecs_service" "panelapp_services" {
  for_each = local.services

  name            = each.value.name
  cluster         = aws_ecs_cluster.panelapp_cluster.id
  task_definition = aws_ecs_task_definition.panelapp_services[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.fargate.id]
    subnets         = [for s in data.aws_subnet.private : s.id]
  }

  dynamic "load_balancer" {
    for_each = each.key == "web" ? ["yes"] : []
    content {
      target_group_arn = aws_lb_target_group.panelapp_app_web.arn
      container_name   = each.value.name
      container_port   = 8080
    }
  }
}

resource "aws_ecs_task_definition" "panelapp_services" {
  for_each = local.services

  family                   = each.value.name
  task_role_arn            = aws_iam_role.ecs_task_panelapp.arn
  execution_role_arn       = aws_iam_role.ecs_task_panelapp.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.task[each.key].cpu
  memory = var.task[each.key].memory

  container_definitions = jsonencode([
    {
      name       = each.value.name
      image      = var.docker_image
      entryPoint = each.value.entry_point

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.panelapp[each.key].name
          awslogs-region        = var.region
          awslogs-stream-prefix = each.value.name
        }
      }

      portMappings = each.key == "web" ? [
        { containerPort = 8080, hostPort = 8080, protocol = "tcp" }
      ] : []

      environment = [
        { name = "DATABASE_HOST",            value = var.database.writer_endpoint },
        { name = "DATABASE_PORT",            value = tostring(var.database.port) },
        { name = "DATABASE_NAME",            value = var.database.name },
        { name = "DATABASE_USER",            value = var.database.user },
        { name = "DJANGO_LOG_LEVEL",         value = var.django.log_level },
        { name = "DJANGO_SETTINGS_MODULE",   value = var.django.settings_module },
        { name = "APP_DOMAIN",               value = var.app_domain },
        { name = "MEDIA_DOMAIN",             value = var.media_domain },
        { name = "STATIC_DOMAIN",            value = var.static_domain }
      ]

      secrets = [
        { name = "DATABASE_PASSWORD", valueFrom = var.database.master_password_arn },
        { name = "OMIM_API_KEY",      valueFrom = var.omim_api_key_arn },
      ]
    }
  ])
}
