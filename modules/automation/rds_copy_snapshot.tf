resource "aws_ssm_document" "rds_copy_snapshot" {
  name            = "${var.name.ws_product}-rds-copy-snapshot"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    description = templatefile("${path.module}/documentation/rds_copy_snapshot.md", {
      env          = var.env_name
      tf_workspace = terraform.workspace
      services     = keys(var.ecs_services)
    })
    schemaVersion = "0.3"
    assumeRole    = aws_iam_role.automation.arn
    parameters = {
      SnapshotArn = {
        type           = "String"
        allowedPattern = "arn:aws:rds:${data.aws_region.current.region}:.*"
        description    = "ARN of the shared snapshot to copy."
      }
    }
    variables = {
      targetSnapshotIdentifier = {
        type = "String"
      }
    }
    mainSteps = [
      {
        name        = "SnapshotMetadata"
        action      = "aws:executeScript"
        description = "Create target snapshot name"
        nextStep    = "CopyDBClusterSnapshot"
        isEnd       = false
        inputs = {
          Runtime = "python3.11"
          Handler = "handler"
          InputPayload = {
            source_snapshot_arn = "{{ SnapshotArn }}"
          }
          Script = file("${path.module}/scripts/target_snapshot_name.py")
        }
        outputs = [
          {
            Name     = "target_snapshot_name"
            Selector = "$.Payload.target_snapshot_name"
            Type     = "String"
          }
        ]
      },
      {
        name     = "CopyDBClusterSnapshot"
        action   = "aws:executeAwsApi"
        nextStep = "WaitOnAWSResourceProperty"
        isEnd    = false
        inputs = {
          Service                           = "rds"
          Api                               = "CopyDBClusterSnapshot"
          SourceDBClusterSnapshotIdentifier = "{{ SnapshotArn }}"
          TargetDBClusterSnapshotIdentifier = "{{ SnapshotMetadata.target_snapshot_name }}"
          KmsKeyId                          = var.aurora.encryption_key_arn
          Tags = [
            for k, v in merge(var.default_tags, { Provisioner = "ssm:automation:{{ automation:EXECUTION_ID }}" }) :
            { Key = k, Value = v }
          ]
        }
      },
      {
        name   = "WaitOnAWSResourceProperty"
        action = "aws:waitForAwsResourceProperty"
        isEnd  = true
        inputs = {
          Service                     = "rds"
          Api                         = "DescribeDBClusterSnapshots"
          DBClusterSnapshotIdentifier = "{{ SnapshotMetadata.target_snapshot_name }}"
          PropertySelector            = "DBClusterSnapshots[0].Status"
          DesiredValues = [
            "available"
          ]
        }
      }
    ]
    outputs = ["SnapshotMetadata.target_snapshot_name"]
  })
}
