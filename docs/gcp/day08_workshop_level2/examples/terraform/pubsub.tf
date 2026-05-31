# トピック: Cloud Functions が publish する先
resource "google_pubsub_topic" "csv_uploaded" {
  name = "csv-uploaded"
}

# Push サブスクリプション: Pub/Sub が Cloud Run を HTTP で呼び出す
resource "google_pubsub_subscription" "etl_worker" {
  name  = "etl-worker-sub"
  topic = google_pubsub_topic.csv_uploaded.id

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.etl_worker.uri}/process"

    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }

  ack_deadline_seconds = 60 # ETL処理のタイムアウト（秒）
}
