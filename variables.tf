###############################################################
# Global
###############################################################

variable "region" {
  type        = string
  default     = "ca-central-1"
}

variable "env_name" {
  type        = string
  description = "Environment (dev, test, prod)"
}

variable "project_name" {
  type        = string
  description = "Project name for ECS, ALB, logs"
}

variable "service_name" {
  type        = string
  description = "Application/service base name (example: panelapp)"
}

variable "account_id" {
  type = string
}

###############################################################
# DNS – nested structured object (required by CloudFront + Route53)
###############################################################

variable "dns" {
  description = "DNS configuration for internal + external zones"
  type = object({
    app = object({
      internal = string
      external = string
    })
    media = object({
      internal = string
      external = string
    })
    static = object({
      internal = string
      external = string
    })
    zone = object({
      internal = string
      external = string
    })
  })
}

###############################################################
# ECS Task CPU/Memory
###############################################################

variable "task" {
  description = "CPU and memory overrides per ECS task family"
  type = map(object({
    cpu    = number
    memory = number
  }))
}

###############################################################
# Domains / CDN Aliases
###############################################################

variable "app_domain"    { type = string }
variable "media_domain"  { type = string }
variable "static_domain" { type = string }

variable "media_cdn_alias"  { type = string }
variable "static_cdn_alias" { type = string }
variable "cdn_alias"        { type = string }

###############################################################
# Docker Image
###############################################################

variable "docker_image" {
  type = string
}

###############################################################
# KMS
###############################################################

variable "kms_key_arn" {
  type        = string
  description = "KMS key used for SSM, logs, secrets"
}

###############################################################
# ECS Desired Counts
###############################################################

variable "panelapp_task_counts" {
  type = map(number)
}

###############################################################
# Django
###############################################################

variable "django_settings_module" { type = string }
variable "django_log_level"       { type = string }
variable "admin_email"            { type = string }

###############################################################
# WAF
###############################################################

variable "waf_is_blocking" { type = bool }

variable "waf_rate_limits" {
  type = object({
    web = object({
      per_ip = number
      global = number
    })
    api = object({
      per_ip = number
      global = number
    })
  })
}

variable "api_url_regex" {
  type    = string
  default = "(/api|/health)"
}

###############################################################
# Cloudflare IPv6 support for CloudFront WAF
###############################################################

variable "cloudflare_ipv6" {
  description = "IPv6 CIDR blocks for Cloudflare CDN"
  type        = list(string)
}

###############################################################
# Database connection
###############################################################

variable "database" {
  type = object({
    writer_endpoint     = string
    port                = number
    name                = string
    user                = string
    master_password_arn = string
  })
}

###############################################################
# Email
###############################################################

variable "email" {
  type = object({
    email_sender  = string
    email_contact = string
    smtp_server   = string
    smtp_port     = number
  })
}

###############################################################
# Django App Config
###############################################################

variable "django" {
  type = object({
    log_level       = string
    settings_module = string
  })
}

###############################################################
# S3 Buckets
###############################################################

variable "buckets" {
  type = object({
    statics = object({ name = string })
    media   = object({ name = string })
  })
}

###############################################################
# App Runtime Settings
###############################################################

variable "panelapp" {
  type = object({
    workers            = number
    connection_timeout = number
    access_log         = string
  })
}

###############################################################
# Cron / Scheduled Tasks
###############################################################

variable "scheduled_tasks" {
  type = object({
    tasks = list(string)
    config = object({
      moi_check_day_of_week = string
    })
  })
}

###############################################################
# Secrets
###############################################################

variable "omim_api_key_arn"   { type = string }
variable "omim_api_key_value" { type = string }

###############################################################
# CloudFront Certificates
###############################################################

variable "certificate_arns" {
  description = "ACM certificates used by CloudFront"
  type = object({
    media   = string
    statics = string
  })
}

###############################################################
# Logging Buckets (CloudFront + WAF)
###############################################################

variable "bucket_name" {
  type        = string
  description = "Base name for all S3 log buckets"
}

###############################################################
# Logging retention for Aurora PostgreSQL
###############################################################

variable "log_retention" {
  type        = number
  default     = 30
  description = "CloudWatch retention period (days) for RDS logs"
}

###############################################################
# Backup Tags (optional)
###############################################################

variable "backup_tags" {
  type        = map(string)
  default     = {}
  description = "Optional backup-related tags for buckets"
}

###############################################################
# Networking
###############################################################

variable "vpc_id" {
  type        = string
  description = "VPC ID for ALB, ECS, and Aurora SGs"
}

###############################################################
# Sidecar Containers
###############################################################

variable "side_cars" {
  type = object({
    fluentbit = string
  })
}

###############################################################
# Optional Toggles
###############################################################

variable "enable_graphiql" {
  type    = bool
  default = true
}

variable "session_cookie_age" {
  type    = number
  default = 28800
}

###############################################################
# IAM
###############################################################

variable "permissions_boundary" {
  type = string
}

###############################################################
# Aurora / RDS
###############################################################

variable "cluster_size" {
  type        = number
  description = "Aurora cluster instance count"
}

variable "instance_class" {
  type        = string
  description = "Aurora instance class"
}

variable "engine_version" {
  type = string
}

variable "auto_minor_version_upgrade" {
  type = bool
}

variable "snapshot_identifier" {
  type        = string
  default     = ""
}

variable "trusted_accounts" {
  type        = list(string)
  default     = []
}

variable "extra_tags" {
  type        = map(string)
  default     = {}
}

variable "create_mgmt_box" {
  type    = bool
  default = false
}
