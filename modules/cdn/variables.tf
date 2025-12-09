variable "dns" {
  description = "DNS parts"
  type = object({
    zone = object({
      internal = string
      external = string
    })
    app = object({
      internal = string
      external = string
    })
    media = object({
      external = string
    })
    static = object({
      external = string
    })
  })
}

variable "certificate_arns" {
  type = object({
    media   = string
    statics = string
  })
}

variable "backup_tags" {
  description = "Tags for automatic backup module"
  type        = map(string)
}

variable "name" {
  type = object({
    product        = string
    ws_product     = string
    ws_env_product = string
    bucket         = string
  })
  description = "Workspace aware name parts"
}
