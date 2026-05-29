# 加工済みファイルの保存先
resource "google_storage_bucket" "processed" {
  name                        = "${var.project_id}-processed"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# 分析用データセット
resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = "analytics"
  location                    = var.region
  default_table_expiration_ms = 2592000000 # 30日で自動削除（研修用）
}

resource "google_bigquery_table" "orders" {
  dataset_id          = google_bigquery_dataset.analytics.dataset_id
  table_id            = "orders"
  deletion_protection = false

  schema = jsonencode([
    { name = "order_id", type = "STRING", mode = "REQUIRED" },
    { name = "customer", type = "STRING", mode = "REQUIRED" },
    { name = "product", type = "STRING", mode = "NULLABLE" },
    { name = "amount", type = "NUMERIC", mode = "REQUIRED" },
    { name = "status", type = "STRING", mode = "NULLABLE" },
    { name = "created_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])
}
