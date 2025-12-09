env_name   = "dev"
account_id = "577192787797"
vpc_id     = "vpc-07d10554b0f5f8f7c"

aurora = {
  cluster_size               = 1
  instance_class             = "db.t3.medium"
  engine_version             = "14"
  auto_minor_version_upgrade = true
}

signed_off_archive_base_url = "https://dev-nhsgms-panelapp.genomicsengland.co.uk"
active_scheduled_tasks = [
  "moi-check",
]

create_mgmt_box = false

enable_graphiql = true

