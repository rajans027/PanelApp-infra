variable "repo_names" {
  type        = list(string)
  default     = []
  description = "List of repository names"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key for encryption"
}

variable "pull_trusted_accounts" {
  type        = list(string)
  description = "Accounts to allow to pull"
}

variable "push_pull_trusted_roles" {
  type        = list(string)
  description = ""
}

variable "permissions_boundary" {
  type = string
}

variable "backup_tags" {
  type = map(string)
}
