# ============================================================
# トピック（多段キュー）
# ============================================================
resource "aws_sns_topic" "orders" {
  name = "level3-orders"
}

resource "aws_sns_topic" "processed" {
  name = "level3-processed"
}

# ============================================================
# キュー
# ============================================================
resource "aws_sqs_queue" "orders" {
  name                       = "level3-orders-queue"
  visibility_timeout_seconds = 60
}

resource "aws_sqs_queue" "notify" {
  name                       = "level3-notify-queue"
  visibility_timeout_seconds = 60
}

# ============================================================
# サブスクリプション（SNS → SQS）
# ============================================================
resource "aws_sns_topic_subscription" "orders_to_queue" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.orders.arn
}

resource "aws_sns_topic_subscription" "processed_to_notify" {
  topic_arn = aws_sns_topic.processed.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notify.arn
}

# ============================================================
# SQS が SNS からの送信を許可するポリシー
# ============================================================
resource "aws_sqs_queue_policy" "orders" {
  queue_url = aws_sqs_queue.orders.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.orders.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.orders.arn } }
    }]
  })
}

resource "aws_sqs_queue_policy" "notify" {
  queue_url = aws_sqs_queue.notify.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.notify.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.processed.arn } }
    }]
  })
}

# ============================================================
# SQS → Lambda のトリガー
# ============================================================
resource "aws_lambda_event_source_mapping" "orders" {
  event_source_arn = aws_sqs_queue.orders.arn
  function_name    = aws_lambda_function.processing.arn
  batch_size       = 10
}

resource "aws_lambda_event_source_mapping" "notify" {
  event_source_arn = aws_sqs_queue.notify.arn
  function_name    = aws_lambda_function.notify.arn
  batch_size       = 10
}
