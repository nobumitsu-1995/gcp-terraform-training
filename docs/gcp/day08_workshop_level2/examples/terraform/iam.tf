# ETLワーカー用（BigQuery書き込み + GCS読み取りのみ許可）
resource "google_service_account" "etl_worker" {
  account_id   = "etl-worker-sa"
  display_name = "ETL Worker Service Account"
}

# ETLワーカーにBigQueryへの書き込み権限を付与
resource "google_project_iam_member" "etl_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.etl_worker.email}"
}

# ETLワーカーにGCSオブジェクトの読み取り権限を付与
resource "google_project_iam_member" "etl_gcs_reader" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.etl_worker.email}"
}

# Pub/Sub → Cloud Run の呼び出し用サービスアカウント
resource "google_service_account" "pubsub_invoker" {
  account_id   = "pubsub-invoker-sa"
  display_name = "Pub/Sub Push Invoker"
}

# Pub/SubからCloud Runを呼び出す権限
resource "google_cloud_run_v2_service_iam_member" "pubsub_invoke" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.etl_worker.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_invoker.email}"
}
