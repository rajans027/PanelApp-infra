##############################################
# FARGATE SECURITY GROUP
##############################################

resource "aws_security_group" "fargate" {
  name        = "${var.project_name}-${var.env_name}-fargate"
  description = "Security group for ${var.project_name} ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.env_name}-fargate"
    Application = "${var.project_name}-${var.env_name}"
  }
}

#################################################
# INGRESS FROM ALB TO FARGATE (PORT 8080)
#################################################

resource "aws_security_group_rule" "fargate_ingress_8080_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.fargate.id
  description              = "Allow ALB → ECS Fargate on port 8080"
}

#################################################
# EGRESS RULES FOR FARGATE
#################################################

resource "aws_security_group_rule" "fargate_smtp_egress" {
  type              = "egress"
  from_port         = 587
  to_port           = 587
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.fargate.id
  description       = "Allow outbound SMTP for SES"
}

resource "aws_security_group_rule" "fargate_https_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.fargate.id
  description       = "Allow outbound HTTPS"
}

##############################################
# IAM ROLE FOR ECS TASKS
##############################################

resource "aws_iam_role" "ecs_task_panelapp" {
  name = "${var.project_name}-${var.env_name}-tasks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeECSTaskRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.env_name}-tasks"
    Application = "${var.project_name}-${var.env_name}"
  }
}

##############################################
# IAM POLICY FOR ECS TASK PERMISSIONS
##############################################

resource "aws_iam_role_policy" "panelapp" {
  name = "${var.project_name}-${var.env_name}-task-policy"
  role = aws_iam_role.ecs_task_panelapp.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      ####################################
      # S3 – READ/WRITE Access
      ####################################
      {
        Sid    = "ReadWriteBucketObjects"
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:PutObject",
          "s3:HeadBucket"
        ]
        Resource = [
          "${var.buckets.media.name}/*",
          "${var.buckets.statics.name}/*",
        ]
      },

      {
        Sid    = "ReadBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          var.buckets.statics.name
        ]
      },

      ####################################
      # SQS
      ####################################
      {
        Sid    = "ReadWriteQueue"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessageBatch",
          "sqs:SendMessageBatch",
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibilityBatch"
        ]
        Resource = "*"
      },

      {
        Sid    = "ListQueues"
        Effect = "Allow"
        Action = "sqs:ListQueues"
        Resource = "*"
      },

      ####################################
      # ECR (pull images)
      ####################################
      {
        Sid    = "ECRPull"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },

      ####################################
      # CloudWatch Logs
      ####################################
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },

      ####################################
      # SSM + SecretsManager
      ####################################
      {
        Sid    = "ReadSecrets"
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          var.database.master_password_arn,
          var.omim_api_key_arn,
        ]
      }
    ]
  })
}

##############################################
# Attach ECS Execution Policy (required)
##############################################

resource "aws_iam_role_policy_attachment" "ecs_task_policy_panelapp" {
  role       = aws_iam_role.ecs_task_panelapp.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
