variable "env_name" {
  type = string
}

variable "rds_snapshot" {
  type    = string
  default = ""
}

variable "instance_class" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cluster_size" {
  type    = number
  default = 1
}

variable "auto_minor_version_upgrade" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "database" {
  type    = string
  default = ""
}

variable "username" {
  type    = string
  default = ""
}

variable "master_password" {
  type    = string
  default = ""
}

variable "engine_version" {
  type        = string
  description = "postgres version"
}

variable "cluster_parameter_group_family" {
  type    = string
  default = "aurora-postgresql14"
}

variable "preferred_maintenance_window" {
  type        = string
  description = "maintenance window for minor version updates"
}

variable "trusted_accounts" {
  type        = list(string)
  description = "List accounts allowed to access RDS KMS key"
}

variable "extra_tags" {
  type        = map(string)
  description = "Tags to be added to resources"
  default     = {}
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
