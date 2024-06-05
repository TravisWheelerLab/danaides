resource "aws_sqs_queue" "data_queue" {
  name                       = "data-queue"
  delay_seconds              = 90
  max_message_size           = 2048
  visibility_timeout_seconds = var.efs_lambda_timeout * 6 # Recommended by aws docs 
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name = "dead-letter-queue"
}

resource "aws_lambda_event_source_mapping" "sqs_event_mapping" {
  event_source_arn = aws_sqs_queue.data_queue.arn
  function_name    = aws_lambda_function.lambda_efs.function_name
  batch_size       = 10
}
