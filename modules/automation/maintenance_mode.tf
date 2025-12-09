resource "aws_ssm_document" "maintenance_mode" {
  name            = "${var.name.ws_product}-maintenance-mode"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description = templatefile("${path.module}/documentation/maintenance_mode.md", {
      banner       = local.maintenance_mode_banner
      env          = var.env_name
      tf_workspace = terraform.workspace
    })
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    parameters = {
      MaintenanceMode = {
        type = "String"
        allowedValues = [
          "on",
          "off"
        ],
        default       = "off"
        allowedValues = ["on", "off"]
        description   = "Mode of operation"
      }
    }
    variables = {
      bannerAction = {
        type    = "String"
        default = "add"
      }
      parameterGroup = {
        type    = "String"
        default = var.aurora.parameter_groups.read-only.name
      }
    },
    mainSteps = [
      {
        name   = "Branch"
        action = "aws:branch"
        inputs = {
          Choices = [
            {
              NextStep     = "SelectBannerAction"
              Variable     = "{{ MaintenanceMode }}"
              StringEquals = "off"
            }
          ],
          Default = "ChangeBanner"
        }
      },
      {
        name     = "SelectBannerAction"
        action   = "aws:updateVariable"
        nextStep = "SelectParameterGroup"
        inputs = {
          Name  = "variable:bannerAction"
          Value = "remove"
        }
      },
      {
        name     = "SelectParameterGroup"
        action   = "aws:updateVariable"
        nextStep = "ChangeBanner"
        inputs = {
          Name  = "variable:parameterGroup"
          Value = var.aurora.parameter_groups.read-write.name
        }
      },
      {
        name        = "ChangeBanner"
        action      = "aws:executeScript"
        description = "Change the banner"
        inputs = {
          Runtime = "python3.11"
          Handler = "handler"
          InputPayload = {
            action        = "{{ variable:bannerAction }}"
            banner        = local.maintenance_mode_banner
            ssm_parameter = var.ssm_parameters.panelapp_banner.name
            cluster       = var.ecs_cluster
            web_service   = var.ecs_services.web.name
          }
          Script = file("${path.module}/scripts/panelapp_banner.py")
        }
        outputs = [
          {
            Name     = "newBanners"
            Selector = "$.Payload.Banners"
            Type     = "String"
          }
        ]
      },
      {
        name        = "AuroraClusterMode"
        action      = "aws:executeAwsApi"
        description = "Use cluster parameter group '{{ variable:parameterGroup }}' to change Aurora cluster"
        inputs = {
          Service                     = "rds"
          Api                         = "ModifyDBCluster"
          DBClusterIdentifier         = var.aurora.cluster.name
          DBClusterParameterGroupName = "{{ variable:parameterGroup }}"
        }
      }
    ]
  })
}
