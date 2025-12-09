env_name   = "prod"
account_id = "876663091628"
vpc_id     = "vpc-09da158931e884d64"

aurora = {
  cluster_size               = 2
  instance_class             = "db.t3.medium"
  engine_version             = "14.15"
  auto_minor_version_upgrade = false
}

signed_off_archive_base_url = "https://nhsgms-panelapp.genomicsengland.co.uk"
active_scheduled_tasks = [
  "moi-check",
]

# Application
gunicorn_workers = 8

create_mgmt_box = false

backup_plans = [
  { name = "panelapp_daily", schedule = "cron(0 6 * * ? *)", delete = 365, start_window = 60, completion_window = 180 },
  { name = "panelapp_weekly", schedule = "cron(0 6 ? * 1 *)", delete = 365, start_window = 60, completion_window = 180 },
  { name = "panelapp_monthly", schedule = "cron(0 6 1 * ? *)", delete = 365, start_window = 60, completion_window = 180 },
]

enable_graphiql = false
