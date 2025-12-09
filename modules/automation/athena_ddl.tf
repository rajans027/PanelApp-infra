resource "aws_ssm_document" "athena_ddl" {
  name            = "${var.name.ws_product}-athena-ddl"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description = templatefile("${path.module}/documentation/athena_ddl.md",
      {
        env                  = var.env_name
        tf_workspace         = terraform.workspace
        region               = data.aws_region.current.region
        athena_result_bucket = var.athena.result_bucket.name
    })
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    mainSteps = [
      {
        name        = "ForEachView"
        action      = "aws:loop"
        description = "Loop to create views"
        inputs = {
          Iterators = var.athena.sql_queries
          Steps = [
            {
              name      = "StartQueryExecution",
              action    = "aws:executeAwsApi",
              nextStep  = "WaitOnAWSResourceProperty",
              isEnd     = false,
              onFailure = "Abort",
              inputs = {
                WorkGroup = var.athena.workgroup.name
                QueryExecutionContext = {
                  Catalog  = var.athena.catalog.name
                  Database = var.athena.database.name
                },
                QueryString = "{{ ForEachView.CurrentIteratorValue }}",
                Service     = "athena",
                Api         = "StartQueryExecution"
              },
              outputs = [
                {
                  Type     = "String",
                  Name     = "QueryExecutionId",
                  Selector = "$.QueryExecutionId"
                }
              ]
            },
            {
              name     = "WaitOnAWSResourceProperty",
              action   = "aws:waitForAwsResourceProperty",
              nextStep = "GetQueryExecution",
              isEnd    = false,
              inputs = {
                Service = "athena",
                Api     = "GetQueryExecution",
                DesiredValues = [
                  "SUCCEEDED",
                  "FAILED",
                  "CANCELLED"
                ],
                PropertySelector = "QueryExecution.Status.State",
                QueryExecutionId = "{{ StartQueryExecution.QueryExecutionId }}"
              }
            },
            {
              name     = "GetQueryExecution",
              action   = "aws:executeAwsApi",
              nextStep = "AssertAWSResourceProperty",
              isEnd    = false,
              inputs = {
                Service          = "athena",
                Api              = "GetQueryExecution",
                QueryExecutionId = "{{ StartQueryExecution.QueryExecutionId }}"
              },
              outputs = [
                {
                  Type     = "StringMap",
                  Name     = "Status",
                  Selector = "$.QueryExecution.Status"
                }
              ]
            },
            {
              name   = "AssertAWSResourceProperty",
              action = "aws:assertAwsResourceProperty",
              isEnd  = true,
              inputs = {
                Service = "athena",
                Api     = "GetQueryExecution",
                DesiredValues = [
                  "SUCCEEDED"
                ],
                PropertySelector = "QueryExecution.Status.State",
                QueryExecutionId = "{{ StartQueryExecution.QueryExecutionId }}"
              }
            },
          ]
        }
      }
    ]
  })
}
