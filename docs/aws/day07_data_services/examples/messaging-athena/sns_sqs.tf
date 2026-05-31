# SNS トピック（メッセージの発行先。GCPでいう Pub/Sub Topic）
resource "aws_sns_topic" "events" {
  name = "events-topic"
}

# SQS キュー（メッセージを溜めて処理。GCPでいう Pub/Sub Subscription）
resource "aws_sqs_queue" "events" {
  name                       = "events-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 604800 # 7日
}

# SNS → SQS のサブスクリプション
resource "aws_sns_topic_subscription" "events" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.events.arn
}

# SNS からの送信を SQS が許可するポリシー
resource "aws_sqs_queue_policy" "events" {
  queue_url = aws_sqs_queue.events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.events.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.events.arn }
      }
    }]
  })
}
