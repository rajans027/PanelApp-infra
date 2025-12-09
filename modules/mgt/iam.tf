resource "aws_iam_instance_profile" "mgt_session" {
  name = "${var.name.ws_product}-mgt_session"
  role = aws_iam_role.mgt_session.name
}

resource "aws_iam_role" "mgt_session" {
  name                 = "${var.name.ws_product}-mgt_session"
  permissions_boundary = local.permissions_boundary

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    }
  )
}

## policies
resource "aws_iam_role_policy_attachment" "mgt_session_ssm" {
  role       = aws_iam_role.mgt_session.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "mgt_session" {
  role       = aws_iam_role.mgt_session.name
  policy_arn = aws_iam_policy.mgt_session.arn
}

resource "aws_iam_policy" "mgt_session" {
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        ## Redundant because of AmazonEC2RoleforSSM
        # {
        #   Action   = "s3:ListBucket"
        #   Effect   = "Allow"
        #   Resource = "arn:aws:s3:::${var.artifacts_bucket}"
        # },
        # {
        #   Action   = "s3:GetObject"
        #   Effect   = "Allow"
        #   Resource = "arn:aws:s3:::${var.artifacts_bucket}/*"
        # },
        ## Necessary because of AmazonEC2RoleforSSM
        {
          Sid    = "DenyTerraform"
          Action = "s3:*"
          Effect = "Deny"
          Resource = [
            "arn:aws:s3:::${data.aws_caller_identity.current.account_id}-terraform",
            "arn:aws:s3:::${data.aws_caller_identity.current.account_id}-terraform/*",
          ]
        },
        {
          Sid      = "GetDBPassword"
          Effect   = "Allow"
          Action   = "ssm:GetParameters"
          Resource = "arn:aws:ssm:eu-west-2:577192787797:parameter/panelapp/database/master_password"
        },
        {
          Sid    = "ECRPermissions"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
          ]
          Resource = "arn:aws:ecr:eu-west-2:577192787797:repository/panelapp"
        },
        {
          Sid      = "ECRAccessToken"
          Effect   = "Allow"
          Action   = "ecr:GetAuthorizationToken"
          Resource = "*"
        },
        {
          Action = [
            "kms:Decrypt",
            "kms:Describe*",
            "kms:Encrypt",
            "kms:GenerateDataKey*",
            "kms:ReEncrypt*",
          ],
          Effect   = "Allow"
          Resource = var.ebs_key_arn
        }
      ]
    }
  )
}
