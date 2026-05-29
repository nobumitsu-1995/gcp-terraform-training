resource "google_bigquery_dataset" "pipeline" {
  dataset_id                  = "pipeline_data"
  location                    = var.region
  default_table_expiration_ms = 2592000000 # 30日で自動削除（研修用）
}

resource "google_bigquery_table" "orders" {
  dataset_id          = google_bigquery_dataset.pipeline.dataset_id
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
