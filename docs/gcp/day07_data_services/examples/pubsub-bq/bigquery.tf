# BigQuery データセット（テーブルをまとめる論理的な入れ物。RDBでいうスキーマに近い）
resource "google_bigquery_dataset" "training" {
  dataset_id                  = "training_dataset"
  location                    = var.region
  default_table_expiration_ms = 2592000000 # テーブルの自動削除 = 30日（コスト管理）

  labels = { env = "training" }
}

# BigQuery テーブル
resource "google_bigquery_table" "orders" {
  dataset_id          = google_bigquery_dataset.training.dataset_id
  table_id            = "orders"
  deletion_protection = false # terraform destroy を許可

  # スキーマ定義（JSON形式で列名・型・必須/任意を定義）
  schema = jsonencode([
    { name = "order_id", type = "STRING", mode = "REQUIRED" },
    { name = "customer", type = "STRING", mode = "REQUIRED" },
    { name = "amount", type = "NUMERIC", mode = "REQUIRED" },
    { name = "status", type = "STRING", mode = "NULLABLE" },
    { name = "created_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])
}
