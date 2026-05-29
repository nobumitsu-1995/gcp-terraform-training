output "raw_bucket" {
  value       = google_storage_bucket.raw_data.name
  description = "CSV を放り込むバケット"
}

output "etl_worker_url" {
  value       = google_cloud_run_v2_service.etl_worker.uri
  description = "ETL Worker の HTTPS エンドポイント（Pub/Sub から呼ばれる）"
}

output "bq_table" {
  value       = "${google_bigquery_dataset.pipeline.dataset_id}.${google_bigquery_table.orders.table_id}"
  description = "BigQuery テーブル（dataset.table 形式）"
}
