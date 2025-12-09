variable "env_name" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "name" {
  type = object({
    product        = string
    ws_product     = string
    ws_env_product = string
    #    dns            = string
    bucket = string
  })
  description = "Workspace aware name parts"
}

variable "vpc_id" {
  type = string
}

variable "cdn_alias" {
  type        = string
  description = "CDN alias"
}

variable "static_cdn_alias" {
  type        = string
  description = "CDN alias"
}

variable "media_cdn_alias" {
  type        = string
  description = "CDN alias"
}

variable "gmspanels_url" {
  type = string
}

variable "certificate_arn" {
  type        = string
  description = "Regional Certificate ARN"
}
variable "task" {
  type = map(object({
    cpu    = number
    memory = number
  }))
}
variable "database" {
  type = object({
    writer_endpoint     = string
    port                = number
    name                = string
    user                = string
    master_password_arn = string
  })
}

variable "session" {
  type = object({
    cookie_age = number
  })
}

variable "enable_graphiql" {
  description = "Enable GraphiQL interface"
  type        = bool
  default     = true
}

variable "email" {
  type = object({
    email_sender  = string
    email_contact = string
    smtp_server   = string
    smtp_port     = number
  })
}


variable "django" {
  type = object({
    log_level       = string
    settings_module = string
    admin_email     = string
  })
}

variable "panelapp" {
  type = object({
    tasks = object({
      web    = number
      worker = number
    })
    workers            = number
    connection_timeout = number
    access_log         = string
  })
}

variable "buckets" {
  type = object({
    statics   = object({ name = string, arn = string })
    media     = object({ name = string, arn = string })
    upload    = object({ name = string, arn = string })
    artifacts = object({ name = string, arn = string })
  })
}

variable "datadog_tags_map" {
  type = map(string)
}

variable "kms_key_arn" {
  type = string
}

variable "docker_image" {
  type = string
}

variable "scheduled_tasks" {
  type = object({
    tasks  = list(string)
    config = map(string)
  })
}

variable "side_cars" {
  description = "Fully qualified repository:version of side cars"
  type = object({
    datadog_agent = string
    fluentbit     = string
  })
}

variable "waf_is_blocking" {
  description = "Block traffic"
  type        = bool
  default     = true
}

variable "waf_rate_limits" {
  description = "WAF rate limits per 1-minute sliding window"
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

