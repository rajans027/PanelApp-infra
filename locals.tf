# locals {
#   is_default_ws       = terraform.workspace == "default"  #default is being used for production
#   is_default_ws_count = local.is_default_ws ? 1 : 0
#   ws_dash_prefix      = local.is_default_ws ? "" : "${terraform.workspace}-"
#   ws_dot_prefix       = local.is_default_ws ? "" : "${terraform.workspace}."


#   permissions_boundary = "arn:aws:iam::${var.account_id}:policy/GELBoundary"

#   _product_name           = "panelapp"
#   _product_name_env       = "${local._product_name}-${var.env_name}"
#   _product_name_external  = (var.env_name == "prod") ? local._product_name : local._product_name_env
#   _internal_dns_zone_name = "aws.gel.ac" #change this to your organisation's internal domain 
#   _external_dns_zone_name = "genomicsengland.co.uk" #change this to your organisation's domain
  
#   dns = {
#     zone = {
#       internal = local._internal_dns_zone_name
#       external = local._external_dns_zone_name
#     }
#     app = {
#       internal = "${local.ws_dot_prefix}${local._product_name_env}" #panelapp-dev 
#       external = "${local.ws_dot_prefix}${local._product_name_external}"
#     }
#     media = {
#       external = "${local.ws_dot_prefix}${var.env_name}-media-${local._product_name}"
#     }
#     static = {
#       external = "${local.ws_dot_prefix}${var.env_name}-static-${local._product_name}"
#     }
#   }
#   email = {
#     sender  = "${local._product_name_external}@${local.dns.zone.external}"
#     contact = "${local._product_name_external}@${local.dns.zone.external}"
#   }

#   name = {
#     product        = local._product_name
#     ws_product     = "${local.ws_dash_prefix}${local._product_name}"
#     ws_env_product = "${local.ws_dash_prefix}${var.env_name}-${local._product_name}"
#     bucket         = "${var.account_id}-${local.ws_dash_prefix}${local._product_name}"
#   }

#   datadog_tags = merge(
#     module.aws_tags.tags,
#     {
#       infra : "aws"
#       service : module.aws_tags.service,
#       version : var.image_tag,
#     }
#   )

#   ecr_registry            = "577192787797.dkr.ecr.eu-west-2.amazonaws.com"
#   ecr_registry_account_id = "577192787797"

#   ecr_pull_trusted_accounts = [
#     "577192787797", # panelapp_dev
#     "455662437776", # panelapp_test
#     "875605549679", # panelapp_e2e
#     "400119055163", # panelapp_uat
#     "876663091628", # panelapp_prod
#   ]
#   ecr_push_pull_trusted_roles = [
#     "arn:aws:iam::577192787797:role/CIDeploypanelapp",
#   ]

#   core_security_account = "157651656631"
#   kms_key_arn = {
#     prod = "arn:aws:kms:${data.aws_region.current.region}:${local.core_security_account}:key/c0c76a0d-0bbb-4341-888e-f2bd66d981f7"
#     uat  = "arn:aws:kms:${data.aws_region.current.region}:${local.core_security_account}:key/55715a10-1f96-444c-990e-b88c28ad97b4"
#     e2e  = "arn:aws:kms:${data.aws_region.current.region}:${local.core_security_account}:key/e65e078d-3bff-4632-aa96-927f93f7b86b"
#     # same as test
#     test = "arn:aws:kms:${data.aws_region.current.region}:${local.core_security_account}:key/e65e078d-3bff-4632-aa96-927f93f7b86b"
#     dev  = "arn:aws:kms:${data.aws_region.current.region}:${local.core_security_account}:key/12bcd425-b07e-4dcb-a7c1-aaefaeb6b0ea"
#     }[
#     var.env_name
#   ]

#   admin_access = tolist(data.aws_iam_roles.admin_role.arns)[0]

#   rds_share_snapshot_trusted_accounts = {
#     dev  = "577192787797", # panelapp_dev
#     test = "455662437776", # panelapp_test
#     e2e  = "875605549679", # panelapp_e2e
#     uat  = "400119055163", # panelapp_uat
#     prod = "876663091628", # panelapp_prod
#   }
#   # FIXME: should not reference generated resources in other accounts
#   rds_key_arns = {
#     dev  = "arn:aws:kms:eu-west-2:577192787797:key/92d760cd-e2fa-437a-b776-bb4833eed874"
#     test = "arn:aws:kms:eu-west-2:455662437776:key/4e6bf5cb-8638-4536-8368-e4eec642c635"
#     e2e  = "arn:aws:kms:eu-west-2:875605549679:key/6e381286-1e06-4a18-b6ad-adc8713697cb"
#     uat  = "arn:aws:kms:eu-west-2:400119055163:key/5552c181-21a3-4ba2-aece-50f963590fc0"
#     prod = "arn:aws:kms:eu-west-2:876663091628:key/30232649-0512-4ace-97db-fc9dedb22533"
#   }

#   backup_tags = local.is_default_ws ? {
#     aws_backup_plan_daily   = "panelapp_daily"
#     aws_backup_plan_weekly  = "panelapp_weekly"
#     aws_backup_plan_monthly = "panelapp_monthly"
#   } : {}

#   django_settings_module = "panelapp.settings.docker-aws"
# }
