env_name   = "uat"
account_id = "400119055163"
vpc_id     = "vpc-01a67de852b29ed86"

aurora = {
  cluster_size               = 2
  instance_class             = "db.t3.medium"
  engine_version             = "14.15"
  auto_minor_version_upgrade = false
}

signed_off_archive_base_url = "https://uat-nhsgms-panelapp.genomicsengland.co.uk"
active_scheduled_tasks = [
  "moi-check",
]

# Application
gunicorn_workers = 8

create_mgmt_box = false

enable_graphiql = false
