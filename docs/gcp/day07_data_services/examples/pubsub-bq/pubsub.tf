# Pub/Sub トピック（メッセージの送信先。AWSでいう SNSトピック）
resource "google_pubsub_topic" "orders" {
  name = "orders-topic"
}

# Pub/Sub サブスクリプション（メッセージの受信設定。AWSでいう SQSキュー）
resource "google_pubsub_subscription" "orders_sub" {
  name  = "orders-subscription"
  topic = google_pubsub_topic.orders.id

  ack_deadline_seconds = 20 # メッセージ処理の確認応答までのタイムアウト（秒）

  # 7日間ackされないメッセージは破棄
  message_retention_duration = "604800s"
}
