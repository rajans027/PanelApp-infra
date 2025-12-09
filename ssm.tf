##############################################
# OMIM API KEY (SSM SecureString)
##############################################

resource "aws_ssm_parameter" "omim_api_key" {
  name        = "/${var.project_name}/${var.env_name}/omim_api_key"
  description = "OMIM API key"
  type        = "SecureString"
  key_id      = var.kms_key_arn

  # Replace this with actual secret value through tfvars for non-prod
  value = var.omim_api_key_value

  lifecycle {
    ignore_changes = [
      value, # prevent drift if updated manually
    ]
  }
}

##############################################
# RANDOM DJANGO ADMIN URL (SecureString)
##############################################

resource "random_id" "django_admin_url" {
  byte_length = 16
}

resource "aws_ssm_parameter" "django_admin_url" {
  name        = "/${var.project_name}/${var.env_name}/django/admin_url"
  description = "Django secret admin URL"
  type        = "SecureString"
  key_id      = var.kms_key_arn
  value       = "${random_id.django_admin_url.b64_url}/"
}

##############################################
# PANELAPP BANNER (String)
##############################################

resource "aws_ssm_parameter" "panelapp_banner" {
  name        = "/${var.project_name}/${var.env_name}/application/banner"
  description = "Banner message for PanelApp. Automatically generated; DO NOT MODIFY."
  type        = "String"

  # Cannot be empty; PanelApp strips whitespace internally.
  value = " "

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}


###############################################################
# RDS Snapshot Metadata Parameter  
# Stores the name of the most recently loaded or saved snapshot
###############################################################

resource "aws_ssm_parameter" "rds_snapshot" {
  name        = "/${var.project_name}/${var.env_name}/rds/snapshot"
  description = "Name of the most recently loaded or saved snapshot (excluding automated backups). Data may have changed since this snapshot was used."

  type  = "String"
  value = "no snapshot loaded"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
