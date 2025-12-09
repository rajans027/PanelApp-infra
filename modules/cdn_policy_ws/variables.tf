variable "bucket" {
  type = object({
    name = string
    arn  = string
  })
}

variable "service_role" {
  type = string
}

variable "distribution_arn" {
  type = string
}
