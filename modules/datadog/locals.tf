locals {
  is_default_ws       = terraform.workspace == "default"
  is_default_ws_count = local.is_default_ws ? 1 : 0

  datadog_identifier = "KMDS PanelApp [${var.env_name}${local.is_default_ws ? "" : ":${terraform.workspace}"}]"

  dd_tags_map  = var.tags
  dd_tags_list = [for k, v in local.dd_tags_map : "${k}:${v}"]

  # Map of environments to DataDog private synthetic locations
  private_synthetic_locations = {
    "dev"  = "pl:devawsgelac-3d7fff16f8e5b7c0b258ca9e3c134c71",
    "test" = "pl:testawsgelac-c7aa621e0fb018909a2ab9e151b4906f",
    "e2e"  = "pl:testawsgelac-c7aa621e0fb018909a2ab9e151b4906f", # no dedicated pl for e2e yet
    "uat"  = "pl:uatawsgelac-20a27d2cf7cdafea3962ca24be44a141",
    # currently broken: GEL-246497
    #"prod" = "pl:prodawsgelac-b602ef21e8643edbb7d47b39202fbf30"
    "prod" = "pl:uatawsgelac-20a27d2cf7cdafea3962ca24be44a141"
  }

  url_synthetic_checks = {
    media = {
      url          = "https://${var.media_cdn_alias}/media/__canary__.txt",
      content_type = "text/plain"
      priority     = local.datadog_priorities.warning
    }
    static = {
      url          = "https://${var.static_cdn_alias}/static/__canary__.txt"
      content_type = "text/plain"
      priority     = local.datadog_priorities.warning
    }
  }

  # Alerting and Out of Hour Support
  # | Type    | Env  | Priority      | OpsGenie |
  # |---------|------|---------------|----------|
  # | error   | prod | P1 (critical) | yes      |
  # | error   | uat  | P3 (medium)   | no       |
  # | error   | e2e  | P4 (low)      | no       |
  # | error   | test | P4 (low)      | no       |
  # | error   | dev  | P5 (info)     | no       |
  # | warning | all  | P5 (info)     | no       |
  #
  # Slack notification mapping in use; only alerts that require out-of-hour support in some environments should use error
  slack_notifications = {
    warning = {
      dev  = "@slack-kmds_alerts"
      test = "@slack-kmds_alerts"
      e2e  = "@slack-kmds_alerts"
      uat  = "@slack-kmds_alerts"
      prod = "@slack-kmds_alerts_prod"
    }[var.env_name]
    error = {
      dev  = "@slack-kmds_alerts"
      test = "@slack-kmds_alerts"
      e2e  = "@slack-kmds_alerts"
      uat  = "@slack-kmds_alerts"
      prod = "@slack-kmds_alerts_prod @opsgenie-Knowledge_Management @opsgenie-HC_CVA_IP_IPC_KMDS"
    }[var.env_name]
  }

  datadog_priorities = {
    error = {
      dev  = 5
      test = 4
      e2e  = 4
      uat  = 3
      prod = 1
    }[var.env_name]
    warning = {
      dev  = 5
      test = 5
      e2e  = 5
      uat  = 5
      prod = 5
    }[var.env_name]
  }
}
