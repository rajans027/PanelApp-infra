env_name   = "test"
account_id = "296021880454"
vpc_id     = "vpc-09747ca5ddc3a78f3"

aurora = {
  cluster_size               = 1
  instance_class             = "db.t3.medium"
  engine_version             = "14"
  auto_minor_version_upgrade = true
}

signed_off_archive_base_url = "https://test-nhsgms-panelapp.genomicsengland.co.uk"
active_scheduled_tasks = [
  "moi-check",
]

create_mgmt_box = false

enable_graphiql = true


domain_name_internal = "internal.example.test"
domain_name_external = "example.test"
dns_record_app    = "app.internal.example.test"
dns_record_media  = "media.example.test"
dns_record_static = "static.example.test"


app_domain      = "app.example.test"
media_domain    = "media.example.test"
static_domain   = "static.example.test"


task = {
  web = {
    cpu    = 4096
    memory = 8192
  }

  worker = {
    cpu    = 2048
    memory = 4096
  }

  worker_beat = {
    cpu    = 512
    memory = 1024
  }
}

waf_rate_limits = {
  web = {
    per_ip = 30
    global = 300
  }
  api = {
    per_ip = 60
    global = 600
  }
}


email_sender    = "app@example.test"
email_contact   = "support@example.test"
smtp_server     = "email-smtp.us-east-1.amazonaws.com"
smtp_port       = 587

docker_image    = "123456789012.dkr.ecr.ca-central-1.amazonaws.com/myapp:v1"
kms_key_arn     = "arn:aws:kms:..."

django_settings_module = "myapp.settings"
django_log_level       = "INFO"
admin_email            = "admin@example.test"

panelapp_task_counts = {
  web    = 4
  worker = 2
}

moi_check_day_of_week = "0"
active_scheduled_tasks = ["sync", "cleanup"]

waf_is_blocking = true
waf_rate_limits = {
  web = {
    per_ip = 20
    global = 200
  }
  api = {
    per_ip = 40
    global = 400
  }
}

datadog_tags = {
  env = "dev"
  service = "panelapp"
}
