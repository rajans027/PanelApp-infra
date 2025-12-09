resource "aws_ssm_document" "restart_services" {
  name            = "${var.name.ws_product}-restart-services"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description = templatefile("${path.module}/documentation/restart_services.md", {
      env          = var.env_name
      tf_workspace = terraform.workspace
      services     = keys(var.ecs_services)
    })
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    parameters = {
      Action = {
        type          = "String"
        default       = "start"
        allowedValues = ["start", "stop"]
        description   = "What to do with the selected service"
      }
      Service = {
        type          = "String"
        default       = "all"
        allowedValues = concat(["all"], keys(var.ecs_services))
        description   = "Which service to start/re-start or stop"
      }
    }
    mainSteps = [
      {
        name        = "UpdateServices"
        action      = "aws:executeScript"
        description = "Update services' task count"
        inputs = {
          Runtime = "python3.11"
          Handler = "handler"
          InputPayload = {
            action       = "{{ Action }}"
            service      = "{{ Service }}"
            cluster      = var.ecs_cluster
            all_services = var.ecs_services
          }
          Script = file("${path.module}/scripts/restart_services.py")
        }
        outputs = [for service in keys(var.ecs_services) :
          {
            Name     = service
            Selector = "$.Payload.${service}"
            Type     = "StringMap"
          }
        ]
      }
    ]
    outputs = [for service in keys(var.ecs_services) : "UpdateServices.${service}"]
  })
}
