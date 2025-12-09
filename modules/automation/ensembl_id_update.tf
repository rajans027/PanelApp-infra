resource "aws_ssm_document" "ensembl_id_update" {
  name            = "${var.name.ws_product}-ensembl-id-update"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description = templatefile("${path.module}/documentation/ensembl_id_update.md", {
      env           = var.env_name
      tf_workspace  = terraform.workspace
      upload_bucket = aws_s3_bucket.upload.bucket
      log_bucket    = aws_s3_bucket.artifacts.bucket
      log_group     = var.log_groups.ensembl_id_update
    })
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    parameters = {
      Data = {
        type           = "String"
        default        = ""
        allowedPattern = "^(| *\\{.*\\} *)$"
        displayType    = "textarea"
        description    = "(Either) Ensembl ID gene data update as JSON"
      }
      Path = {
        type        = "String"
        default     = ""
        description = "(Or) Path to file in the S3 upload bucket ${aws_s3_bucket.upload.bucket}, containing the Ensembl ID gene data update as JSON"
      }
    }
    mainSteps = [
      {
        name        = "UploadData"
        action      = "aws:executeScript"
        description = "Upload to or find data in upload bucket"
        inputs = {
          Runtime = "python3.11"
          Handler = "handler"
          InputPayload = {
            input_bucket  = aws_s3_bucket.upload.bucket
            output_bucket = aws_s3_bucket.artifacts.bucket
            data_path     = "{{ Path }}"
            data_string   = "{{ Data }}"
            execution_id  = "ssm:automation:{{ automation:EXECUTION_ID }}"
          }
          Script = file("${path.module}/scripts/ensembl_id_data_file_upload.py")
        }
        outputs = [
          {
            Name     = "outputPath"
            Selector = "$.Payload.output_path"
            Type     = "String"
          },
          {
            Name     = "inputPath"
            Selector = "$.Payload.input_path"
            Type     = "String"
          }
        ]
      },
      {
        name        = "UpdateEnsemblId"
        action      = "aws:executeScript"
        description = "Run PanelApp standalone task"
        inputs = {
          Runtime = "python3.11"
          Handler = "handler"
          Script  = file("${path.module}/scripts/run_task.py")
          InputPayload = {
            cluster         = var.ecs_cluster
            task_arn        = var.standalone_tasks.ensembl_id_update.arn
            subnets         = data.aws_subnets.vpc.ids
            security_groups = [var.ecs_security_group_id]
            execution_id    = "ssm:automation:{{ automation:EXECUTION_ID }}"
            environment = {
              INPUT_PATH  = "{{ UploadData.inputPath }}"
              OUTPUT_PATH = "{{ UploadData.outputPath }}"
            }
          }
        }
      }
    ]
  })
}
