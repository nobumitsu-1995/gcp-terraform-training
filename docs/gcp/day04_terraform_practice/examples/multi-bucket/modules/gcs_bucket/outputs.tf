output "bucket_name" {
  value       = google_storage_bucket.this.name
  description = "作成されたバケットの名前"
}

output "bucket_url" {
  value       = google_storage_bucket.this.url
  description = "gs://形式のURL"
}
