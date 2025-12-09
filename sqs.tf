##############################################
# SQS QUEUE — PANELAPP
##############################################

resource "aws_sqs_queue" "panelapp" {
  name = "${var.project_name}-${var.env_name}"

  visibility_timeout_seconds  = 360
  message_retention_seconds   = 345600
  max_message_size            = 262144
  delay_seconds               = 0
  receive_wait_time_seconds   = 0

  # No DLQ unless you create one and reference its ARN
  # redrive_policy = jsonencode({ 
  #   deadLetterTargetArn = aws_sqs_queue.deadletter.arn
  #   maxReceiveCount     = 3
  # })

  fifo_queue                  = false
  content_based_deduplication = false

  tags = {
    Name        = "${var.project_name}-${var.env_name}-queue"
    Application = "${var.project_name}-${var.env_name}"
  }
}
