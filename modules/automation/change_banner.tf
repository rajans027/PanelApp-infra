resource "aws_ssm_document" "banner" {
  name            = "${var.name.ws_product}-change-banner"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description = templatefile("${path.module}/documentation/change_banner.md",
      {
        env          = var.env_name
        tf_workspace = terraform.workspace
    })
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    parameters = {
      Banner = {
        type        = "String"
        description = "(Required) The banner to add or to remove. Must be an exact match when removing the banner."
      }
      Mode = {
        type = "String"
        allowedValues = [
          "add",
          "remove"
        ],
        default       = "add"
        allowedValues = ["add", "remove"]
        description   = "What to do with the banner"
      }
    }
    mainSteps = [
      {
        name        = "ChangeBanner"
        action      = "aws:executeScript"
        description = "Change the banner"
        inputs = {
          Runtime = "python3.11"
          Handler = "handler"
          InputPayload = {
            action        = "{{ Mode }}"
            banner        = "{{ Banner }}"
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
      }
    ]
    outputs = [
      "ChangeBanner.newBanners"
    ]
  })
}
