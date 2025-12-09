resource "aws_ssm_document" "rds_create_snapshot" {
  name            = "${var.name.ws_product}-rds-create-snapshot"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description = templatefile("${path.module}/documentation/rds_create_snapshot.md", {
      env          = var.env_name
      tf_workspace = terraform.workspace
      services     = keys(var.ecs_services)
    })
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    parameters = {
      Release = {
        type           = "String"
        default        = "ad-hoc"
        allowedPattern = "^[a-z]([a-z0-9]+-)*[a-z0-9]+$"
        description    = "Release name as part of the snapshot, e.g. \"nembus-inc-1\"; must only contain lower case letters, digits, and hyphens."
      }
    }
    variables = {
      snapshot = {
        type = "String"
      }
    }
    mainSteps = [
      {
        name        = "SnapshotMetadata"
        action      = "aws:executeScript"
        description = "Create a snapshot-compatible name"
        nextStep    = "CreateDBClusterSnapshot"
        isEnd       = false
        inputs = {
          Runtime = "python3.11"
          Handler = "handler"
          InputPayload = {
            db_cluster = var.aurora.cluster.name
            release    = "{{ Release }}"
          }
          Script = file("${path.module}/scripts/snapshot_name.py")
        }
        outputs = [
          {
            Name     = "name"
            Selector = "$.Payload.name"
            Type     = "String"
          }
        ]
      },
      {
        name     = "CreateDBClusterSnapshot"
        action   = "aws:executeAwsApi"
        nextStep = "PutParameter"
        isEnd    = false
        inputs = {
          Service                     = "rds"
          Api                         = "CreateDBClusterSnapshot"
          DBClusterSnapshotIdentifier = "{{ SnapshotMetadata.name }}"
          DBClusterIdentifier         = var.aurora.cluster.name
          Tags = [
            for k, v in merge(var.default_tags, { Provisioner = "ssm:automation:{{ automation:EXECUTION_ID }}" }) :
            { Key = k, Value = v }
          ]
        }
      },
      {
        name     = "PutParameter"
        action   = "aws:executeAwsApi"
        nextStep = "WaitOnAWSResourceProperty"
        isEnd    = false
        inputs = {
          Service   = "ssm"
          Api       = "PutParameter"
          Name      = var.ssm_parameters.aurora_snapshot.name
          Value     = "{{ SnapshotMetadata.name }}"
          Type      = "String"
          Overwrite = true
          Tier      = "Standard"
          DataType  = "text"
        }
      },
      {
        name     = "WaitOnAWSResourceProperty"
        action   = "aws:waitForAwsResourceProperty"
        nextStep = "ModifyDBClusterSnapshotAttribute"
        isEnd    = false
        inputs = {
          Service                     = "rds"
          Api                         = "DescribeDBClusterSnapshots"
          DBClusterSnapshotIdentifier = "{{ SnapshotMetadata.name }}"
          PropertySelector            = "DBClusterSnapshots[0].Status"
          DesiredValues = [
            "available"
          ]
        }
      },
      {
        "name" : "ModifyDBClusterSnapshotAttribute",
        "action" : "aws:executeAwsApi",
        "isEnd" : true,
        "inputs" : {
          "Service" : "rds",
          "Api" : "ModifyDBClusterSnapshotAttribute",
          "DBClusterSnapshotIdentifier" : "{{ SnapshotMetadata.name }}",
          "AttributeName" : "restore",
          "ValuesToAdd" : var.aurora.accounts_to_share_with
        }
      }
    ]
    outputs = ["SnapshotMetadata.name"]
  })
}
