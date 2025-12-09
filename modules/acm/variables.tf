variable "env_name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "public_zone_id" {
  type = string
}

variable "create_cloudfront_cert" {
  type    = bool
  default = false
}

variable "create_regional_cert" {
  type    = bool
  default = false
}


variable "dns_record" {
  type = string
}
