variable "name" {
  type = object({
    product        = string
    ws_product     = string
    ws_env_product = string
    bucket         = string
  })
  description = "Workspace aware name parts"
}

# Launch template
variable "instance_type" {
  type        = string
  description = "The size of instance to launch"
  default     = ""
}

variable "ebs_key_arn" {
  type        = string
  description = "KMS key for ebs encryption"
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "id of the vpc"
  default     = "default value"
}

variable "artifacts_bucket" {
  type = string
}

# docker-compose.yml panelapp
variable "image_name" {
  type    = string
  default = ""
}

variable "database_host" {
  type    = string
  default = ""
}

variable "database_port" {
  type    = string
  default = ""
}

variable "database_name" {
  type    = string
  default = ""
}

variable "database_user" {
  type    = string
  default = ""
}

variable "panelapp_statics" {
  type    = string
  default = ""
}

variable "panelapp_media" {
  type    = string
  default = ""
}

variable "cdn_domain_name" {
  type    = string
  default = ""
}

variable "tags" {
  type        = map(string)
  description = "tags to push to generated resources"
}

variable "django_settings_module" {
  type    = string
  default = ""
}
