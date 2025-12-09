variable "env_name" {
  type        = string
  description = "Name of the environment"
  validation {
    condition     = can(regex("^(dev|test|e2e|uat|prod)$", var.env_name))
    error_message = "Invalid value for env_name"
  }
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

variable "default_tags" {
  description = "Default tags"
  type        = map(string)
}

variable "backup_tags" {
  description = "Tags for automatic backup module"
  type        = map(string)
}

variable "boundary_policy_arn" {
  type        = string
  description = "ARN of the policy to use as a boundary for the IAM role"
}

variable "ecs_task_iam_role_arn" {
  type = string
}

variable "ecs_cluster" {
  type        = string
  description = "Name of the cluster to run tasks on"
}

variable "standalone_tasks" {
  description = "aws_ecs_task_definitions[]"
}

variable "ecs_services" {
}

variable "ecs_security_group_id" {
  type        = string
  description = "ID of security group"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC"
}

variable "ssm_parameters" {
  type = object({
    panelapp_banner = object({
      name = string
      arn  = string
    })
    aurora_snapshot = object({
      name = string
      arn  = string
    })
  })
}

variable "aurora" {
  type = object({
    cluster = object({
      name = string
      arn  = string
    })
    parameter_groups = object({
      read-only = object({
        name = string
        arn  = string
      })
      read-write = object({
        name = string
        arn  = string
      })
    })
    accounts_to_share_with = list(string)
    accounts_to_copy_from  = list(string)
    encryption_key_arn     = string
    decryption_key_arns    = list(string)
  })
}

variable "email" {
  type = object({
    contact = string
  })
}

variable "log_groups" {
  type = object({
    ensembl_id_update = string
  })
}

variable "athena" {
  type = object({
    sql_queries = list(string)
    database = object({
      name = string
      arn  = string
    })
    catalog = object({
      name = string
      arn  = string
    })
    workgroup = object({
      name = string
      arn  = string
    })
    tables = list(object({
      name = string
      arn  = string
    }))
    result_bucket = object({
      arn  = string
      name = string
    })
  })
}
