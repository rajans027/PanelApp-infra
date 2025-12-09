locals {
  Datadog_monitors = merge(
    {
      system_memory_health = {
        parameters = {
          type              = "metric alert"
          name              = "${local.datadog_identifier} System Memory"
          message           = <<-EOF
          Check PanelApp Memory use on {{servicename}}
          ${local.slack_notifications.warning}
        EOF
          query             = format("avg(last_10m):avg:aws.ecs.memory_utilization.maximum{aws_account:%s,terraform_workspace:%s} by {servicename} > 90", data.aws_caller_identity.current.account_id, terraform.workspace)
          notify_no_data    = true
          evaluation_delay  = 300
          no_data_timeframe = 30
          priority          = local.datadog_priorities.warning
        }
        thresholds = {
          warning  = 75
          critical = 90
        }
        tags = local.dd_tags_map
      }
      cpu_utilisation = {
        parameters = {
          type              = "metric alert"
          name              = "${local.datadog_identifier} CPU use"
          message           = <<-EOF
          Check PanelApp CPU use on {{servicename}}
          ${local.slack_notifications.warning}
        EOF
          query             = format("avg(last_10m):avg:aws.ecs.cpuutilization.maximum{account_id:%s,terraform_workspace:%s} by {servicename} > 90", data.aws_caller_identity.current.account_id, terraform.workspace)
          notify_no_data    = true
          evaluation_delay  = 300
          no_data_timeframe = 30
          priority          = local.datadog_priorities.warning
        }
        thresholds = {
          warning  = 75
          critical = 90
        }
        tags = local.dd_tags_map
      }
      backup_job = {
        parameters = {
          type    = "metric alert"
          name    = "${local.datadog_identifier} Data backup"
          message = <<-EOF
          Check AWS backup for RDS Aurora and S3
          ${local.slack_notifications.warning}
        EOF
          query = format(
            "sum(last_25h):sum:aws.backup.number_of_backup_jobs_completed{account_id:%s}.as_count() < 2",
            data.aws_caller_identity.current.account_id,
          )
          require_full_window = false
          notify_no_data      = false
          evaluation_delay    = 900
          no_data_timeframe   = 30
          priority            = local.datadog_priorities.warning
        }
        thresholds = {
          warning  = null
          critical = 2
        }
        tags = merge(
          local.dd_tags_map,
          {
            Application : "backup"
          }
        )
      }
    },
    {
      for key, value in var.ecs_services : key => {
        parameters = {
          type    = "metric alert"
          name    = "${local.datadog_identifier} Tasks running ${value.name}"
          message = <<-EOF
            Check PanelApp Task ${value.name}
            ${local.slack_notifications.warning}
          EOF
          query = format(
            "max(last_10m):avg:aws.ecs.service.running{account_id:%s,servicename:%s,terraform_workspace:%s} < %d",
            data.aws_caller_identity.current.account_id,
            value.name,
            terraform.workspace,
            value.desired_count,
          )
          require_full_window = false
          notify_no_data      = true
          evaluation_delay    = 300
          no_data_timeframe   = 30
          priority            = local.datadog_priorities.warning
        }
        thresholds = {
          warning  = null
          critical = value.desired_count
        }
        tags = merge(
          local.dd_tags_map,
          {
            Application : value.name
          }
        )
      }
    }
  )
}

module "datadog-monitors" {
  source           = "git::https://gitlab.com/genomicsengland/opensource/terraform-modules/datadog-monitors?ref=82a532c916eceb423008707a1aa7899a9c611c81" # commit hash of version: 2024.11.22
  region           = data.aws_region.current.region
  datadog_monitors = local.Datadog_monitors
}

resource "datadog_synthetics_test" "test_health_endpoint" {
  type    = "api"
  subtype = "http"
  request_definition {
    method = "GET"
    url    = "https://${var.cdn_alias}/"
  }
  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }
  assertion {
    type     = "header"
    property = "Content-Type"
    operator = "is"
    target   = "text/html; charset=utf-8"
  }
  assertion {
    type     = "body"
    operator = "contains"
    target   = "Genomics England PanelApp"
  }
  locations = [local.private_synthetic_locations[var.env_name]]
  options_list {
    tick_every           = 60  # run the check every minute
    min_failure_duration = 300 # alert if failing for 5 min
    monitor_priority     = local.datadog_priorities.error

    retry {
      count    = 2
      interval = 300
    }

    monitor_options {
      renotify_interval = 90
    }
  }
  name    = "${local.datadog_identifier} health check - Error"
  message = <<-EOF
    DOWN: Check ${local.datadog_identifier}

    Runbook: https://cnfl.extge.co.uk/display/KMDS/Out+of+Hours+Support+--+PanelApp

    ${local.slack_notifications.error}
  EOF
  tags    = local.dd_tags_list

  status = "live"
}

resource "datadog_synthetics_test" "test_maintenance_mode" {
  type    = "api"
  subtype = "http"
  request_definition {
    method = "GET"
    url    = "https://${var.cdn_alias}/"
  }
  assertion {
    type     = "body"
    operator = "doesNotContain"
    target   = "MAINTENANCE MODE"
  }
  locations = [local.private_synthetic_locations[var.env_name]]
  options_list {
    tick_every           = 60 # run the check every minute
    min_failure_duration = 60 # alert if failing for 1 min
    monitor_priority     = local.datadog_priorities.warning

    retry {
      count    = 2
      interval = 300
    }

    monitor_options {
      renotify_interval = 90
    }
  }
  name    = "${local.datadog_identifier} maintenance mode - Warning"
  message = <<-EOF
    DOWN: Check ${local.datadog_identifier}

    Runbook: https://cnfl.extge.co.uk/display/KMDS/Out+of+Hours+Support+--+PanelApp

    ${local.slack_notifications.warning}
  EOF
  tags    = local.dd_tags_list

  status = "live"
}

resource "datadog_synthetics_test" "secondary" {
  for_each = local.url_synthetic_checks
  type     = "api"
  subtype  = "http"
  request_definition {
    method = "GET"
    url    = each.value.url
  }
  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }
  assertion {
    type     = "header"
    property = "Content-Type"
    operator = "is"
    target   = each.value.content_type
  }
  locations = [local.private_synthetic_locations[var.env_name]]
  options_list {
    tick_every           = 60  # run the check every minute
    min_failure_duration = 300 # alert if failing for 5 min
    monitor_priority     = each.value.priority

    retry {
      count    = 2
      interval = 300
    }

    monitor_options {
      renotify_interval = 90
    }
  }
  name    = "${local.datadog_identifier} secondary check: ${each.key} - Warning"
  message = <<-EOF
    DOWN: Check ${local.datadog_identifier}

    URL: ${each.value.url}
    Runbook: https://cnfl.extge.co.uk/display/KMDS/Out+of+Hours+Support+--+PanelApp

    ${local.is_default_ws ? local.slack_notifications.warning : ""}
  EOF
  tags    = local.dd_tags_list

  status = "live"
}
