# 第1段: Order Svc → Processing Svc への注文イベント配信
resource "google_pubsub_topic" "orders" {
  name = "orders"
}

# 第2段: Processing Svc → Notify Svc への処理完了イベント配信
resource "google_pubsub_topic" "processed" {
  name = "processed"
}

# --- Push Subscription: Pub/Sub → 各Cloud Runサービス ---

# orders → Processing Svc
resource "google_pubsub_subscription" "processing_svc" {
  name  = "processing-svc-sub"
  topic = google_pubsub_topic.orders.id

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.processing_svc.uri}/process"

    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }

  ack_deadline_seconds = 60
}

# processed → Notify Svc（第2段キューの購読）
resource "google_pubsub_subscription" "notify_svc" {
  name  = "notify-svc-sub"
  topic = google_pubsub_topic.processed.id

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.notify_svc.uri}/notify"

    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }

  ack_deadline_seconds = 30
}
