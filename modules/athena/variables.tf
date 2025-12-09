variable "alb_logs_bucket" {
  description = "S3 location of ALB access logs"
  type = object({
    name = string
    arn  = string
  })
}

variable "waf_logs_bucket" {
  description = "S3 location of WAF logs"
  type = object({
    name = string
    arn  = string
  })
}

variable "cloudfront_logs_bucket" {
  description = "S3 location of CloudFront logs"
  type = object({
    name = string
    arn  = string
  })
}

variable "alb_waf" {
  description = "Name of WAF used by ALB"
  type = object({
    name = string
  })
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
