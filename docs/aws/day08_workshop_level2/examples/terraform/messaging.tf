# 注文イベントのトピック
resource "aws_sns_topic" "orders" {
  name = "orders-topic"
}

# 処理用キュー
resource "aws_sqs_queue" "orders" {
  name                       = "orders-process-queue"
  visibility_timeout_seconds = 60
}

# SNS → SQS のサブスクリプション
resource "aws_sns_topic_subscription" "orders" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.orders.arn
}

# SNS からの送信を SQS が許可するポリシー
resource "aws_sqs_queue_policy" "orders" {
  queue_url = aws_sqs_queue.orders.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.orders.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.orders.arn }
      }
    }]
  })
}

# SQS → process-order Lambda のトリガー
resource "aws_lambda_event_source_mapping" "orders" {
  event_source_arn = aws_sqs_queue.orders.arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 10
}
