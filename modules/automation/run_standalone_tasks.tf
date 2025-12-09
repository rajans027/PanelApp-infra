resource "aws_ssm_document" "run_standalone_tasks" {
  name            = "${var.name.ws_product}-run-standalone-tasks"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description = templatefile("${path.module}/documentation/run_standalone_tasks.md", {
      env          = var.env_name
      tf_workspace = terraform.workspace
      choices      = "`${join("`, `", keys(var.standalone_tasks))}`"
    })
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    parameters = {
      Task = {
        type          = "String"
        allowedValues = keys(var.standalone_tasks)
        description   = "(Required) Which task to run; one of \"${join("\", \"", keys(var.standalone_tasks))}\"."
        default       = "collect_static"
      }
    }
    variables = {
      taskArn = {
        type = "String"
      }
    }
    mainSteps = concat(
      [
        {
          name   = "Branch"
          action = "aws:branch"
          inputs = {
            Choices = [
              for k in keys(var.standalone_tasks) :
              {
                NextStep     = "Select_${k}"
                Variable     = "{{ Task }}"
                StringEquals = k
              }
            ]
            Default = "Select_collect_static"
          }
        },
      ],
      [
        for k, v in var.standalone_tasks :
        {
          name     = "Select_${k}"
          action   = "aws:updateVariable"
          nextStep = "RunStandaloneTask"
          inputs = {
            Name  = "variable:taskArn"
            Value = v.arn
          }
        }
      ],
      [
        {
          name        = "RunStandaloneTask"
          action      = "aws:executeScript"
          description = "Run PanelApp standalone task"
          inputs = {
            Runtime = "python3.11"
            Handler = "handler"
            Script  = file("${path.module}/scripts/run_task.py")
            InputPayload = {
              cluster         = var.ecs_cluster
              task_arn        = "{{ variable:taskArn }}"
              subnets         = data.aws_subnets.vpc.ids
              security_groups = [var.ecs_security_group_id]
              execution_id    = "ssm:automation:{{ automation:EXECUTION_ID }}"
            }
          }
        }
      ],
    )
  })
}

data "aws_subnets" "vpc" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}
