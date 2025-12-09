variable "env_name" {
  type        = string
  description = "Environment name"
}

variable "media_cdn_alias" {
  type = string
}

variable "static_cdn_alias" {
  type = string
}

variable "application_version" {
  type = string
}

variable "cdn_alias" {
  type = string
}

variable "ecs_services" {
  type = map(object({
    name          = string,
    desired_count = number
  }))
}

variable "tags" {
  type = map(string)
}
