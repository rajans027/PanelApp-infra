resource "aws_sqs_queue" "panelapp" {
  name                        = var.name.ws_product
  visibility_timeout_seconds  = 360
  message_retention_seconds   = 345600
  max_message_size            = 262144
  delay_seconds               = 0
  receive_wait_time_seconds   = 0
  policy                      = ""
  redrive_policy              = ""
  fifo_queue                  = false
  content_based_deduplication = false

  tags = {
    Name = "panelapp"
  }
}
