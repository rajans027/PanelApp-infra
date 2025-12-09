resource "aws_security_group" "fargate" {
  name        = "${var.name.ws_product}-cluster"
  description = "group for panelapp fargate"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name.ws_product}-cluster"
  }
}

resource "aws_security_group_rule" "fargate_ingress_8080_alb" {
  type                     = "ingress"
  from_port                = "8080"
  to_port                  = "8080"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.fargate.id
  description              = "Allow 8080 from Load Balancer"
}

resource "aws_security_group_rule" "fargate_smtp_egress" {
  type              = "egress"
  from_port         = 587
  to_port           = 587
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.fargate.id
  description       = "Allow SMTP to AWS SES Service"
}

resource "aws_security_group_rule" "fargate_https_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.fargate.id
  description       = "Allow HTTPS to External Services"
}

resource "aws_iam_role" "ecs_task_panelapp" {
  name                 = "${var.name.ws_product}-tasks"
  permissions_boundary = local.permissions_boundary
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "panelapp" {
  name = "${var.name.ws_product}-tasks"
  role = aws_iam_role.ecs_task_panelapp.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ReadWriteBucketObjects"
        Action = [
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:HeadBucket",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          "${var.buckets.media.arn}/*",
          "${var.buckets.statics.arn}/*",
          "${var.buckets.upload.arn}/*",
          "${var.buckets.artifacts.arn}/*"
        ]
      },
      {
        Sid = "ReadBucket"
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          var.buckets.statics.arn
        ]
      },
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
        Sid      = "ListQueues"
        Effect   = "Allow"
        Action   = "sqs:ListQueues"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          "${var.database.master_password_arn}/*",
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:*"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_panelapp" {
  role       = aws_iam_role.ecs_task_panelapp.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
