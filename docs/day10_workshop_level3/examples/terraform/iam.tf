# ============================================================
# サービスアカウント（サービスごとに分離 — 最小権限の原則）
# ============================================================

# API Gateway がバックエンド（Cloud Run）を呼び出す際に使用するSA
resource "google_service_account" "api_gateway" {
  account_id   = "api-gateway-sa"
  display_name = "API Gateway"
}

resource "google_service_account" "order_svc" {
  account_id   = "order-svc-sa"
  display_name = "Order Service"
}

resource "google_service_account" "processing_svc" {
  account_id   = "processing-svc-sa"
  display_name = "Processing Service"
}

resource "google_service_account" "notify_svc" {
  account_id   = "notify-svc-sa"
  display_name = "Notify Service"
}

resource "google_service_account" "pubsub_invoker" {
  account_id   = "pubsub-invoker-sa"
  display_name = "Pub/Sub Push Invoker"
}

# ============================================================
# IAMバインディング: 各SAに必要最小限のロールだけ付与
# ============================================================

# API Gateway SA: Cloud Run の呼び出し権限（Order Svcへのルーティングに必要）
resource "google_cloud_run_v2_service_iam_member" "apigw_invoke_order" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.order_svc.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.api_gateway.email}"
}

# Order Svc: Cloud SQL接続 + Secret Manager読み取り + Pub/Sub publish
resource "google_project_iam_member" "order_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.order_svc.email}"
}

resource "google_secret_manager_secret_iam_member" "order_secret" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.order_svc.email}"
}

resource "google_project_iam_member" "order_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.order_svc.email}"
}

# Processing Svc: GCS書き込み + BigQueryロード + Pub/Sub publish
resource "google_project_iam_member" "proc_gcs" {
  project = var.project_id
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.processing_svc.email}"
}

resource "google_project_iam_member" "proc_bq" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.processing_svc.email}"
}

resource "google_project_iam_member" "proc_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.processing_svc.email}"
}

# Pub/Sub Invoker: Processing Svc, Notify Svc の呼出し権限
resource "google_cloud_run_v2_service_iam_member" "invoke_processing" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.processing_svc.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_invoker.email}"
}

resource "google_cloud_run_v2_service_iam_member" "invoke_notify" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.notify_svc.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_invoker.email}"
}
