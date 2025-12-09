env_name   = "e2e"
account_id = "875605549679"
vpc_id     = "vpc-02368dae78f1387e5"

aurora = {
  cluster_size               = 1
  instance_class             = "db.t3.medium"
  engine_version             = "14"
  auto_minor_version_upgrade = true
}

signed_off_archive_base_url = "https://e2e-nhsgms-panelapp.genomicsengland.co.uk"
active_scheduled_tasks = [
  "moi-check",
]

gunicorn_workers = 8
create_mgmt_box  = false

enable_graphiql = false
