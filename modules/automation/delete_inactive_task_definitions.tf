resource "aws_ssm_document" "delete_inactive_task_definitions" {
  name            = "${var.name.ws_product}-delete-inactive-task-definitions"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description   = "Delete all inactive ECS task definitions in this account."
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    mainSteps = [
      {
        name        = "DeleteInactiveTaskDefs"
        action      = "aws:executeScript"
        description = "Delete inactive task definitions"
        inputs = {
          Runtime = "python3.11"
          Handler = "handler"
          Script  = file("${path.module}/scripts/delete_inactive_task_definitions.py")
        }
      }
    ]
  })
}
